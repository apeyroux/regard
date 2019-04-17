{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE LambdaCase #-}

module Main where

import           Control.Monad.IO.Class
import qualified Data.ByteString               as BS
import qualified Data.ByteString.Char8         as BSC
import qualified Data.ByteString.Lazy          as BLS
import           Data.Default
import           Data.List
import           Data.Map
import           Data.Time.Clock
import           Data.Yaml                      ( decodeEither'
                                                , ParseException
                                                )
import           Network.HTTP.Client           as HTTPC
import qualified Network.HTTP.Proxy            as Proxy
import qualified Network.HTTP.Simple           as HTTP
import           Network.HTTP.Types.Status
import           Network.URI
import           Network.Wai                    ( Response
                                                , responseLBS
                                                )
import           Network.Wai.Handler.Warp.Internal
import           Options.Applicative
import           Web.Scotty
import           System.Directory
import           System.FilePath.Posix


import           Regard.Opts
import           Regard.Config

checker
  :: String
  -> String
  -> Proxy.Request
  -> IO (Either Network.Wai.Response Proxy.Request)
checker srv clientId req =
  case Data.Map.lookup "host" $ fromList $ Proxy.requestHeaders req of
    Just u -> do
      -- revoir la construction de l'url (pas de ////xxxx)
      r <- HTTP.parseRequest (srv <> "/" <> clientId)
      let r' = HTTPC.urlEncodedBody [("url", u)] (r { HTTPC.method = "POST" })
      resp <- HTTP.httpLBS r'
      if statusCode (HTTP.getResponseStatus resp) /= 200
        then return
          (Left
            (responseLBS
              status401
              []
              "<center><h1>Tu dois demander l'accès à ce site avant d'y aller.</h1></center>"
            )
          )
        else return $ Right req

sOpts :: Options
sOpts = def { verbose = 0, settings = (settings def) { settingsPort = 3000 } }

loadCfg :: Maybe FilePath -> IO BS.ByteString
loadCfg (Just f) = BS.readFile f
loadCfg Nothing  = do
  -- check dir exist
  f <- (</> "config.yaml") <$> getXdgDirectory XdgConfig "regard"
  -- create dir if missing
  pure (takeDirectory f) >>= createDirectoryIfMissing True
  -- load file
  doesFileExist f
    >>= (\case
          k | k         -> BS.readFile f
            | otherwise -> cfg2file f >> loadCfg Nothing
        )

main :: IO ()
main = do
  opts <- execParser
    $ info (commandParser <**> helper) Options.Applicative.fullDesc
  case opts of
    SubCmdClient c -> do
      putStrLn $ coName c <> " use " <> coAuthServer c <> " ..."
      Proxy.runProxySettings Proxy.defaultProxySettings
        { Proxy.proxyPort            = 3128
        , Proxy.proxyRequestModifier = checker (coAuthServer c) (coName c)
        }
    SubCmdServer cfile -> do
      cfg <- loadCfg (soConfigFile cfile)
      case decodeEither' cfg :: Either ParseException SrvConfig of
        Left  ex     -> print ex
        Right srvCfg -> do
          putStrLn $ "Use this wl : " <> show (srvConfigWL srvCfg)
          scottyOpts sOpts $ post "/:client/" $ do
            idClient <- param "client"
            url      <- param "url"
            now      <- liftIO getCurrentTime
            if any (isInfixOf url) (srvConfigWL srvCfg)
              then do
                liftIO
                  $  putStrLn
                  $  show now
                  <> " OK c:"
                  <> idClient
                  <> " - "
                  <> url
                status status200
              else do
                liftIO
                  $  putStrLn
                  $  show now
                  <> " KO c:"
                  <> idClient
                  <> " - "
                  <> url
                status status401
