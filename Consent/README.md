Eligibility & Consent
=====================

A FHIR `Contract` resource constitutes a consent document that can be rendered using a `ORKTaskViewController` view controller and can be signed with a patient reference.
It can also contain eligibility criteria which a participant must answer first in order to be able to start consenting.


Eligibility
-----------

Eligibility criteria can be included in the `Contract` resource as the contract's `subject`, represented as a `Group` resource.

Here's an example group that requires participants to be older than 18 and reside in the US.
This is a Group resource that is contained in the Contract resource it applies to and referenced accordingly:

```json
{
  "id": "org.chip.c-tracker.consent",
  "resourceType": "Contract",
  ...
  "subject": [{
    "reference": "#eligibility"
  }],
  "contained": [{
    "id": "eligibility",
    "resourceType": "Group",
    "type": "person",
    "actual": false,
    "characteristic": [{
      "code": {
        "text": "Are you 18 years of age or older?"
      },
      "valueBoolean": true,
      "exclude": false
    },
    {
      "code": {
        "text": "Do you live in the United States of America?"
      },
      "valueBoolean": true,
      "exclude": false
    }]
  }]
}
```


Consent Workflow
----------------

To read eligibility and consent data from a bundled consent called `Consent.json` you can do the following.
It will also use the bundled file `Consent_full.html` to show a custom HTML page in the _“Agree”_ step instead of auto-generating that page from all consent sections.
This is optional and, if omitted, the consent will be composed of all the individual consenting sections.

You could use this method in combination with `setupUI()` shown in `StudyIntro/README.md`.

```swift
func startEligibilityAndConsent(intro: StudyIntroCollectionViewController) {
    self.controller = ConsentController(bundledContract: "Consent")  // retain
    controller.options.reviewConsentDocument = "Consent_full"     // optional
    
    let center = NSNotificationCenter.defaultCenter()
    center.addObserver(self, selector: "userDidConsent",
        name: C3UserDidConsentNotification, object: nil)
    
    let elig = controller.eligibilityStatusViewController(intro.config)
    if let navi = intro.navigationController {
        navi.pushViewController(elig)
    }
    else {
        // you did not put the intro view controller on a navigation controller
    }
}

func userDidConsent() {
    // Your user is consented. A generated PDF will be written to
    // `ConsentController.signedConsentPDFURL()` on a background queue, so
    // might not yet be available. Usually, the user is now prompted for app
    // setup (not yet provided by C3-PRO):
    // - set a passcode
    // - grant necessary permissions (notifications, HealthKit, Motion, ...)
}
```

First, the user will be asked your eligibility questions, and – if they are met – presents the consent task as a modal view controller.
If the user cancels or declines consent, the view controller is dismissed and the eligibility view controller popped from its navigation controller.
If the user consents the consent view controller is likewise dismissed and you'll receive the `C3UserDidConsentNotification` notification.

### Consent Sections

To represent consent sections that can be shown on screen, we usa a `Contract` resource and instantiate each `Contract.term` element as a `ORKConsentSection`.
These sections are added to a `ORKConsentDocument`'s `section` property to represent the _"visual"_ consenting step.
The properties to use are:

