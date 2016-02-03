Questionnaires
==============

You can use a FHIR `Questionnaire` resource in combination with a `QuestionnaireController` instance.
When the user completes the survey/questionnaire, rendered by ResearchKit, you'll get a `QuestionnaireResponse` back.

### Module Interface

#### IN
- `Questionnaire` FHIR resource.

#### OUT
- `QuestionnaireResponse` FHIR resource.
- `ORKTaskViewController` configured with a task representing the questionnaire.


QuestionnaireController
-----------------------

This model implements the `ORKTaskViewControllerDelegate` protocol and holds on to a callback block:

- Use `prepareQuestionnaireViewController()`, which fulfills any questionnaire dependencies before calling the callback, in which you get a handle to a `ORKTaskViewController` view controller that you can present on the UI.
- `whenCompleted` is called when the user completes the questionnaire without cancelling nor error and provides the responses in a `QuestionnaireResponse` resource
- `whenCancelledOrFailed` is called when the questionnaire is cancelled (error = nil) or finishes with an error


```swift
let controller = QuestionnaireController(questionnaire: <# FHIR Questionnaire #>)
controller.whenCompleted = { viewController, answers in
    viewController.dismissViewControllerAnimated(true, completion: nil)
	// `answers` is a FHIR "QuestionnaireResponse" resource if not nil
    // e.g. send to a SMART server:
    if let answers = answers {
        answers.create(<# smart.server #>) { error in
            // check if `error` is not nil and handle
        }
    }
}

controller.whenCancelledOrFailed = { viewController, error in
    viewController.dismissViewControllerAnimated(true, completion: nil)
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

### Choice and Bool Questions

There's a small sample Questionnaire [examples/Questionnaire-choices.json](../../examples/Questionnaire-choices.json) that has a `choice` and some `boolean` type questions.
Notice how you can skip questions 1 and 4 but not 2 and 3.
It also uses the `enableWhen` extension to conditionally show the 3rd question based on the answer to the 2nd question.

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

Full: [examples/Questionnaire-sliders.json](../../examples/Questionnaire-sliders.json)

