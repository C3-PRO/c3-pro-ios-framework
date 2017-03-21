ProfileManager, User, UserTask
==============================

This module provides a `ProfileManager` and protocols – some with implementations – which help with user/profile management common in research apps.
You will provide your own implementation of `User` and `UserTask`, which makes this module very flexible but not usable out of the box.
For a simple sample implementation see the [C Tracker SCCS App][c-tracker-sccs], a live research app.


ProfileManager
--------------

The profile manager can be used to:

- enroll, "link" and withdraw a `User`; see "User" below
- schedule and react to tasks for a (`User` as `UserTask`); see "Task Schedule" below
- configure system services (such as CoreMotion and HealthKit access, notifications, ...)

You usually create one instance of this manager, e.g. in the app delegate, and hand it down to view controllers that need access to it.


User
----

Adapt this protocol if you want to make your user handling compatible with the profile manager.

A user can be enrolled in your study and can withdraw.
Upon enrollment, the profile manager will schedule of study tasks, see below for configuration.

### Linking

An app user can also be "linked" to a known patient or participant by scanning a JWT encoded in a QR code.
See our paper and the [C Tracker SCCS app][c-tracker-sccs] for details on this complex topic.
Of interest in this regard are the `ProfileLink` class, which you instantiate from JWT data that you obtained for example by scanning a QR code, `ProfileManager.userFromLink()` and `ProfileManager.establishLink(between:and:)`.


UserTask
--------

Tasks that the user is expected to complete.

### Task Schedule

A sample task schedule configuration to issue one survey (`taskType`) every month (`repeats`), repeated for a year (`expires`), can be postponed up to 14 days (`notificationType`, `delayMax`):

```json
{
    "activitySampleDays": 30,
    "tasks": [
        {
            "taskId": "c-tracker.survey-in-app.main",
            "taskType": "survey",
            "notificationType": "delayable",
            "repeats": "1m",
            "delayMax": "14d",
            "expires": "1y"
        }
    ]
}
```

The format is very basic at this time and understands numbers immediately followed by `h` (hours), `d` (days), `m` (months) and `y` (years).

### UserTaskPreparer

An instance of this class is used by `ProfileManager` to prepare tasks for the user.
Usually this means it looks ahead at tasks in the future and attempts to download resources, such as questionnaires, so the resource is ready when the task is due.

### UserTaskHandler

Provides implementations of what to do when the user completes a task.
Provided is `UserActivityTaskHandler`, which will react to completed `.survey` type tasks by:

- taking the task's `resultResource` (usually a QuestionnaireResponse resource) and assigning the respective user
- issuing a FHIR `create` call to the data server
- collect device activity data as configured
- serialize the activity data into a FHIR resource and also issue a `create` call on the data server
- collect latest user data (such as weight) from HealthKit
- serialize the health data into FHIR resources and again issue a `create` call on the data server


[c-tracker-sccs]: https://github.com/usz-rdsc/c-tracker-sccs
