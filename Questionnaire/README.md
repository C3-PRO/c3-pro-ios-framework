Questionnaires
==============

You can use a FHIR `Questionnaire` resource in combination with a `QuestionnaireController` instance.
This model implements the `ORKTaskViewControllerDelegate` protocol and has a main method and holds on to a callback block:

- `prepareQuestionnaireViewController()` to fulfill any questionnaire dependencies before calling the callback, in which you get a handle to a `ORKTaskViewController` view controller that you can present on the UI
- `whenFinished` is called when the user finishes the questionnaire


```swift
let controller = QuestionnaireController()
controller.questionnaire = <# FHIR Questionnaire #>

controller.whenFinished = { viewController, reason, error in
    self.dismissViewControllerAnimated(true, completion: nil)
    if let err = error {
        // error when going through the questionnaire
    }
    else {
        // all done, result is in "viewController.result"
    }
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
