--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import Data.Monoid (mappend)
import Prelude hiding ( div, span )
import Control.Monad (forM_)
import Hakyll
import Text.Blaze.Html5 as H hiding (main)
import Text.Blaze.Html5.Attributes as A
import Text.Blaze.Html.Renderer.Pretty      ( renderHtml )
--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do
    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*.css" $ do
        route   idRoute
        compile compressCssCompiler

    match "css/*.hs" $ do
      route   $ setExtension "css"
      compile $ getResourceString >>= withItemBody (unixFilter "runghc" [])

    -- I can't figure out how to get this done properly 
    -- match "layouts/*.hs" $ do
    --   route   idRoute
    --   compile $ getResourceString >>= withItemBody (unixFilter "runghc" [])

    match (fromList ["about.rst", "contact.markdown"]) $ do
        route   $ setExtension "html"
        compile $ pandocCompiler
            >>= applyTemplate defaultTemplate defaultContext
            >>= relativizeUrls

    match "test.md" $ do
        route   $ setExtension "html"
        compile $ do
            pandocCompiler >>= applyTemplate defaultTemplate postCtx

    match "posts/*" $ do
        route $ setExtension "html"
        compile $ pandocCompiler
            >>= applyTemplate postTemplate postCtx
            >>= applyTemplate defaultTemplate defaultContext
            >>= relativizeUrls

    create ["archive.html"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let archiveCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Archives"            `mappend`
                    defaultContext

            makeItem ""
                >>= applyTemplate postListTemplate archiveCtx
                >>= applyTemplate defaultTemplate defaultContext
                >>= relativizeUrls


    match "index.html" $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let indexCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Home"                `mappend`
                    defaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= applyTemplate defaultTemplate defaultContext
                >>= relativizeUrls

    match "templates/*" $ compile templateCompiler


--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext

defaultTemplate :: Template
defaultTemplate = readTemplate . renderHtml $ defaultTemplateRaw

defaultTemplateRaw :: Html
defaultTemplateRaw = html $ do
    H.head $ do
        meta ! httpEquiv "Content-Type" ! content "text/html; charset=UTF-8"
        H.title "My Hakyll Blog - $title$"
        link ! rel "stylesheet" ! type_ "text/css" ! href "/css/default.css"
        link ! rel "stylesheet" ! type_ "text/css" ! href "/css/style.css"
    body $ do
        H.div ! A.id "header" $ do
            H.div ! A.id "logo" $ a ! href "/" $ "My Hakyll Blog"
            H.div ! A.id "navigation" $ do
                a ! href "/" $ "Home"
                a ! href "/about.html" $ "About"
                a ! href "/contact.html" $ "Contact"
                a ! href "/archive.html" $ "Archive"
        H.div ! A.id "content" $ do
            h1 "$title$"
            "$body$"
        H.div ! A.id "footer" $ do
            "Site proudly generated by"
            a ! href "http://jaspervdj.be/hakyll" $ "Hakyll"

postListTemplate :: Template
postListTemplate = readTemplate . renderHtml $ postListTemplateRaw

postListTemplateRaw :: Html
postListTemplateRaw =
  ul $ do
    "$for(posts)$"
    li $ do
        a ! href "$url$" $ "$title$"
        "- $date$"
    "$endfor$"

postTemplate :: Template
postTemplate = readTemplate . renderHtml $ postTemplateRaw

postTemplateRaw :: Html
postTemplateRaw = H.div ! class_ "info" $ do
  "Posted on $date$\n"
  "$body$"
