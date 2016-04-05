Migrating Consent
=================

1.0.2 -> 1.4.0
--------------

We're still using the `Contract` resource to represent consent, with some changes:

- `Contract.signer[#].type` is using a new coding system; the previous value is now at `Contract.signer[#].signature[#].type`
- `Contract.signer[#].signature = String` -> `Contract.signer[#].signature = [Signature]`