- `type`: one of [`ORKConsentSectionType`](http://researchkit.org/docs/Constants/ORKConsentSectionType.html) (without the _ORKConsentSectionType_ part)
- `text`: the section's summary

Several ResearchKit-specific parameters require the use of an extension.
We use nested extensions under the parent URI `http://fhir-registry.smarthealthit.org/StructureDefinition/ORKConsentSection`.
The nested extensions are:

- `title`: A string representing the title of the section
- `image`: A string for an image name, included in the app bundle, that will be assigned the section's `customImage` property.
- `animation`: A string for a movie name, included in the app bundle, that will be assigned the section's `customAnimationURL` property.
- `htmlContent`: A string representing the full HTML content, to be shown when “Learn More” is tapped.
- `htmlContentFile`: A name of an HTML file (without file extension) that contains the HTML to be shown when “Learn More” is tapped; needs to be added to the App Bundle

Example:

```json
{
  "id": "org.chip.c-tracker.consent",
  "resourceType": "Contract",
  "type": {
    "coding": [{
      "system": "http://hl7.org/fhir/contracttypecodes",
      "code": "consent"
    }]
  },
  "issued": "2015-08-18",
  "applies": {
    "start": "2015-08-18"
  },
  "authority": [{
    "reference": "#bch"
  }],
  "term": [{
    "type": {
      "coding": [{
        "system": "http://researchkit.org/docs/Constants/ORKConsentSectionType.html",
        "code": "Privacy"
      }]
    },
    "extension": [{
      "url": "http://fhir-registry.smarthealthit.org/StructureDefinition/ORKConsentSection",
      "extension": [{
        "url": "title",
        "valueString": "Privacy"
      },
      {
        "url": "htmlContentFile",
        "valueString": "5_privacyprotection"
      }]
    }],
    "text": "Your data will be sent to a secure database, ..."
  }]
}
```


### Sharing Options

To populate the team name used when the user is asked if he's willing to share his data with qualified researchers worldwide or just the study researchers, the `authority.name` property of the Contract is consulted.

> At this time this must be an _Organization_ element that is contained in the contract.

Example:

```json
{
  "id": "org.chip.c-tracker.consent",
  "resourceType": "Contract",
  ...
  "authority": [{
    "reference": "#team"
  }],
  "contained": [{
    "id": "team",
    "resourceType": "Organization",
    "name": "C Tracker Team"
  }]
}
```


Signing
-------

A signed `Contract` resource can be generated by providing a Patient resource and subsequently be sent to the SMART/FHIR backend:

```swift
let server = <# SMART client #>.server
consentController = ConsentController()       // ivar on e.g. the App Delegate
do {
    let contract = try consentController.signContractWithPatient(patient, date: NSDate())
    patient._server = server
    patient.update() { error in     // cannot use `create` as an ID was assigned
        if let error = error {
            println("Error creating patient: \(error)")
        }
        else {
            contract.create(server) { error in
                if let error = error {
                    println("Error creating contract: \(error)")
                }
            }
        }
    }
}
catch let error {
    chip_warn("Failed signing contract: \(error)")
}
```

For HIPAA-compliant (Safe Harbor) de-identified patient signing, including determining the (current) location, you can use `deIdentifyAndSignConsentWithPatient()`.
Using the `DeIdentifier` and `Geocoder` included in this framework, a de-identified Patient resource will be created alongside the Contract that can be sent to the SMART/FHIR backend:

```swift
let server = <# SMART client #>.server
consentController = ConsentController()       // ivar on e.g. the App Delegate
consentController!.deIdentifyAndSignConsentWithPatient(patient, date: NSDate()) { contract, patient, error in
    patient._server = server
    patient.update() { error in     // cannot use `create` as an ID was assigned
        if let error = error {
            println("Error creating patient: \(error)")
        }
        else {
            contract.create(server) { error in
                if let error = error {
                    println("Error creating contract: \(error)")
                }
            }
        }
    }
}
```


## Manual Overrides

If you don't want some of the automation, here are several points of entry that you can use to customize behavior.

### Separating Eligibility and Consenting

Sample code that could work this way on the app delegate, showing override points in the eligibility-consenting setup.
You could call `eligibilityStatusViewController()` and push the received view controller onto a navigation controller.

```swift
func eligibilityStatusViewController(withConfiguration config: StudyIntroConfiguration?) -> EligibilityStatusViewController {
  return consentController.eligibilityStatusViewController(config) { controller in
    let root = self.window!.rootViewController!
    do {
      let consentVC = try self.consentViewController()
      root.presentViewController(consentVC, animated: true, completion: nil)
    }
    catch let error {
      chip_warn("Failed to create consent view controller: \(error)")
    }
  }
}

func consentViewController() throws -> ORKTaskViewController {
  return try consentController.consentViewController(
    onUserDidConsent: { controller, result in
      // look at the consent result for participant's name, signature and sharing choice
      print("\(result.participantFriendlyName) DID CONSENT, START APP SETUP")
      controller.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    },
    onUserDidDecline: { controller in
      controller.navigationController?.popToRootViewControllerAnimated(false)
      controller.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
  )
}
```

### Manual Consenting Task

To create a consenting task from a bundled consent called `Consent.json` and show it using an `ORKTaskViewController` you can do the following.

```swift
let controller = ConsentController(bundledContract: "Consent")
let task = controller.createConsentTask()
let vc = ORKTaskViewController(task: task, taskRunUUID: NSUUID())
vc.delegate = <# your ORKTaskViewControllerDelegate #>
// now present `vc` somewhere
```
