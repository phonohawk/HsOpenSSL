module Main where

import OpenSSL
import Network.Socket as S
import OpenSSL.Session as SSL
import Data.ByteString.Char8 as BC

main = withOpenSSL (main')

main' = do
  -- open bare socket
  host <- inet_addr "127.0.0.1"
  socket <- socket AF_INET Stream defaultProtocol
  S.connect socket (SockAddrInet (fromIntegral 4112) host)

  -- setup context
  ctx <- SSL.context
  SSL.contextAddOption ctx SSL.SSL_OP_NO_SSLv2
  SSL.contextAddOption ctx SSL.SSL_OP_NO_SSLv3
  SSL.contextSetPrivateKeyFile ctx "client.pem"
  SSL.contextSetCertificateFile ctx "client.crt"
  SSL.contextSetVerificationMode ctx SSL.VerifyNone
  SSL.contextSetCiphers ctx "DEFAULT"
  SSL.contextCheckPrivateKey ctx >>= print

  -- wrap bare socket in an SSL connection
  wrappedSSLSocket <- SSL.connection ctx socket

  -- perform SSL client handshake
  _ <- SSL.connect wrappedSSLSocket

  -- write to socket
  SSL.write wrappedSSLSocket (BC.pack "Hello World!")

  -- read one response from peer
  b <- SSL.read wrappedSSLSocket 1024
  Prelude.putStrLn $ show b

  -- shutdown without waiting for peer to also shutdown
  SSL.shutdown wrappedSSLSocket SSL.Unidirectional
  Prelude.putStrLn "Done!"
