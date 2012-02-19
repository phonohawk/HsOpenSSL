{- -*- haskell -*- -}

-- |Asymmetric cipher decryption using encrypted symmetric key. This
-- is an opposite of "OpenSSL.EVP.Seal".

module OpenSSL.EVP.Open
    ( open
    , openBS
    , openLBS
    )
    where

import qualified Data.ByteString.Char8 as B8
import qualified Data.ByteString.Lazy.Char8 as L8
import           Foreign hiding (unsafePerformIO)
import           System.IO.Unsafe (unsafePerformIO)
import           Foreign.C
import           OpenSSL.EVP.Cipher hiding (cipher)
import           OpenSSL.EVP.PKey
import           OpenSSL.EVP.Internal
import           OpenSSL.Utils


foreign import ccall unsafe "EVP_OpenInit"
        _OpenInit :: Ptr EVP_CIPHER_CTX
                  -> Cipher
                  -> Ptr CChar
                  -> CInt
                  -> CString
                  -> Ptr EVP_PKEY
                  -> IO CInt


openInit :: KeyPair key => Cipher -> String -> String -> key -> IO CipherCtx
openInit cipher encKey iv pkey
    = do ctx <- newCipherCtx
         withCipherCtxPtr ctx $ \ ctxPtr ->
             withCStringLen encKey $ \ (encKeyPtr, encKeyLen) ->
                 withCString iv $ \ ivPtr ->
                     withPKeyPtr' pkey $ \ pkeyPtr ->
                         _OpenInit ctxPtr cipher encKeyPtr (fromIntegral encKeyLen) ivPtr pkeyPtr
                              >>= failIf_ (== 0)
         return ctx

-- |@'open'@ lazilly decrypts a stream of data. The input string
-- doesn't necessarily have to be finite.
open :: KeyPair key =>
        Cipher -- ^ symmetric cipher algorithm to use
     -> String -- ^ encrypted symmetric key to decrypt the input string
     -> String -- ^ IV
     -> key    -- ^ private key to decrypt the symmetric key
     -> String -- ^ input string to decrypt
     -> String -- ^ decrypted string
open cipher encKey iv pkey input
    = L8.unpack $ openLBS cipher encKey iv pkey $ L8.pack input

-- |@'openBS'@ decrypts a chunk of data.
openBS :: KeyPair key =>
          Cipher     -- ^ symmetric cipher algorithm to use
       -> String     -- ^ encrypted symmetric key to decrypt the input string
       -> String     -- ^ IV
       -> key        -- ^ private key to decrypt the symmetric key
       -> B8.ByteString -- ^ input string to decrypt
       -> B8.ByteString -- ^ decrypted string
openBS cipher encKey iv pkey input
    = unsafePerformIO $
      do ctx <- openInit cipher encKey iv pkey
         cipherStrictly ctx input

-- |@'openLBS'@ lazilly decrypts a stream of data. The input string
-- doesn't necessarily have to be finite.
openLBS :: KeyPair key =>
           Cipher         -- ^ symmetric cipher algorithm to use
        -> String         -- ^ encrypted symmetric key to decrypt the input string
        -> String         -- ^ IV
        -> key            -- ^ private key to decrypt the symmetric key
        -> L8.ByteString -- ^ input string to decrypt
        -> L8.ByteString -- ^ decrypted string
openLBS cipher encKey iv pkey input
    = unsafePerformIO $
      do ctx <- openInit cipher encKey iv pkey
         cipherLazily ctx input
