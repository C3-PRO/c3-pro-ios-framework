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
// Let's assume you have a Questionnaire "Survey.json" in your app bundle
// You can use other means, such as `Questionnaire.read(id:server:callback:)`,
// to read a questionnaire from a FHIR server.
let questionnaire = NSBundle.mainBundle().fhir_bundledResource("<# Survey #>")
let controller = QuestionnaireController(questionnaire: questionnaire)
controller.whenCompleted = { viewController, answers in
    viewController.dismissViewControllerAnimated(true, completion: nil)
	// `answers` is a FHIR "QuestionnaireResponse" resource if not nil
    if let answers = answers {
        // e.g. send to a SMART server:
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

// you will need a type/instance variable to hold on to `controller`
self.controller = controller
```


Examples
--------

Examples on how to achieve certain ResearchKit steps with FHIR.

As of DSTU-2, questionnaire groups can contain other groups and questions.
If you add a `title` or `text` to a group, it will automatically insert an instruction step.
Otherwise the group will be transparent, only its questions will show up.

### Choice and Bool Questions

There's a small sample Questionnaire [Questionnaire-choices.json](../../examples/Questionnaire/Questionnaire-choices.json) that has a `choice` and some `boolean` type questions.
A _choice_ question becomes a _multiple choice_ question when its `repeats` flag is set to true.
You can use the `max-occurs` extension to limit the number of choices.

Notice how you can skip questions 1 and 2 but not 4 and 4 in the sample questionnaire.
The sample also uses `item.enableWhen` to conditionally show the 4th question based on the answer to the 3rd question.

The respective response resource with sample answers is shown in [examples/QuestionnaireResponse/QuestionnaireResponse-choices.json](../../examples/QuestionnaireResponse/QuestionnaireResponse-choices.json).

### Text and Values, Slider for Integers

The [Questionnaire-textvalues.json](../../examples/Questionnaire/Questionnaire-textvalues.json) example contains samples for textual and numerical input.

The following will show the title “FHIR Likening”, a smaller instruction text and a slider going from 0-10, with 8 pre-selected.
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

### Date and Time

The [Questionnaire-dates.json](../../examples/Questionnaire/Questionnaire-dates.json) example contains samples for date and time input.

