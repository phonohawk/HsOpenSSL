module Main (main) where
import OpenSSL.DER
import qualified Test.Framework as TF
import qualified Test.Framework.Providers.HUnit as TF
import Test.HUnit

test_encodeDecodeEqual :: Test
test_encodeDecodeEqual = TestCase $ do
  keyPair <- generateRSAKey 1024 3 Nothing
  pubKey <- rsaCopyPublic keyPair
  assertEqual "encodeDecode" (Just pubKey) (fromDERPub (toDERPub keyPair))

main :: IO ()
main = TF.defaultMain $ TF.hUnitTestToTests test_encodeDecodeEqual
