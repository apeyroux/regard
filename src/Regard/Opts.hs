{-# LANGUAGE OverloadedStrings #-}

module Regard.Opts (ServerOpts (..)
                   , ClientOpts (..)
                   , Cmd (..)
                   , serverOptsParser
                   , parseSubCmdServer
                   , commandParser
                   , parseSubCmdClient) where

import           Options.Applicative

data ServerOpts = ServerOpts {
  soConfigFile :: String
  } deriving (Eq, Show)

data ClientOpts = ClientOpts {
  coName :: String
  , coToken :: Maybe String
  , coAuthServer :: String
  } deriving (Eq, Show)

data Cmd = SubCmdServer ServerOpts | SubCmdClient ClientOpts deriving (Eq, Show)

parseSubCmdServer :: Parser Cmd
parseSubCmdServer = SubCmdServer <$> serverOptsParser

parseSubCmdClient :: Parser Cmd
parseSubCmdClient = SubCmdClient <$> clientOptsParser

serverOptsParser :: Parser ServerOpts
serverOptsParser =
  ServerOpts <$> strOption
  (short 'f'
    <> help "File config")

clientOptsParser :: Parser ClientOpts
clientOptsParser =
  ClientOpts
  <$> strOption
  (long "name"
    <> help "Name")
  <*> optional (strOption
  (long "token"
    <> help "Client token"))
  <*> strOption
  (long "auth-server"
    <> help "Server d'auth" <> value "127.0.0.1:3000")

commandParser :: Parser Cmd
commandParser = subparser (command "server" (info parseSubCmdServer (progDesc "Server sub command"))
                           <>
                           command "client" (info parseSubCmdClient (progDesc "Client sub command")))
