module Gitignore.Cli (main, run) where

import Control.Concurrent (myThreadId, throwTo)
import Control.Exception (AsyncException (UserInterrupt), IOException, bracket, catch, throwIO)
import qualified Data.ByteString.Char8 as B
import Gitignore.File
import Gitignore.Format (renderFormatError)
import System.Environment (getArgs)
import System.Exit (ExitCode (..), exitWith)
import System.IO (hPutStrLn, stderr)
import System.Posix.Signals (Handler (Catch), installHandler, keyboardSignal, lostConnection, softwareTermination)

parseArgs :: Bool -> [String] -> Maybe (Bool, [FilePath])
parseArgs _ [] = Nothing
parseArgs _ ("--check" : rest) = parseArgs True rest
parseArgs check ("--" : rest) = if null rest then Nothing else Just (check, rest)
parseArgs _ (('-' : _) : _) = Nothing
parseArgs check files = Just (check, files)

run :: [String] -> IO Int
run args = case parseArgs False args of
    Nothing -> hPutStrLn stderr "Usage: gitignore-fmt [--check] [--] FILE [FILE ...]" >> pure 2
    Just (check, files) -> maximum <$> mapM (process check) files
  where
    process check path =
        ( do
            result <- formatFile fileOps check path
            case result of
                Left NotRegular -> diagnostic path "not a regular file" >> pure 2
                Left SymbolicLink -> diagnostic path "symbolic links are not supported" >> pure 2
                Left (InvalidFormat err) -> do
                    B.hPutStr stderr (B.pack "gitignore-fmt: " <> renderFormatError err <> B.pack ": ")
                    hPutStrLn stderr path
                    pure 2
                Right Unchanged -> pure 0
                Right NeedsFormatting -> hPutStrLn stderr ("Not formatted: " ++ path) >> pure 1
                Right Changed -> putStrLn ("Formatted: " ++ path) >> pure 0
        )
            `catch` \err -> diagnostic path (show (err :: IOException)) >> pure 2
    diagnostic path message = hPutStrLn stderr ("gitignore-fmt: " ++ message ++ ": " ++ path)

main :: IO ()
main = do
    thread <- myThreadId
    let handler = Catch (throwTo thread UserInterrupt)
        signals = [keyboardSignal, lostConnection, softwareTermination]
        withHandlers action =
            bracket
                (mapM (\signal -> installHandler signal handler Nothing) signals)
                (\previous -> sequence_ (zipWith (\signal old -> installHandler signal old Nothing >> pure ()) signals previous))
                (const action)
    status <-
        withHandlers (getArgs >>= run) `catch` \interrupt -> case interrupt of
            UserInterrupt -> pure 2
            _ -> throwIO interrupt
    exitWith (if status == 0 then ExitSuccess else ExitFailure status)
