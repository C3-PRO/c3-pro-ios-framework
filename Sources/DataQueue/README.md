DataQueue
=========

`DataQueue` is a FHIRServer implementation primarily used to move FHIR resources, created on device, to a FHIR server, without the need for user interaction nor -confirmation.

### Module Interface

#### IN
- Any FHIR `Resource` that needs to be sent to a FHIR server.
- OAuth2 Dynamic Client Registration:
    + With additional App Receipt payload

#### OUT
- _Unencrypted_: performs any standard FHIR request using JSON.
- _Encrypted_: encrypts, creates a simple JSON body with keys `key_id`, `symmetric_key`, `message` and `version` (see below) and performs a request against a separate endpoint in a FHIR-like manner.

Data Queue
----------

The idea is that data collection tasks do not need to inform the user whether a file was uploaded or not.
The queue acts like a standard SMART on FHIR server class, except that it automatically enqueues resources to disk when a POST fails.
Issuing a POST later on first clears the queue, if needed, before issuing the intended POST, to ensure creation order of all resources intended for the respective server.
The queue can also be manually flushed.


Encrypted Queue
---------------

There is also an `EncryptedDataQueue` subclass.
Instances of this class are capable of encrypting resources before sending them to a server, keeping track of a standard FHIR endpoint and an additional encrypted data endpoint.
Resources-to-encrypt are, by default, AES encrypted with a random 32 byte key.
The random key itself is RSA encrypted using a public key in a X509 certificate, identified by an id, that is generated server-side (and the server has the private key).
A request with a JSON body containing a key-identifier and base-64 encoded key and resource data is then sent to the encrypted endpoint:

```json
{
  "key_id": "{public-key-id}",
  "symmetric_key": "{base64-encoded-RSA-encrypted-AES-key}",
  "message": "{base64-encoded-AES-encrypted-FHIR-resource}",
  "version": "1.0.2"
}
```

You can implement a delegate to only encrypt certain resources, and the instance can handle two different endpoints so "normal" FHIR requests can be routed to a standard FHIR endpoint (just like `DataQueue` does).
Only resources to-be-encrypted are sent to the "encrypt" endpoint.


Usage
-----

You usually use `DataQueue` with a SMART client that can authorize without user authentication, like a _client_credentials_ flow, as follows.
If you set `authorize_uri` manually, the client will not attempt to fetch the server's [Conformance statement](http://hl7.org/fhir/conformance.html) and uses the supplied endpoint insted.

```swift
let baseURL = NSURL(string: "https://fhir-api-dstu2.smarthealthit.org")
let auth = [
    "client_id": "{key}",         // or use dyn reg, see below
    "client_secret": "{secret}",
    "authorize_uri": "{OAuth2 authorize endpoint URL}",
    "authorize_type": "client_credentials",
] as OAuth2JSON
let dataQueue = DataQueue(baseURL: baseURL, auth: auth)
let smart = Client(server: dataQueue)
```

Now, whenever you issue a _create_ or _update_ command on a FHIR _Resource_ (i.e. a POST or PUT request) and the request fails, the resource will automatically be enqueued.
Next time a command is issued and the queue is not empty, the queue is first (attempted to be) flushed, then the POST or PUT is executed.

```swift
let questionnaire = Questionnaire(json: {some FHIRJSON})
smart.authorize() { patient, error in
    if let error = error {
        // error authorizing
    }
    else {
        questionnaire.create(smart.server) { error in
            // handle error, if you like
        }
    }
}
```

You can also flush the queue manually:

```swift
smart.authorize() { patient, error in
    if let error = error {
        // error authorizing
    }
    else {
        dataQueue.flush() { error in
            // check error; you may attempt to re-flush any time
        }
    }
}
```

Resources are enqueued automatically when a POST or PUT fails, but you can also enqueue manually:

```swift
let questionnaire = Questionnaire(json: {some FHIRJSON})
dataQueue.enqueueResource(questionnaire)
```


Dynamic Client Registration
---------------------------

You probably want to protect your endpoint to only accept OAuth2-signed requests from registered clients.
You can either ship your app with `client_id` and `client_secret` embedded, which may be possible to extract from your app binary, or you can use [dynamic client registration](https://tools.ietf.org/html/rfc7591) to register your app the first time it makes a request.
The latter is automatically performed for you when you supply a `registration_uri` when instantiating the server handle.

C3-PRO contains a dynamic client registration variant that allows client registration based on valid App Store receipts.
Use as follows:

```swift
let baseURL = NSURL(string: "https://fhir-api-dstu2.smarthealthit.org")
let auth = [
    "client_name": "My Awesome App",
    "authorize_uri": "{OAuth2 authorize endpoint URL}",
    "registration_uri": "{OAuth2 dynamic client registration endpoint URL}",
    "authorize_type": "client_credentials",
] as OAuth2JSON

let dataQueue = DataQueue(baseURL: baseURL, auth: auth)
dataQueue.onBeforeDynamicClientRegistration = { url in
    return OAuth2DynRegAppStore()
}
smart = Client(server: dataQueue)
```

The framework automatically attempts to register your app when you call `authorize()` if

1. there **is no** client-id and
2. there **is** a registration URL.

Registration credentials are stored to the keychain.
