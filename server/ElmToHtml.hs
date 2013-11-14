{-# LANGUAGE OverloadedStrings #-}
module ElmToHtml (elmToHtml, elmToJS) where

import Data.Maybe (fromMaybe)
import Text.Blaze (preEscapedToMarkup)
import Text.Blaze.Html5 ((!))
import qualified Text.Blaze.Html5 as H
import qualified Text.Blaze.Html5.Attributes as A

import qualified Language.Elm as Elm
import Utils

-- | Using a page title and the full source of an Elm program, compile down to
--   a valid HTML document.
elmToHtml :: Elm.Interfaces -> String -> String -> H.Html
elmToHtml interfaces name src =
  H.docTypeHtml $ do
      H.head $ do
        H.meta ! A.charset "UTF-8"
        H.title . H.toHtml $ name
        H.style ! A.type_ "text/css" $ preEscapedToMarkup
         ("a:link {text-decoration: none; color: rgb(15,102,230);}\n\
          \a:visited {text-decoration: none}\n\
          \a:active {text-decoration: none}\n\
          \a:hover {text-decoration: underline; color: rgb(234,21,122);}" :: String)
      H.body $ do
        let js = H.script ! A.type_ "text/javascript"
            elmname = "Elm." ++ fromMaybe "Main" (Elm.moduleName src)
            runFullscreen = "var runningElmModule = Elm.fullscreen(" ++ elmname ++ ")"
        js ! A.src (H.toValue ("/elm-runtime.js" :: String)) $ ""
        case Elm.compile interfaces src of
          Right jsSrc -> do
              js $ preEscapedToMarkup jsSrc
              js $ preEscapedToMarkup runFullscreen
          Left err ->
              H.span ! A.style "font-family: monospace;" $
              mapM_ (\line -> preEscapedToMarkup (addSpaces line) >> H.br) (lines err)
        googleAnalytics

addSpaces :: String -> String
addSpaces str =
  case str of
    ' ' : ' ' : rest -> " &nbsp;" ++ addSpaces rest
    c : rest -> c : addSpaces rest
    [] -> []

elmToJS :: Elm.Interfaces -> String -> String
elmToJS interfaces src = case Elm.compile interfaces src of
                Right js -> "{ \"success\" : " ++ show js ++ " }"
                Left err -> "{ \"error\" : " ++ show err ++ " }"
