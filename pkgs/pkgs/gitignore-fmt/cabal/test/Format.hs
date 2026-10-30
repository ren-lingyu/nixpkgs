{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Control.Monad (forM_)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as B
import Data.List (permutations)
import Fixtures
import Gitignore.Format
import System.Exit (exitFailure)

require :: String -> Bool -> IO ()
require name valid = if valid then pure () else putStrLn ("FAIL " ++ name) >> exitFailure

main :: IO ()
main = do
    forM_ goldenCases $ \(name, input, expected) -> do
        require name (formatGitignore input == Right expected)
        require (name ++ " idempotence") (formatGitignore expected == Right expected)
    forM_ invalidCases $ \(name, input, message) ->
        require name $ case formatGitignore input of
            Left err -> B.pack message `BS.isInfixOf` renderFormatError err
            Right _ -> False
    forM_ (permutations ["!z/", "!root", "!a/"]) $ \ordering ->
        require "input permutations" $
            formatGitignore (B.unlines ordering) == Right "*\n*/\n\n!/root\n\n!/a/\n\n!/z/\n"
    -- The byte parser must preserve undecodable bytes and significant whitespace.
    let raw = "!file" <> BS.pack [255] <> " \\ \n"
    require "raw bytes" (formatGitignore raw == Right ("*\n*/\n\n!/file" <> BS.pack [255] <> " \\ \n"))
    -- Detached comments partition sorting, while identical rules retain comments.
    require "multiple barriers" $
        formatGitignore "!z\n# one\n\n!b\n!a\n# two\n\n!d\n!c\n"
            == Right "*\n*/\n\n!/z\n\n# one\n\n!/a\n!/b\n\n# two\n\n!/c\n!/d\n"
    putStrLn "format-tests: golden, invalid, permutation and byte invariants passed"
