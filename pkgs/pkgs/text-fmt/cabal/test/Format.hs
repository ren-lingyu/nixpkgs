{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Control.Monad (forM_, replicateM)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as B
import Fixtures
import System.Exit (exitFailure)
import TextFmt.Format

require :: String -> Bool -> IO ()
require name valid = if valid then pure () else putStrLn ("FAIL " ++ name) >> exitFailure

-- Independent list-based oracle, separate from the production Builder scan.
reference :: [Word] -> Either FormatError [Word]
reference input
    | 0 `elem` input = Left NulByte
    | unstable input = Left UnstableNewline
    | otherwise = Right (finish (pairs input))
  where
    unstable [] = False
    unstable [13] = True
    unstable (13 : 13 : 10 : _) = True
    unstable (_ : rest) = unstable rest
    pairs (13 : 10 : rest) = 10 : pairs rest
    pairs (x : rest) = x : pairs rest
    pairs [] = []
    finish [] = []
    finish xs = if last xs == 10 then xs else xs ++ [10]

main :: IO ()
main = do
    forM_ goldenCases $ \(name, input, expected) -> do
        require name (formatText input == Right expected)
        require (name ++ " idempotence") (formatText expected == Right expected)
    forM_ invalidCases $ \(name, input, message) ->
        require name $ case formatText input of
            Left err -> B.pack message `BS.isInfixOf` renderFormatError err
            Right _ -> False
    let samples = concatMap (\n -> replicateM n [0, 10, 13, 32, 65, 255]) [0 .. 6]
    forM_ samples $ \bytes -> do
        let input = BS.pack (map fromIntegral bytes)
            expected = fmap (BS.pack . map fromIntegral) (reference bytes)
        require ("generated oracle " ++ show bytes) (formatText input == expected)
        case formatText input of
            Left _ -> pure ()
            Right output -> require "generated idempotence" (formatText output == Right output)
    forM_ [1 .. 255] $ \byte -> do
        let input = BS.pack [65, byte, 66]
        require "all non-NUL interior bytes" (formatText input == Right (BS.snoc input 10))
    putStrLn "format-tests: byte goldens, invalid inputs, exhaustive short inputs and idempotence passed"
