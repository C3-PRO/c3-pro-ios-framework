DataQueue
=========

`DataQueue` is a FHIRServer implementation primarily used to move FHIR resources, created on device, to a FHIR server, without the need for user interaction nor -confirmation.

The idea is that data collection tasks do not need to inform the user whether a file was uploaded or not.
The queue acts like a standard SMART on FHIR server class, except that it automatically enqueues resources to disk when a POST fails.
Issuing a POST later on first clears the queue, if needed, before issuing the intended POST, to ensure creation order of all resources intended for the respective server.
The queue can also be manually flushed.

Usage
-----

You usually use `DataQueue` with a SMART client that can authorize without user authentication, like a _client_credentials_ flow, like so:

```swift
let baseURL = NSURL(string: "https://fhir-api-dstu2.smarthealthit.org")
let auth = [
    "client_id": "{key}",
    "client_secret": "{secret}",
    "authorize_type": "client_credentials",
] as OAuth2JSON
let dataQueue = DataQueue(baseURL: baseURL, auth: auth)
let smart = Client(server: dataQueue)
```

Now, whenever you issue a _create_ command on a FHIR _Resource_ (i.e. a POST request) and the request fails, the resource will automatically be enqueued.
Next time a POST command is issued and the queue is not empty, the queue is first (attempted to be) flushed, then the POST is executed.

```swift
let questionnaire = Questionnaire(json: {some FHIRJSON})
smart.authorize { patient, error in
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
smart.authorize { patient, error in
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

Resources are enqueued manually when a POST fails, but you can also enqueue manually:

```swift
let questionnaire = Questionnaire(json: {some FHIRJSON})
dataQueue.enqueueResource(questionnaire)
```
