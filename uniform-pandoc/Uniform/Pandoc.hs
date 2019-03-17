-----------------------------------------------------------------------------
--
-- Module      :  Uniform.Pandoc
-----------------------------------------------------------------------------
-- {-# LANGUAGE BangPatterns                   #-}
{-# LANGUAGE ConstraintKinds             #-}
-- {-# LANGUAGE DeriveDataTypeable    #-}
{-# LANGUAGE DoAndIfThenElse             #-}
{-# LANGUAGE FlexibleContexts               #-}
{-# LANGUAGE FlexibleInstances              #-}
{-# LANGUAGE MultiParamTypeClasses          #-}
{-# LANGUAGE OverloadedStrings              #-}
{-# LANGUAGE ScopedTypeVariables            #-}
{-# LANGUAGE TypeFamilies               #-}
-- {-# LANGUAGE TypeSynonymInstances        #-}
{-# LANGUAGE UndecidableInstances           #-}


module Uniform.Pandoc
  ( module Uniform.Pandoc
  , Pandoc(..)
  , module Uniform.Error   -- or at least ErrIO
  )
where

-- import           Data.Aeson                     ( toJSONList )
import           Test.Framework

-- import Data.Time as T
import           Text.Pandoc.Readers            ( readMarkdown )
import Text.DocTemplates              ( applyTemplate )
-- import qualified Data.Yaml                     as Y

import           Uniform.Error
-- import Uniform.Strings
import           Uniform.Filenames
import           Uniform.TypedFile              ( TypedFiles7(..)
                                                , TypedFiles5(..), TypedFile5(..)  
                                                )
import           Uniform.FileIO                 ( read8 )
import           Uniform.Json
import Uniform.Yaml  

-- import qualified Data.Yaml                     as Y
-- import qualified Data.HashMap.Lazy             as HML

import qualified Text.Pandoc                   as Pandoc
import           Text.Pandoc                    ( Pandoc(..)
                                                , ReaderOptions
                                                , Meta
                                                , MetaValue
                                                , writerHighlightStyle
                                                , writerExtensions
                                                , WriterOptions
                                                , writeHtml5String
                                                , def
                                                )

import           Text.Pandoc.Highlighting       ( tango )
import           Text.Pandoc.Shared             ( stringify )

extMD = Extension "md"

newtype MarkdownText = MarkdownText Text deriving (Show, Read, Eq, Ord)
-- a wrapper around Markdonw text
unMT (MarkdownText a) = a   --needed for other ops

instance Zeros MarkdownText where
  zero = MarkdownText zero
markdownFileType =
  TypedFile5 { tpext5 = extMD } :: TypedFile5 Text MarkdownText
--instance FileHandles MarkdownText
-- what is missing here?


instance TypedFiles7 Text  MarkdownText    where
-- handling Markdown and read them into MarkdownText
  wrap7 = MarkdownText
  unwrap7 (MarkdownText a) = a

readMd2meta :: Path Abs File -> ErrIO (Pandoc, Value)
-- ^ read a markdown file to metadata
readMd2meta md = do
  putIOwords ["readMd2meta", "readPandocFile", showT md]
  mdtext :: MarkdownText <- read8 md markdownFileType
  pandoc                 <- readMarkdown2 mdtext
  let meta2 = flattenMeta (getMeta pandoc)
  return (pandoc, meta2)

readMarkdown2 :: MarkdownText -> ErrIO Pandoc
readMarkdown2 (MarkdownText text1) =
  unPandocM $ readMarkdown markdownOptions text1

-- | Reasonable options for reading a markdown file
markdownOptions :: ReaderOptions
markdownOptions = Pandoc.def { Pandoc.readerExtensions = exts }
 where
  exts = mconcat
    [ Pandoc.extensionsFromList
      [ Pandoc.Ext_yaml_metadata_block
      , Pandoc.Ext_fenced_code_attributes
      , Pandoc.Ext_auto_identifiers
      , Pandoc.Ext_raw_html   -- three extension give markdown_strict
      , Pandoc.Ext_shortcut_reference_links
      , Pandoc.Ext_spaced_reference_links
      , Pandoc.Ext_citations           -- <-- this is the important extension for bibTex
      ]
    , Pandoc.githubMarkdownExtensions
    ]

  -- | Handle possible pandoc failure within the Action Monad
unPandocM :: Pandoc.PandocIO a -> ErrIO a
unPandocM op1 =
  do
      res <- callIO $ Pandoc.runIO
        (do  -- liftIO $putStrLn "unPandocM op"
          a <- op1 --       error "xx"
          -- liftIO $putStrLn "error xx"
          return a
        )
      either
        (\e -> do
          putIOwords ["unPandocM error", showT e]
          throwError . showT $ e
        )
        return
        res
    `catchError` (\e -> do
                   putIOwords ["unPandocM catchError", showT e]
                   throwError . showT $ e
                 )

getMeta :: Pandoc -> Pandoc.Meta
getMeta (Pandoc.Pandoc m _) = m

putMeta :: Pandoc.Meta -> Pandoc -> Pandoc
putMeta m1 (Pandoc _ p0) = Pandoc m1 p0

-- | Flatten a Pandoc 'Meta' into a well-structured JSON object, rendering Pandoc
-- text objects into plain strings along the way.
flattenMeta :: Pandoc.Meta -> Value
flattenMeta (Pandoc.Meta meta) = toJSON $ fmap go meta
 where
  go :: MetaValue -> Value
  go (Pandoc.MetaMap     m) = toJSON $ fmap go m
  go (Pandoc.MetaList    m) = toJSONList $ fmap go m
  go (Pandoc.MetaBool    m) = toJSON m
  go (Pandoc.MetaString  m) = toJSON m
  go (Pandoc.MetaInlines m) = toJSON $ stringify m
  go (Pandoc.MetaBlocks  m) = toJSON $ stringify m


readYaml2value :: Path Abs File -> ErrIO Value
-- read a yaml file to a value
-- error when syntax issue
readYaml2value fp = do
  t <- read8 fp yamlFileType
  return . yaml2value $ t

-- yaml2value :: YamlText -> Value
-- -- convert a YamlText to a JSON value, error if not ok
-- -- how to debug input erros?
-- yaml2value yt = either (error . show) id vx
--  where
--   vx = decodeEither' (t2b . unYAML $ yt) :: Either ParseException Value


-- newtype YamlText = YamlText Text deriving (Show, Read, Eq, Ord)
-- -- a wrapper around Markdonw text
-- unYAML (YamlText a) = a   --needed for other ops

-- extYAML = Extension "yaml"
-- instance Zeros YamlText where
--   zero = YamlText zero

-- yamlFileType = TypedFile5 { tpext5 = extYAML } :: TypedFile5 Text YamlText
-- --instance FileHandles YamlText
-- -- what is missing here?


-- instance TypedFiles7 Text  YamlText    where
-- -- handling Markdown and read them into YamlText
--   wrap7 = YamlText
--   unwrap7 (YamlText a) = a


-- | Reasonable options for rendering to HTML
html5Options :: WriterOptions
html5Options = def { writerHighlightStyle = Just tango
                   , writerExtensions     = writerExtensions def
                   }


writeHtml5String2 :: Pandoc -> ErrIO HTMLout
writeHtml5String2 pandocRes = do
  p <- unPandocM $ writeHtml5String html5Options pandocRes
  return . HTMLout $ p

newtype HTMLout = HTMLout Text deriving (Show, Read, Eq, Ord)

-- a wrapper around html ready to publish
unHTMLout (HTMLout a) = a

htmloutFileType = TypedFile5 { tpext5 = extHTML } :: TypedFile5 Text HTMLout

instance Zeros HTMLout where
  zero = HTMLout zero

instance TypedFiles7 Text HTMLout  where

  wrap7 = HTMLout
  unwrap7 (HTMLout a) = a


extMD, extHTML :: Extension
extHTML = Extension "html"

-- the final application
applyTemplate3 :: Dtemplate -> DocValue -> ErrIO HTMLout
-- apply the template in the file to the text
--
applyTemplate3 templText val =
     case applyTemplate (unwrap7 templText) (unDocValue val) of
          Left  msg  -> throwError . s2t $ msg
          Right val2 -> return . HTMLout $ (val2 :: Text)

          -- handling the doctype templates dtpl
extDtemplate :: Extension
extDtemplate = Extension "dtpl"

newtype Dtemplate = Dtemplate Text deriving (Show, Read, Eq, Ord)
-- ^ a template which contains variables in doctype  $x$  format

-- a wrapper around html ready to publish
--unDtemplate (Dtemplate a) = a

dtmplFileType :: TypedFile5 Text Dtemplate
dtmplFileType = makeTyped extDtemplate :: TypedFile5 Text Dtemplate

instance Zeros Dtemplate where zero = Dtemplate zero

instance TypedFiles5 Text Dtemplate  where
instance TypedFiles7 Text Dtemplate  where

    wrap7 = Dtemplate
    unwrap7 (Dtemplate a) = a


newtype DocValue = DocValue Value  deriving (Show,  Eq, Read)
-- ^ a value type with "content" which is a html translation
-- and all the other keys

unDocValue :: DocValue -> Value
unDocValue (DocValue v) = v

instance Zeros DocValue where zero = DocValue Null

instance NiceStrings DocValue where
    shownice = showNice .  unDocValue

docValueFileType :: TypedFile5 Text DocValue
docValueFileType = TypedFile5 {tpext5 = Extension "docval"} :: TypedFile5   Text DocValue
--instance FileHandles MarkdownText
-- what is missing here?


-- instance TypedFiles7 Text  DocValue    where
-- -- handling Markdown and read them into DocValue
--     wrap7 = DocValue . fromJustNote "wrap7 docvalue decode" . decode . b2bl . t2b
--     unwrap7 (DocValue a) = shownice a

mergeAll :: [Value] -> DocValue
-- merge the four diffferent value -- last winns
-- issue how to collect all css?
mergeAll  = DocValue . mergeAeson . reverse     