C3-PRO
======

This is the **iOS** framework, written in Swift, for our [C3-PRO][] research framework.

Combining [🔥 FHIR][fhir] and [ResearchKit][], usually for data storage into [i2b2][], this framework allows you to use FHIR _Questionnaire_ resources directly with ResearchKit and will return FHIR _QuestionnaireResponse_ that you can send to your server.
In addition, a FHIR _Contract_ resource can be used to carry trial eligibility requirements and define content to be shown during consenting.
Subsequently, the contract can be “signed” with a FHIR _Patient_ resource and returned to your server, indicating consent.

There are additional utilities for _encryption_, _geolocation_, _de-identification_ and _data queueing_ that go well with a research app.

#### Usage

The iOS framework is built of components that can be used individually, meaning you can use only the parts you need.

Taking a _pure Swift_ approach, you will not be able to use this framework with Objective-C alone.
Instead, you can use Swift code in your app, using a [mix and match][mix-match] approach, to connect the C3-PRO components to the Objective-C bits in your app.

See the [install instructions](Install.md), then use `C3PRO` in your code and start coding.
We also have a [sample app][] that demonstrates how some of the components can be used.

```swift
import C3PRO
```

#### Versions

The `master` branch currently supports _Swift 2.0_ and _FHIR 0.5.0_ and requires Xcode 7.
The `develop` branch is on _FHIR 1.0.2_.
For other versions see the [releases](releases) tab, for newer versions look for `feature/x` branches.

See [CHANGELOG.md](./CHANGELOG.md) for updates.
Since this framework combines several versioned technologies, the releases support:

 Version | Swift | ResearchKit |  FHIR
---------|-------|-------------|------
 **1.0** |   2.x |         1.3 | 1.0.2


Components
----------

The framework consists of several components that complement each other.

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

### HealthKit Extensions

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

### Identity and De-Identification

Helps creating de-identified patient resources, consistent with _HIPAA Safe Harbor_ guidelines, with birthdate and ZIP truncated accordingly.  
[➔ Identity](./Sources/Identity/)


Localization
------------

The framework uses `NSLocalizedString` on the `C3PRO` table name, meaning it's looking at the C3PRO.strings file for string localization.
There is an extension on _String_ so we can simply use `"My Text".c3_localized` in code; if you're looking in the code, search for this variable.


License
-------

This work is [Apache 2](./LICENSE.txt) licensed.
Be sure to take a look at the [NOTICE.txt](./NOTICE.txt) file, and don't forget to also add the licensing information of the two submodules somewhere in your product:

- [ResearchKit](./ResearchKit/LICENSE)
- [CryptoSwift](./CryptoSwift/LICENSE)


[C3-PRO]: http://c3-pro.chip.org
[fhir]: http://hl7.org/fhir/
[researchkit]: http://researchkit.github.io
[i2b2]: https://www.i2b2.org
[mix-match]: https://developer.apple.com/library/ios/documentation/Swift/Conceptual/BuildingCocoaApps/MixandMatch.html
[sample app]: https://github.com/chb/c3-pro-demo-ios
