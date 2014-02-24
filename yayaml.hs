{-# LANGUAGE OverloadedStrings #-}

-- import           Blaze.ByteString.Builder
-- import           Blaze.ByteString.Builder.Char8
import           Data.Text.Lazy.Builder 
import           Data.Attoparsec
import qualified Data.ByteString.Lazy.Char8 as L
-- import           Data.Foldable
-- import qualified Data.HashMap.Strict as HM
import           Data.List (intersperse)
import           Data.Monoid ((<>), mconcat, mempty)
import           Data.Scientific
import qualified Data.String as S (IsString(..), fromString)
import qualified Data.Text.Lazy as T
import qualified Data.Text.Lazy.IO as TIO
import qualified Data.Vector as V

data ListStyle = Inline | Wrapped 

data YamlValue = YObject [(T.Text, YamlValue)]
               | YLArray [YamlPrimValue]
               --  | YIArray [YamlValue]
               | YPrim YamlPrimValue 

data YamlPrimValue = YNumber Scientific
                   | YString T.Text
                   | YBool Bool 
                   | YNull 

instance S.IsString YamlPrimValue where
  fromString str = YString (T.pack str) 

instance S.IsString YamlValue where
  fromString = YPrim . S.fromString

defIndent :: Int
defIndent = 4 

buildYaml :: Int -> YamlValue -> Builder 
buildYaml n (YObject m) = (mconcat . map (buildPair n) ) m
buildYaml n (YLArray xs) = buildList n xs 
buildYaml n (YPrim p) = buildPrim p 

buildList :: Int -> [YamlPrimValue] -> Builder 
buildList n xs = fromLazyText "[ "
                 <> (mconcat . intersperse (fromLazyText ", ") . map buildPrim ) xs 
                 <> fromLazyText " ]"

buildPrim (YNumber s) = scientificBuilder s 
buildPrim (YString txt) = fromLazyText txt
buildPrim (YBool b) = (fromLazyText . T.pack . show) b 
buildPrim YNull = mempty 

buildPair :: Int -> (T.Text, YamlValue) -> Builder
buildPair n (k,v) = fromLazyText "\n" <> mconcat (replicate n (fromString "_")) 
                    <> fromLazyText k <> fromLazyText ": " <> buildYaml (n+defIndent) v 



testvalue = YObject $ [ ("abc", "haha")
                      , ("def", testvalue2)
                      , ("acd", testvalue3) 
                      , ("lo" , YPrim (YNumber (fromFloatDigits 314.159)))
                      ]
testvalue2 = YObject $ [ ("hello", "okay") 
                       , ("world", "no")
                       ] 

testvalue3 = YLArray [ "a", "bc" , "abc", "babo" ] 

main :: IO ()
main = do 
  putStrLn "yayaml"
  TIO.putStrLn $ toLazyText (buildYaml 4 testvalue)
