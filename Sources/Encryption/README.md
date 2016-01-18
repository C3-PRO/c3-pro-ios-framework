Encryption
==========

Encryption facilities that come in handy.
These can be used **without an additional OpenSSL library**, meaning you don't need to add OpenSSL to your app; these facilities rely solely on methods officially exposed by iOS's `Security.framework`.


RSAUtility
----------

Can use a (bundled) X509 public key certificate to encrypt a symmetric key that can be used elsewhere (see below).
Relies on `SecKeyEncrypt`, which comes with `Security.framework`, and is compatible with `RSA/ECB/OAEPWithSHA1AndMGF1Padding` padding.

Key pairs can be generated using OpenSSL on your desktop like so:

```
openssl req -x509 -days 3652 -out public.crt -outform DER -new -newkey rsa:2048 -keyout private.pem
```


AESUtility
----------

The AES utility can be used for symmetric key encryption and decryption, default key length is 32 bytes.
Relies on the [`CryptoSwift`](https://github.com/krzyzanowskim/CryptoSwift) submodule and is compatible with `AES/CBC/PKCS5Padding` encryption.

