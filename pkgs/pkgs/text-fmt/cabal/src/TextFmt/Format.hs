{-# LANGUAGE OverloadedStrings #-}

module TextFmt.Format (FormatError (..), formatText, renderFormatError) where

import Data.ByteString (ByteString)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Builder as Builder
import qualified Data.ByteString.Lazy as Lazy

data FormatError = NulByte | UnstableNewline deriving (Eq, Show)

renderFormatError :: FormatError -> ByteString
renderFormatError NulByte = "unsupported NUL byte"
renderFormatError UnstableNewline = "newline normalization would not be idempotent"

formatText :: ByteString -> Either FormatError ByteString
formatText input
    | BS.elem 0 input = Left NulByte
    | "\r\n" `BS.isInfixOf` rendered = Left UnstableNewline
    | otherwise = Right rendered
  where
    normalized = Lazy.toStrict (Builder.toLazyByteString (convert input))
    rendered
        | BS.null normalized || BS.last normalized == 10 = normalized
        | otherwise = BS.snoc normalized 10

-- Consume original CRLF pairs together; every other byte is copied verbatim.
convert :: ByteString -> Builder.Builder
convert bytes = case BS.elemIndex 13 bytes of
    Nothing -> Builder.byteString bytes
    Just offset ->
        let (prefix, suffix) = BS.splitAt offset bytes
            rest = BS.tail suffix
         in Builder.byteString prefix
                <> case BS.uncons rest of
                    Just (10, remaining) -> Builder.word8 10 <> convert remaining
                    _ -> Builder.word8 13 <> convert rest
