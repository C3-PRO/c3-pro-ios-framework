C3-PRO
======

**iOS** framework, written in Swift, for our [C3-PRO][] research framework.
Combining [🔥 FHIR][fhir] and [ResearchKit][] for data storage into [i2b2][], this framework allows you to use FHIR _Questionnaire_ directly with ResearchKit and will return FHIR _QuestionnaireAnswers_ to your server.
There are additional utilities for geolocation, de-identification and data queueing that go well with a research app.

The `master` branch currently supports _Swift 2.0_ and _FHIR 0.5.0_ and requires Xcode 7.
For other versions see the [releases](releases) tab, for newer versions look for `feature/x` branches.

See the [install instructions](Install.md), then use `import C3PRO` in your code files and start coding!


Components
----------

The framework consists of several components that complement each other.

### Consent

Using a FHIR `Contract` resource, representing the **consent document**, can render the consenting workflow with a ResearchKit task view controller.  
[➔ Consent](Consent)

### Questionnaires

Enables use of a FHIR `Questionnaire` resource as direct input to a ResearchKit **survey** task and return the encoded answers as a FHIR resource.
Also serves as return format of **activity data** collected on the phone.  
[➔ Questionnaire](Questionnaire)

### DataQueue

`DataQueue` is a FHIR server implementation used to move FHIR resources, created on device, to a FHIR server, without the need for user interaction nor -confirmation.  
[➔ DataQueue](DataQueue)

### Encryption

AES and RSA encryption facilities that come in handy.  
[➔ Encryption](Encryption)

### Identity and De-Identification

Helps creating de-identified patient resources, consistent with _HIPAA Safe Harbor_ guidelines, with birthdate and ZIP truncated accordingly.  
[➔ Identity](Identity)


License
-------

This work is [Apache 2](LICENSE.txt) licensed.

[C3-PRO]: http://c3-pro.chip.org
[fhir]: http://hl7.org/fhir/
[researchkit]: http://researchkit.github.io
[i2b2]: https://www.i2b2.org
