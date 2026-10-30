{-# LANGUAGE OverloadedStrings #-}

module Fixtures (goldenCases, invalidCases) where

import Data.ByteString (ByteString)
import qualified Data.ByteString as BS

goldenCases :: [(String, ByteString, ByteString)]
goldenCases =
    [ ("empty", "", "")
    , ("lf", "\n", "\n")
    , ("crlf", "\r\n", "\n")
    , ("mixed", "a\r\nb\nc", "a\nb\nc\n")
    , ("missing-final-lf", "abc", "abc\n")
    , ("multiple-final-lf", "a\n\n\n", "a\n\n\n")
    , ("whitespace", "  a \t\r\n \t\n\tb  ", "  a \t\n \t\n\tb  \n")
    , ("chinese", BS.pack [228, 184, 173, 230, 150, 135], BS.pack [228, 184, 173, 230, 150, 135, 10])
    , ("bom", BS.pack [239, 187, 191] <> "a\r\n", BS.pack [239, 187, 191] <> "a\n")
    , ("raw-bytes", BS.pack [255, 128, 9], BS.pack [255, 128, 9, 10])
    , ("interior-cr", "111\r111", "111\r111\n")
    , ("interior-cr-and-crlf", "111\r111\r\n", "111\r111\n")
    , ("interior-repeated-cr", "a\r\rb", "a\r\rb\n")
    ]

invalidCases :: [(String, ByteString, String)]
invalidCases =
    [ ("nul", "a\0b", "NUL")
    , ("terminal-cr", "111\r111\r", "idempotent")
    , ("cr-only", "\r", "idempotent")
    , ("repeated-cr-before-lf", "a\r\r\n", "idempotent")
    , ("interior-unstable", "a\r\r\nb", "idempotent")
    , ("repeated-terminal-cr", "a\r\r", "idempotent")
    ]
