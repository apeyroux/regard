{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

module Regard.Config
  ( SrvConfig(..)
  , cfg2file
  )
where

import qualified Data.ByteString               as BS
import           Data.Yaml
import           GHC.Generics
import           System.Directory
import           System.FilePath.Posix
import           System.IO                      ( FilePath )

data SrvConfig = SrvConfig {
  srvConfigWL :: [String]
  } deriving Generic

instance ToJSON SrvConfig where
  toJSON (SrvConfig wl) =
    object ["wl" .= wl]


instance FromJSON SrvConfig where
  parseJSON (Object v) = SrvConfig
    <$> v .: "wl"

cfg2file :: FilePath -> IO ()
cfg2file dest = do
  createDirectoryIfMissing True (takeDirectory dest)
  BS.writeFile
    dest
    (encode (SrvConfig ["fr.wikipedia.org:443", "fr.wikipedia.org"]))
