Questionnaires
==============

You can use a FHIR `Questionnaire` resource in combination with a `QuestionnaireController` instance.
This model implements the `ORKTaskViewControllerDelegate` protocol and has a main method and holds on to a callback block:

- `prepareQuestionnaireViewController()` to fulfill any questionnaire dependencies before calling the callback, in which you get a handle to a `ORKTaskViewController` view controller that you can present on the UI
- `whenFinished` is called when the user finishes the questionnaire without error
- `whenFailed` is called when the questionnaire finishes with an error


```swift
let controller = QuestionnaireController()
controller.questionnaire = <# FHIR Questionnaire #>

controller.whenFinished = { reason, answers in
    self.dismissViewControllerAnimated(true, completion: nil)
	// `reason` is an "ORKTaskViewControllerFinishReason" instance
	// `answers` is a FHIR "QuestionnaireAnswers" resource
}

controller.whenFailed = { error in
	// maybe do something with `error`
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
