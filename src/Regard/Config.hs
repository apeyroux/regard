{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

module Regard.Config (SrvConfig (..)) where

import           Data.Yaml
import           GHC.Generics

data SrvConfig = SrvConfig {
  srvConfigWL :: [String]
  } deriving Generic

instance ToJSON SrvConfig
instance FromJSON SrvConfig where
  parseJSON (Object v) = SrvConfig
    <$> v .: "wl"
