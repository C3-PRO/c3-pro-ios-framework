Study Introduction
==================

These classes allow to display the standard _“Welcome to my study”_ screen that is shown to new users and allows them to inform themselves before joining your study.

### Module Interface

#### IN
- `StudyIntro.storyboard`, use the one provided and alter it, if needed.
- `StudyIntroConfiguration`, read from local JSON, for customization.

#### OUT
- `StudyIntroCollectionViewController`, ready to be shown.


Study Intro Collection View Controller
--------------------------------------

You start by instantiating a `StudyIntroCollectionViewController` and configuring it to your liking.
Then simply show it as the root view controller and your app already looks like a basic ResearchKit app.

You can use `StudyIntro.storyboard` provided with the framework but **you must** add it to your app's target yourself.
Customization is done via configuration, which you can either do manually in code or -- much better -- by using a JSON file loaded by the `StudyIntroConfiguration` class.

Here's an example that you could use from your App Delegate.
This assumes you have a file `StudyOverview.json` with the proper structure in your bundle:

```swift
func setupUI() {
  let intro = try! StudyIntroCollectionViewController.fromStoryboard(named: "StudyIntro")
  intro.config = try! StudyIntroConfiguration(json: "StudyOverview")
  intro.onJoinStudy = { viewController in
    // Action to perform when user taps "Join Study"
    // See `startEligibilityAndConsent()` in `Consent/README.md` on how
    // you can proceed with eligibility and consenting
    startEligibilityAndConsent(viewController)
  }
  let navi = UINavigationController(rootViewController: intro)
  window?.rootViewController = navi
}
```

`StudyOverview.json`
```json
{
  "title": "My Research App",
  "logo": "logo_disease_researchInstitute",
  "items": [
    {
      "type": "welcome",
      "title": "Welcome to My App",
      "subtitle": "An Awesome Research Study",
      "video": "VideoFile"
    },
    {
      "type": "video",
      "video": "VideoFile"
    },
    {
      "title": "About this Study",
      "filename": "Intro_about"
    },
    {
      "title": "How this Study works",
      "filename": "Intro_howstuffworks"
    },
    {
      "title": "Who is Eligible to Participate",
      "filename": "Intro_eligibility"
    }
  ]
}
```

Consent
-------

Add your blank consent PDF named `Consent.pdf` to the app bundle to make it accessible from a _welcome_ intro item.

You can use the _Consent & Eligibility_ classes contained in C3-PRO to move on to eligibility checking and consenting when the user taps “Join Study”.
A [`ConsentController`](../ConsentController) instance has a method `eligibilityStatusViewController()` that configures and returns a view controller that guides through simple YES/NO eligibility checking.
If you call this method on the intro's `onJoinStudy` block and display the returned view controller, you will get the default ResearchKit app experience when users want to join a study.
