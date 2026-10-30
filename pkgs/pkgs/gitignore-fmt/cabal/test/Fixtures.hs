{-# LANGUAGE OverloadedStrings #-}

module Fixtures (goldenCases, invalidCases) where

import Data.ByteString (ByteString)

-- Byte-exact expectations retained from the Shell implementation's regressions.
goldenCases :: [(String, ByteString, ByteString)]
goldenCases =
    [ ("empty", "", "*\n*/\n")
    , ("only-blank-lines", "\n\n\n", "*\n*/\n")
    , ("complete-header", "*\n*/\n", "*\n*/\n")
    , ("star-only", "*\n", "*\n*/\n")
    , ("directory-only", "*/\n", "*\n*/\n")
    , ("reversed-header", "*/\n*\n", "*\n*/\n")
    , ("missing-header", "!foo\n", "*\n*/\n\n!/foo\n")
    , ("already-anchored", "!/foo\n", "*\n*/\n\n!/foo\n")
    , ("three-sections", "*/\n*\n!z\n!a\nz\na\n", "*\n*/\n\n!/a\n!/z\n\na\nz\n")
    , ("directory-groups", "!z/child\n!a/nested/file\n!root\n!a/\n!z/\n", "*\n*/\n\n!/root\n\n!/a/\n!/a/nested/file\n\n!/z/\n!/z/child\n")
    , ("glob-directory", "!src/\n!**/*.nix\n!root\n!**/\n", "*\n*/\n\n!/root\n\n!/**/\n!/**/*.nix\n\n!/src/\n")
    , ("attached-comment", "# z\n!z\n# a\n!a\n", "*\n*/\n\n# a\n!/a\n# z\n!/z\n")
    , ("multiple-comments", "# one\n# two\n!foo\n", "*\n*/\n\n# one\n# two\n!/foo\n")
    , ("detached-comment", "!z\n# barrier\n\n!a\n", "*\n*/\n\n!/z\n\n# barrier\n\n!/a\n")
    , ("eof-comment", "!foo\n# tail", "*\n*/\n\n!/foo\n\n# tail\n")
    , ("comments-only", "# one\n# two\n", "*\n*/\n\n# one\n# two\n")
    , ("header-comment", "# header\n*\n*/\n!a\n", "*\n*/\n\n# header\n\n!/a\n")
    , ("blank-lines", "\n*\n\n*/\n\n\n!a\n\n!b\n\n", "*\n*/\n\n!/a\n!/b\n")
    , ("missing-final-lf", "!foo", "*\n*/\n\n!/foo\n")
    , ("crlf", "*\r\n*/\r\n!foo\r\n# end\r\n", "*\n*/\n\n!/foo\n\n# end\n")
    , ("escaped-markers", "\\!foo\n\\#foo\n", "*\n*/\n\n\\!foo\n\\#foo\n")
    , ("wildcards", "!*.nix\n!file[ab]?\n!src/**/\n*.tmp\n", "*\n*/\n\n!/*.nix\n!/file[ab]?\n\n!/src/**/\n\n*.tmp\n")
    , ("spaces", "!file\\ name\n!trail\\ \n  literal  \n", "*\n*/\n\n!/file\\ name\n!/trail\\ \n\n  literal  \n")
    , ("tabs", "!file\tname\n", "*\n*/\n\n!/file\tname\n")
    , ("duplicate-rules", "# first\n!a\n# second\n!a\nfoo\nfoo\n", "*\n*/\n\n# first\n!/a\n# second\n!/a\n\nfoo\nfoo\n")
    , ("non-ascii", "!\xc3\&\xa9\&\n!a\n", "*\n*/\n\n!/a\n!/\xc3\&\xa9\&\n")
    ]

invalidCases :: [(String, ByteString, String)]
invalidCases =
    [ ("duplicate-star", "*\n*\n", "duplicate * header")
    , ("duplicate-directory", "*/\n*/\n", "duplicate */ header")
    , ("negation-after-ignore", "foo\n!bar\n", "invalid section order")
    , ("header-after-negation", "!foo\n*\n", "invalid section order")
    , ("header-after-ignore", "foo\n*/\n", "invalid section order")
    , ("empty-negation", "!\n", "empty negation")
    , ("empty-negation-path", "!/\n", "empty negation path")
    , ("record-separator", "!a\x1f\&b\n", "unsupported control character")
    , ("comment-separator", "# a\x1f\&b\n", "unsupported control character")
    , ("nul", "!a\x00\&b\n", "unsupported NUL byte")
    ]
