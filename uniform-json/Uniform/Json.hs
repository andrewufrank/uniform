-----------------------------------------------------------------------------
--
-- Module      :  Uniform.Json
--
-- | the operations on JSON data types 
-----------------------------------------------------------------------------
{-# LANGUAGE ConstraintKinds                #-}
{-# LANGUAGE DoAndIfThenElse                #-}
{-# LANGUAGE FlexibleContexts               #-}
{-# LANGUAGE FlexibleInstances              #-}
{-# LANGUAGE MultiParamTypeClasses          #-}
{-# LANGUAGE ScopedTypeVariables            #-}
{-# LANGUAGE TypeFamilies                   #-}
{-# LANGUAGE UndecidableInstances           #-}
{-# LANGUAGE OverloadedStrings       #-}

{-# OPTIONS_GHC -fno-warn-orphans #-}

module Uniform.Json
    ( module Uniform.Json
    , module Uniform.Error   -- or at least ErrIO
    , Value(..)
    , ToJSON(..), FromJSON(..)
    , fromJSON
    , decode, omitNothingFields
    -- , encode
    , object, (.=)
    , genericParseJSON, defaultOptions
    , HML.fromList, HML.toList
    , Result(..)
    
    )
where

import           Control.Lens                   ( (^?)
                                                , (?~)
                                                , (&)
                                                , at
                                                )

import           Data.Aeson
import           Data.Aeson.Lens
import Data.Aeson.Encode.Pretty (encodePretty)
import qualified Data.HashMap.Lazy   as HML
import Uniform.Strings  hiding ( at )
import           Uniform.Error           hiding ( at )

encodeT :: ToJSON a => a -> Text  
encodeT = bb2t . bl2b . encode 

fromJSONmaybe :: FromJSON a => Value -> Maybe a 
fromJSONmaybe v = case (fromJSON v) of 
            Success a -> Just a 
            _ -> Nothing 


fromJSONm :: (FromJSON a, Show a) => Value -> ErrIO a 
-- fromJSONm :: (FromJSON a, MonadError m) => Value -> m a   -- TODO in error
fromJSONm v = case (fromJSON v) of 
            Success a -> return a 
            x -> throwErrorT ["fromJson", showT x]

class AtKey vk v where
-- ^ get and set at a key 
    getAtKey :: vk -> Text -> Maybe v
    getAt2Key :: vk -> Text -> Text -> Maybe v
    putAtKey :: Text -> v -> vk -> vk

instance AtKey Value Text where
    getAtKey meta2 k2 = meta2 ^? key k2 . _String
    getAt2Key meta2 k1 k2 = meta2 ^? key k1 . key k2 . _String 
    putAtKey k2 txt meta2 = meta2 & _Object . at k2 ?~ String txt
--        (unHTMLout text2)
instance AtKey Value Integer where
    getAtKey meta2 k2 = meta2 ^? key k2 . _Integral
    getAt2Key meta2 k1 k2 = meta2 ^? key k1 . key k2 . _Integral 
    putAtKey k2 txt meta2 = meta2 & _Object . at k2 ?~ toJSON txt
--        (unHTMLout text2)
instance AtKey Value Bool where
    getAtKey meta2 k2 = meta2 ^? key k2 . _Bool
    getAt2Key meta2 k1 k2 = meta2 ^? key k1 . key k2 . _Bool 
    putAtKey k2 txt meta2 = meta2 & _Object . at k2 ?~ Bool txt


mergeAeson :: [Value] -> Value
-- ^ The (left-biased) union of two maps.
-- all values must be objects 
-- It prefers the first map when duplicate keys are encountered,
-- http://hackage.haskell.org/package/hashmap-1.3.3/docs/Data-HashMap.html
mergeAeson = Object . HML.unions . map (\(Object x) -> x)


instance NiceStrings Value where
    shownice = bb2t . bl2b . encodePretty

