Consenting
==========

A FHIR `Contract` resource constitutes a consent document that can be rendered using a `ORKTaskViewController` view controller.
Currently only signing a contract is supported.


Geocoder
--------

A class `Geocoder` to help with (reverse) geocoding is provided.
This class is intended to be used for a one-time location determination, e.g. to obtain the user's location while consenting.
This may or may not be close to the patient's home location.

If you use this you **must include** a short description of why you're accessing the user's location under the key `NSLocationWhenInUseUsageDescription` in the app's Info.plist.
Otherwise you will never receive the location callback.
The user will see this string in an alert window the first time the geocoder is used.

```Swift
geocoder = Geocoder()       // ivar on e.g. the App Delegate
geocoder!.currentLocation() { current in
    println("==>  current location: \(current)")
}
```
