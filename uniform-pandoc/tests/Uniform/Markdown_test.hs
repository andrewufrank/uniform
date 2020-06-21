-----------------------------------------------------------------------------
--
-- Module      :  pandoc test


-----------------------------------------------------------------------------
{-# OPTIONS_GHC -F -pgmF htfpp #-}
--{-# LANGUAGE AllowAmbiguousTypes   #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE ScopedTypeVariables   #-}
{-# LANGUAGE TypeFamilies          #-}
-- {-# LANGUAGE TypeSynonymInstances  #-}
-- {-# OPTIONS_GHC -fno-warn-missing-methods #-}

module Uniform.Markdown_test where
--
-- --import qualified Data.Text as T
-- import qualified System.Posix  as P (FileStatus)
-- --import qualified System.Directory as S
--
---- using uniform:
import Test.Framework
import Uniform.Pandoc 
import Uniform.Markdown
import Uniform.Test.TestHarness

-- import           Uniform.Strings     hiding ((</>), (<.>))
            -- (s2t, showT, t2s, removeChar, CharChains2 (..), Text)
--import Safe   -- todo error


import Uniform.Error           hiding (  (<.>)  )  -- (</>)

    -- all filenames without extension 
shortFile  =makeAbsFile "/home/frank/Workspace8/uniform/uniform-pandoc/tests/data/someTextShort"
regFile = makeAbsFile "/home/frank/Workspace8/uniform/uniform-pandoc/tests/data/someText"
complexFile = makeAbsFile "/home/frank/Workspace8/uniform/uniform-pandoc/tests/data/complex"

-- problem with readwrite tests - need two files to start 
test_readWrite = do 
    res4 <- runErr $ do 
        let pfn1 = makeAbsFile "/home/frank/Workspace8/uniform/uniform-pandoc/tests/data/someTextShort.md" 
        let pfn2 = makeAbsFile "/home/frank/Workspace8/uniform/uniform-pandoc/tests/data/someTextShort2.md" 

        pan1 <- read8 pfn1 markdownFileType 
        write8 pfn2  markdownFileType pan1

        pan2 <- read8 pfn2 markdownFileType
        return (pan1, pan2)
    let Right (target3, res3) = res4
    assertEqual target3 res3


-- test_readPandoc2 = do
--     res4 <- runErr $ do
--         let mfn = makeAbsFile "/home/frank/Workspace8/uniform/uniform-pandoc/tests/data/someTextShort.md" 
--         text1 <- read8 mfn markdownFileType 
--         res1 :: Pandoc <-  readMarkdown2  text1
--         -- putIOwords ["test_readPandoc2", showT text1, "\n", "res1\n", showT res1, "\n"]
--         let pfn = makeAbsFile "/home/frank/Workspace8/uniform/uniform-pandoc/tests/data/someTextShort.pandoc"
--         pres :: Pandoc <- read8 pfn pandocFileType
--         return (pres,  res1)
--     putIOwords ["test_readPandoc2", "\n res1\n", showT res4, "\n"]
--     let Right (target3, res3) = res4
--     assertEqual target3 res3

-- test_readPandoc2a = do
--     res4 <- runErr $ do
--         let mfn = makeAbsFile "/home/frank/Workspace8/uniform/uniform-pandoc/tests/data/someText.md"         
--         text1 <- read8 mfn markdownFileType 
--         res1 :: Pandoc <-  readMarkdown2  text1
--         -- putIOwords ["ptext1", showT text1, "\n", "res1\n", showT res1, "\n"]
--         let pfn = makeAbsFile "/home/frank/Workspace8/uniform/uniform-pandoc/tests/data/someText.pandoc"
--         pres :: Pandoc <- read8 pfn pandocFileType
--         return (pres,  res1)
--     let Right (target3, res3) = res4
--     assertEqual target3 res3

test_readPandocShort = testVar0FileIO "uniform-pandoc" 
        shortFile
        "test_readPandocShort" readPandoc2 
test_readPandocReg = testVar0FileIO "uniform-pandoc" 
        regFile
        "test_readPandocReg" readPandoc2 
test_readPandocComplex = testVar0FileIO "uniform-pandoc" 
        complexFile
        "test_readPandocComplex" readPandoc2 

-- testVar0FileIO :: (Zeros b, Eq b, Show b, Read b, ShowTestHarness b)
            -- => Text -> a -> FilePath -> (a-> ErrIO b) -> IO ()
readPandoc2 mfn  = do       
        text1 <- read8 mfn markdownFileType 
        res1 :: Pandoc <-  readMarkdown2  text1 
        write8 mfn pandocFileType res1
        return res1

-- res4text1 = "ttxx   " :: Text
instance ShowTestHarness Pandoc  