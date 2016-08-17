<img src="./assets/Logo.png" srcset="./assets/Logo@2x.png 2x, ./assets/Logo@3x.png 3x" alt="C3-PRO">

This is the **iOS** framework, written in Swift, for our [C3-PRO][] research framework.

Combining [🔥 FHIR][fhir] and [ResearchKit][], usually for data storage into [i2b2][], this framework allows you to use FHIR _Questionnaire_ resources directly with ResearchKit and will return FHIR _QuestionnaireResponse_ that you can send to your server.
In addition, a FHIR _Contract_ resource can be used to carry trial eligibility requirements and define content to be shown during consenting.
Subsequently, the contract can be “signed” with a FHIR _Patient_ resource and returned to your server, indicating consent.

There are additional utilities for _encryption_, _geolocation_, _de-identification_ and _data queueing_ that go well with a research app.
These are individual modules, meaning you can use only the parts you need.
See below for what's included.

#### Usage

Taking a _pure Swift_ approach, you will not be able to use this framework with Objective-C alone.
Instead, you can use Swift code in your app, using a [mix and match][mix-match] approach, to connect the C3-PRO components to the Objective-C bits in your app.

[⤵️ Installation](INSTALL.md)  
[📱 Sample App][sample app]  
[📖 Technical Documentation][docs]

```swift
import C3PRO
```


#### Versions

The `master` branch requires Xcode 7.3 and _should_ always be compatible with the latest version released.
The `develop` branch may contain new developments and have different requirements.
See the [releases](releases) tab for previous releases, for newer versions look for `feature/x` branches.

See [CHANGELOG.md](./CHANGELOG.md) for updates.
This framework combines several versioned technologies, here's an overview over what's included:

   Version |   Swift | ResearchKit |  FHIR
-----------|---------|-------------|------
   **2.0** |     3.0 |         1.3 | 1.7.0
   **1.9** |     3.0 |         1.3 | 1.6.0
   **1.8** |     3.0 |         1.3 | 1.0.2
   **1.2** |     2.2 |         1.3 | 1.6.0
   **1.1** |     2.2 |         1.3 | 1.0.2
 **1.0.1** |     2.2 |         1.3 | 1.0.2
   **1.0** | 2.0-2.2 |         1.3 | 1.0.2


Modules
-------

The framework consists of several modules that complement each other.

### Study Introduction

Shows the well-known _“Welcome to my study”_ screens that allows users to inform themselves before joining your study.  
[➔ Study Intro](./Sources/StudyIntro/)

### Eligibility & Consent

Using a FHIR `Contract` resource representing the **consent document**, can render eligibility questions and the consenting workflow.  
[➔ Consent](./Sources/Consent/)

### Questionnaires

Enables use of a FHIR `Questionnaire` resource as direct input to a ResearchKit **survey** task and return the encoded answers as a FHIR resource.
Also serves as return format of **activity data** collected on the phone.  
[➔ Questionnaire](./Sources/Questionnaire/)

### DataQueue

`DataQueue` is a FHIR server implementation used to move FHIR resources, created on device, to a FHIR server, without the need for user interaction nor -confirmation.  
[➔ DataQueue](./Sources/DataQueue/)

### HealthKit & CoreMotion (Activity Data)

`ActivityReporter` implementations for _HealthKit_ and _CoreMotion_.
The latter includes persistence of activity data past the 7 days iOS default.
Extensions to _HealthKit_ classes to easily query for samples and to represent quantities in FHIR.  
[➔ HealthKit](./Sources/HealthKit/)

### System Service Permissions

Facilities to request permission to send notifications, access HealthKit and others.
These can be integrated into the Consent flow.  
[➔ SystemServices](./Sources/SystemServices)

### Encryption

AES and RSA encryption facilities that come in handy.
These work with facilities officially exposed by iOS, meaning you **don't need to add OpenSSL** to your app.  
[➔ Encryption](./Sources/Encryption/)

### De-Identification & Geocoder

Helps creating de-identified patient resources, consistent with _HIPAA Safe Harbor_ guidelines, with birthdate and ZIP (determined by _Geocoder_) truncated accordingly.  
[➔ DeIdentifier](./Sources/DeIdentifier/)


Localization
------------

The framework uses `NSLocalizedString` on the `C3PRO` table name, meaning it's looking at the C3PRO.strings file for string localization.
There is an extension on _String_ so we can simply use `"My Text".c3_localized` in code.
If you're looking for localizable strings in code, search for this variable.


License
-------

This work is [Apache 2](./LICENSE.txt) licensed.
Be sure to take a look at the [NOTICE.txt](./NOTICE.txt) file, and don't forget to also add the licensing information of the two submodules somewhere in your product:

- [ResearchKit](./ResearchKit/LICENSE)
- [CryptoSwift](./CryptoSwift/LICENSE)


[C3-PRO]: http://c3-pro.org
[fhir]: http://hl7.org/fhir/
[researchkit]: http://researchkit.github.io
[i2b2]: https://www.i2b2.org
[mix-match]: https://developer.apple.com/library/ios/documentation/Swift/Conceptual/BuildingCocoaApps/MixandMatch.html
[sample app]: https://github.com/C3-PRO/c3-pro-demo-ios
[docs]: http://chb.github.io/c3-pro-ios-framework/
