{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Control.Exception (AsyncException (UserInterrupt), IOException, bracket, throwIO, try)
import Control.Monad (forM_, unless, when)
import Data.Bits ((.&.))
import qualified Data.ByteString as BS
import Data.List (isInfixOf)
import Fixtures
import Gitignore.File
import System.Directory (doesFileExist, getDirectoryContents, getTemporaryDirectory, removePathForcibly)
import System.Environment (getExecutablePath, lookupEnv, setEnv)
import System.Exit (ExitCode (..), exitFailure)
import System.FilePath (searchPathSeparator, takeDirectory, (</>))
import qualified System.Posix.Files as P
import System.Posix.Temp (mkdtemp)
import System.Posix.Types (FileMode)
import System.Process (CreateProcess (cwd), proc, readCreateProcessWithExitCode)

require :: String -> Bool -> IO ()
require name valid = unless valid (putStrLn ("FAIL " ++ name) >> exitFailure)

invoke :: FilePath -> [String] -> Int -> IO String
invoke root args expected = do
    (status, _, err) <- readCreateProcessWithExitCode (proc "gitignore-fmt" args){cwd = Just root} ""
    require ("exit status " ++ show args ++ ": " ++ show status ++ " " ++ err) $
        status == if expected == 0 then ExitSuccess else ExitFailure expected
    pure err

snapshot :: FilePath -> IO (BS.ByteString, FileMode, Integer, Rational)
snapshot path = do
    bytes <- BS.readFile path
    status <- P.getFileStatus path
    pure (bytes, P.fileMode status, fromIntegral (P.fileID status), toRational (P.modificationTimeHiRes status))

unchanged :: String -> FilePath -> (BS.ByteString, FileMode, Integer, Rational) -> IO ()
unchanged name path before = snapshot path >>= require name . (== before)

withDirectory :: String -> (FilePath -> IO a) -> IO a
withDirectory name action = do
    parent <- getTemporaryDirectory
    bracket (mkdtemp (parent </> ("gitignore-fmt-" ++ name ++ "-"))) removePathForcibly action

golden :: FilePath -> String -> BS.ByteString -> BS.ByteString -> IO ()
golden root name input expected = do
    let path = root </> "input"
    BS.writeFile path input
    P.setFileMode path 0o640
    before <- snapshot path
    _ <- invoke root ["--check", "input"] (if input == expected then 0 else 1)
    unchanged (name ++ " check write") path before
    _ <- invoke root ["input"] 0
    actual <- BS.readFile path
    require (name ++ " bytes") (actual == expected)
    status <- P.getFileStatus path
    require (name ++ " mode") (P.fileMode status .&. 0o7777 == 0o640)
    formatted <- snapshot path
    _ <- invoke root ["input"] 0
    unchanged (name ++ " idempotence") path formatted
    _ <- invoke root ["--check", "input"] 0
    unchanged (name ++ " check no-op") path formatted

main :: IO ()
main = do
    -- Cabal v2 supplies build-tool-depends on PATH; Setup test needs this fallback.
    testExecutable <- getExecutablePath
    let local = takeDirectory (takeDirectory testExecutable) </> "gitignore-fmt"
    built <- doesFileExist (local </> "gitignore-fmt")
    when built $ do
        existing <- lookupEnv "PATH"
        setEnv "PATH" (local ++ maybe "" (searchPathSeparator :) existing)
    forM_ goldenCases $ \(name, input, expected) ->
        withDirectory name $ \root -> golden root name input expected
    forM_ invalidCases $ \(name, input, message) -> withDirectory name $ \root -> do
        let path = root </> "input"
        BS.writeFile path input
        before <- snapshot path
        forM_ [["input"], ["--check", "input"]] $ \args -> do
            err <- invoke root args 2
            require (name ++ " diagnostic") (message `isInfixOf` err)
            unchanged (name ++ " invalid write") path before
    withDirectory "arguments" $ \root -> do
        forM_ [[], ["--check"], ["--"], ["--unknown"]] $ \args -> do
            err <- invoke root args 2
            require "usage diagnostic" ("Usage:" `isInfixOf` err)
        forM_ ["space name", "-name", "--check", "中文"] $ \name -> do
            let path = root </> name
            BS.writeFile path "!a\n"
            _ <- invoke root ["--check", "--", name] 1
            _ <- invoke root ["--", name] 0
            _ <- invoke root ["--check", "--", name] 0
            bytes <- BS.readFile path
            require "filename bytes" (bytes == "*\n*/\n\n!/a\n")
    withDirectory "files" $ \root -> do
        let target = root </> "target"
        BS.writeFile target "!a\n"
        P.createSymbolicLink "target" (root </> "link")
        before <- snapshot target
        forM_ [[], ["--check"]] $ \mode -> do
            err <- invoke root (mode ++ ["link"]) 2
            require "symlink diagnostic" ("symbolic links" `isInfixOf` err)
            unchanged "symlink target write" target before
            status <- P.getSymbolicLinkStatus (root </> "link")
            require "symlink retained" (P.isSymbolicLink status)
            _ <- invoke root (mode ++ ["absent"]) 2
            _ <- invoke root (mode ++ ["."]) 2
            pure ()
    withDirectory "multiple" $ \root -> do
        let a = root </> "a"; b = root </> "b"; bad = root </> "bad"
        BS.writeFile a "!z\n"
        BS.writeFile b "!a\n"
        BS.writeFile bad "!\n"
        before <- mapM snapshot [a, b, bad]
        _ <- invoke root ["--check", "a", "bad", "b"] 2
        after <- mapM snapshot [a, b, bad]
        require "multiple check writes" (before == after)
        _ <- invoke root ["a", "bad", "b"] 2
        require "first file" . (== "*\n*/\n\n!/z\n") =<< BS.readFile a
        require "later file" . (== "*\n*/\n\n!/a\n") =<< BS.readFile b
        require "invalid file" . (== "!\n") =<< BS.readFile bad
        _ <- invoke root ["a", "b"] 0
        BS.writeFile a "!z\n"
        _ <- invoke root ["--check", "a", "b"] 1
        _ <- invoke root ["--check", "bad", "a"] 2
        pure ()
    let failure label = ioError (userError ("injected " ++ label))
        operations =
            [ ("inspect", fileOps{inspect = \_ -> failure "inspect"}, True)
            , ("read", fileOps{readInput = \_ -> failure "read"}, True)
            , ("create", fileOps{createTemp = \_ -> failure "create"}, False)
            , ("write", fileOps{writeTemp = \h _ -> BS.hPut h "partial" >> failure "write"}, False)
            , ("flush", fileOps{flushTemp = \_ -> failure "flush"}, False)
            , ("close", fileOps{closeTemp = \_ -> failure "close"}, False)
            , ("mode", fileOps{setMode = \_ _ -> failure "mode"}, False)
            , ("rename", fileOps{replace = \_ _ -> failure "rename"}, False)
            ]
    forM_ operations $ \(name, ops, checkFails) -> withDirectory name $ \root -> do
        let path = root </> "input"
        BS.writeFile path "!z\n!a\n"
        P.setFileMode path 0o640
        before <- snapshot path
        checked <- try (formatFile ops True path) :: IO (Either IOException (Either FileError Outcome))
        require (name ++ " check path") $ case checked of
            Left _ -> checkFails
            Right (Right NeedsFormatting) -> not checkFails
            _ -> False
        unchanged (name ++ " check changed original") path before
        attempted <- try (formatFile ops False path) :: IO (Either IOException (Either FileError Outcome))
        require (name ++ " failure missing") $ case attempted of
            Left err -> ("injected " ++ name) `isInfixOf` show err
            Right _ -> False
        unchanged (name ++ " damaged original") path before
        entries <- getDirectoryContents root
        require (name ++ " temporary leak") (all (`elem` [".", "..", "input"]) entries)
        result <- formatFile fileOps False path
        require (name ++ " recovery") (result == Right Changed)
    withDirectory "interrupted-write" $ \root -> do
        let path = root </> "input"
            interrupted = fileOps{writeTemp = \h _ -> BS.hPut h "partial" >> throwIO UserInterrupt}
        BS.writeFile path "!a\n"
        before <- snapshot path
        result <- try (formatFile interrupted False path) :: IO (Either AsyncException (Either FileError Outcome))
        require "interruption propagated" $ case result of Left UserInterrupt -> True; _ -> False
        unchanged "interruption damaged original" path before
        entries <- getDirectoryContents root
        require "interruption leaked temporary" (all (`elem` [".", "..", "input"]) entries)
    putStrLn "cli-tests: golden, invalid, CLI, filesystem, eight IO failures and interruption passed"
