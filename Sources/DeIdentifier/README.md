De-Identification
=================


DeIdentifier
------------

Helps creating a de-identified [FHIR `Patient` resource][patient] from a given resource and by looking up the device's current location.
After determining the location (see `Geocoder` below), the Patient resource will have:

- Gender
- Year of birth, capped at 90 years of age
- 3-digit ZIP, except for too sparsely populated areas, in which case ZIP is "000"
- Country


Geocoder
--------

A class `Geocoder` to help with (reverse) geocoding is provided.
This class is primarily intended to be used for a one-time location determination, e.g. to obtain the user's location while consenting.
This may or may not be close to the patient's home location.

If you use the geocoder you **must include** a short description of why you're accessing the user's location under the key `NSLocationWhenInUseUsageDescription` in the app's Info.plist.
Otherwise you will never receive the location callback.
The user will see this string in an alert window the first time the geocoder is used.

```swift
geocoder = Geocoder()       // ivar on e.g. the App Delegate
geocoder!.currentLocation() { current, error in
  println("Current location: \(current)")
  // <+37.33233141,-122.03121860> +/- 50.00m (speed -1.00 mps / course -1.00)
}
```

### HIPAA Safe Harbor

The geocoder takes care of reporting de-identified location data according to [HIPAA's Safe Harbor guidelines][hipaa].
There are convenience methods to retrieve locations in a HIPAA compliant [FHIR `Address` element][address], populated only with country and 3-digit ZIP.
For those areas where the 3-digit ZIP is not an acceptable form of de-identification, the ZIP code is set to “000”, as per the guidelines.

```swift
geocoder = Geocoder()       // ivar on e.g. the App Delegate
geocoder!.hipaaCompliantCurrentAddress() { address, error in
  println("Current address: \(address)")
  // {"country": "US", "postalCode": "950"}
}
```


[patient]: http://hl7.org/fhir/2015May/patient.html
[hipaa]: http://www.hhs.gov/ocr/privacy/hipaa/understanding/coveredentities/De-identification/guidance.html
[address]: http://hl7.org/fhir/2015May/datatypes.html#Address
