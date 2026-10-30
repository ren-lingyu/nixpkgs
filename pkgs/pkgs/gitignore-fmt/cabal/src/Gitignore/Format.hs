{-# LANGUAGE OverloadedStrings #-}

module Gitignore.Format (FormatError (..), formatGitignore, renderFormatError) where

import Control.Monad (foldM)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as B
import Data.List (sortOn)

data FormatError
    = DuplicateStar
    | DuplicateDirectory
    | EmptyNegation
    | EmptyNegationPath
    | InvalidSectionOrder BS.ByteString
    | UnsupportedNul
    | UnsupportedControl
    deriving (Eq, Show)

renderFormatError :: FormatError -> BS.ByteString
renderFormatError problem = case problem of
    DuplicateStar -> "duplicate * header"
    DuplicateDirectory -> "duplicate */ header"
    EmptyNegation -> "empty negation"
    EmptyNegationPath -> "empty negation path"
    InvalidSectionOrder line -> "invalid section order: " <> line
    UnsupportedNul -> "unsupported NUL byte"
    UnsupportedControl -> "unsupported control character"

data Phase = Header | Allow | Ignore deriving (Eq, Ord)

data Rule = Rule Phase BS.ByteString BS.ByteString [BS.ByteString]

-- A detached comment starts a new independently sorted segment.
data Segment = Segment [BS.ByteString] [Rule]

data Parser = Parser
    { seenStar :: Bool
    , seenDirectory :: Bool
    , lastPhase :: Phase
    , pendingComments :: [BS.ByteString]
    , detachedComments :: [BS.ByteString]
    , currentRules :: [Rule]
    , previousSegments :: [Segment]
    }

initial :: Parser
initial = Parser False False Header [] [] [] []

flushComments :: Parser -> Parser
flushComments state
    | null (pendingComments state) = state
    | otherwise =
        state
            { pendingComments = []
            , detachedComments = reverse (pendingComments state)
            , currentRules = []
            , previousSegments = Segment (detachedComments state) (reverse (currentRules state)) : previousSegments state
            }

parseLine :: Parser -> BS.ByteString -> Either FormatError Parser
parseLine state raw
    | BS.elem 31 line = Left UnsupportedControl
    | BS.null line = Right (flushComments state)
    | B.head line == '#' = Right state{pendingComments = line : pendingComments state}
    | otherwise = do
        (phase, group, normalized, updated) <- classify
        if phase < lastPhase state
            then Left (InvalidSectionOrder line)
            else
                if phase == Header
                    then Right (flushComments updated{lastPhase = Header})
                    else
                        Right
                            updated
                                { lastPhase = phase
                                , pendingComments = []
                                , currentRules = Rule phase group normalized (reverse (pendingComments state)) : currentRules state
                                }
  where
    line = if not (BS.null raw) && B.last raw == '\r' then BS.init raw else raw
    classify
        | line == "*" =
            if seenStar state
                then Left DuplicateStar
                else Right (Header, "", line, state{seenStar = True})
        | line == "*/" =
            if seenDirectory state
                then Left DuplicateDirectory
                else Right (Header, "", line, state{seenDirectory = True})
        | line == "!" = Left EmptyNegation
        | "!" `BS.isPrefixOf` line =
            let normalized = if "!/" `BS.isPrefixOf` line then line else "!/" <> BS.tail line
                path = BS.drop 2 normalized
                group = if B.elem '/' path then B.takeWhile (/= '/') path else ""
             in if BS.null path
                    then Left EmptyNegationPath
                    else Right (Allow, group, normalized, state)
        | otherwise = Right (Ignore, "", line, state)

formatGitignore :: BS.ByteString -> Either FormatError BS.ByteString
formatGitignore input
    | BS.elem 0 input = Left UnsupportedNul
    | otherwise = do
        parsed <- foldM parseLine initial (B.lines input)
        let state = flushComments parsed
            segments = reverse (Segment (detachedComments state) (reverse (currentRules state)) : previousSegments state)
        pure (BS.concat ("*\n*/\n" : concatMap renderSegment segments))

renderSegment :: Segment -> [BS.ByteString]
renderSegment (Segment comments rules) =
    (if null comments then [] else ["\n", B.unlines comments])
        ++ renderRules Nothing (sortOn key rules)
  where
    key (Rule phase group line _) = (phase, group, line)
    renderRules _ [] = []
    renderRules previous (Rule phase group line attached : rest) =
        let separator = case previous of
                Nothing -> "\n"
                Just (oldPhase, oldGroup)
                    | oldPhase /= phase || (phase == Allow && oldGroup /= group) -> "\n"
                    | otherwise -> ""
         in [separator, B.unlines attached, line, "\n"]
                ++ renderRules (Just (phase, group)) rest
