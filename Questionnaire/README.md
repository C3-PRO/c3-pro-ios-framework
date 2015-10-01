Questionnaires
==============

You can use a FHIR `Questionnaire` resource in combination with a `QuestionnaireController` instance.
This model implements the `ORKTaskViewControllerDelegate` protocol and holds on to a callback block:

- `prepareQuestionnaireViewController()` to fulfill any questionnaire dependencies before calling the callback, in which you get a handle to a `ORKTaskViewController` view controller that you can present on the UI
- `whenCompleted` is called when the user completes the questionnaire without cancelling nor error
- `whenCancelledOrFailed` is called when the questionnaire is cancelled (error = nil) or finishes with an error.


```swift
let controller = QuestionnaireController()
controller.questionnaire = <# FHIR Questionnaire #>

controller.whenCompleted = { answers in
    self.dismissViewControllerAnimated(true, completion: nil)
	// `answers` is a FHIR "QuestionnaireResponse" resource if not nil
    // e.g. send to a SMART server:
    if let answers = answers {
        answers.create(<# smart.server #>) { error in
            // check if `error` is not nil and handle
        }
    }
}

controller.whenCancelledOrFailed = { error in
    self.dismissViewControllerAnimated(true, completion: nil)
	// check if `error` is not nil and handle
}

controller.prepareQuestionnaireViewController() { viewController, error in
    if let vc = viewController {
        self.presentViewController(vc, animated: true, completion: nil)
    }
    else {
        // error preparing the questionnaire in "error"
    }
}
```


Examples
--------

Examples on how to achieve certain ResearchKit steps with FHIR.

### Slider for Integers

This will show the title “FHIR Likening”, a smaller instruction text and a slider going from 0-10, with 8 pre-selected.
Sliders with more than 5 steps will render vertically instead of horizontally.
If no default value is specified, the minimum value will be pre-selected.

```json
{
    "linkId": "intSlider",
    "extension": [
        {
            "url": "http://hl7.org/fhir/StructureDefinition/questionnaire-instruction",
            "valueString": "Rate how much you truly like FHIR"
        },
        {
            "url": "http://hl7.org/fhir/StructureDefinition/minValue",
            "valueInteger": 0
        },
        {
            "url": "http://hl7.org/fhir/StructureDefinition/minValue",
            "valueString": "Not at all"
        },
        {
            "url": "http://hl7.org/fhir/StructureDefinition/maxValue",
            "valueInteger": 10
        },
        {
            "url": "http://hl7.org/fhir/StructureDefinition/maxValue",
            "valueString": "Very very much"
        },
        {
            "url": "http://hl7.org/fhir/StructureDefinition/questionnaire-defaultValue",
            "valueInteger": 8
        }
    ],
    "text": "FHIR Likening",
    "type": "integer"
}
```

Full: [examples/Questionnaire-sliders.json](examples/Questionnaire-sliders.json)

