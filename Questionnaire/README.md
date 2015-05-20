Questionnaires
==============

You use a FHIR `Questionnaire` resources in combination with a UIViewController that conforms to the `ORKTaskViewControllerDelegate` protocol.
This view controller can then present the questionnaire in an `ORKTaskViewController` and wait for completion of the questionnaire.

```swift
let questionnaire = <# FHIR Questionnaire #>
let promise = QuestionnairePromise(questionnaire: questionnaire)
promise.fulfill(nil) { errors in
    if let tsk = promise.task {
        let viewController = ORKTaskViewController(task: tsk, taskRunUUID: nil)
        viewController.delegate = self
        self.presentViewController(viewController, animated: true, completion: nil)
    }
    else {
        // error creating a task from questionnaire
    }
    if nil != errors {
        // one or more errors fulfilling the promise
    }
}
```
