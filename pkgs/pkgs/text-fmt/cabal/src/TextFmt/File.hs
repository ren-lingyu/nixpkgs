module TextFmt.File (FileOps (..), fileOps, FileError (..), Outcome (..), formatFile) where

import Control.Exception (finally, mask, onException)
import Control.Monad (unless)
import qualified Data.ByteString as BS
import System.Directory (removeFile, renameFile)
import System.FilePath (takeDirectory, takeFileName)
import System.IO (Handle, hClose, hFlush, hIsClosed, openBinaryTempFile)
import System.IO.Error (catchIOError, isDoesNotExistError)
import qualified System.Posix.Files as P
import System.Posix.Types (FileMode)
import TextFmt.Format

-- Small IO boundary for the real filesystem and operation-failure tests.
data FileOps = FileOps
    { inspect :: FilePath -> IO P.FileStatus
    , readInput :: FilePath -> IO BS.ByteString
    , createTemp :: FilePath -> IO (FilePath, Handle)
    , writeTemp :: Handle -> BS.ByteString -> IO ()
    , flushTemp :: Handle -> IO ()
    , closeTemp :: Handle -> IO ()
    , setMode :: FilePath -> FileMode -> IO ()
    , replace :: FilePath -> FilePath -> IO ()
    }

fileOps :: FileOps
fileOps =
    FileOps
        P.getSymbolicLinkStatus
        BS.readFile
        (\path -> openBinaryTempFile (takeDirectory path) (takeFileName path ++ ".text-fmt."))
        BS.hPut
        hFlush
        hClose
        P.setFileMode
        renameFile

data FileError = NotRegular | SymbolicLink | InvalidFormat FormatError deriving (Eq, Show)
data Outcome = Unchanged | Changed | NeedsFormatting deriving (Eq, Show)

formatFile :: FileOps -> Bool -> FilePath -> IO (Either FileError Outcome)
formatFile ops check path = do
    status <-
        (Just <$> inspect ops path) `catchIOError` \err ->
            if isDoesNotExistError err then pure Nothing else ioError err
    case status of
        Nothing -> pure (Left NotRegular)
        Just info
            | P.isSymbolicLink info -> pure (Left SymbolicLink)
            | not (P.isRegularFile info) -> pure (Left NotRegular)
            | otherwise -> do
                original <- readInput ops path
                case formatText original of
                    Left err -> pure (Left (InvalidFormat err))
                    Right rendered
                        | original == rendered -> pure (Right Unchanged)
                        | check -> pure (Right NeedsFormatting)
                        | otherwise -> do
                            writeAtomically ops path (P.fileMode info) rendered
                            pure (Right Changed)

writeAtomically :: FileOps -> FilePath -> FileMode -> BS.ByteString -> IO ()
writeAtomically ops path mode bytes = mask $ \restore -> do
    (temporary, handle) <- createTemp ops path
    let cleanup =
            (hIsClosed handle >>= \closed -> unless closed (hClose handle))
                `finally` removeFile temporary
    restore
        ( do
            writeTemp ops handle bytes
            flushTemp ops handle
            closeTemp ops handle
            setMode ops temporary mode
            replace ops temporary path
        )
        `onException` cleanup
