C3-PRO
======

Combining [🔥 FHIR][fhir] and [ResearchKit][].
The built framework will be available as `C3PRO`:

```swift
import C3PRO
```


Requirements
------------

Apps built using this framework need to include:

- SMART (built with C3PRO)
- ResearchKit (built with C3PRO)
- HealthKit


Modules
-------

The framework provides a handful of modules that work well together but can be used individually.

### [StudyIntro](StudyIntro)

A view controller that renders configurable intro “sections”, through which a user can swipe left-to-right.
At the bottom sits a “Join Study” button, which can be used to start enrolling a potential participant with the next module:

### [Consent](Consent)

A controller can read a FHIR `Contract` resource, which is used to create a _ResearchKit_ consenting task.
At the end of this task the participant can sign the consent and is enrolled into the study.

TODO: the rest


[fhir]: http://hl7.org/fhir/
[researchkit]: http://researchkit.github.io
