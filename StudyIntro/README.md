Study Introduction
==================

These classes allow to display the standard _“Welcome to my study”_ screen that is shown to new users and allows them to inform themselves before joining your study.

You start by instantiating a `StudyIntroCollectionViewController` and configuring it to your liking.
Then simply show it as the root view controller and your app already looks like a basic ResearchKit app.

You can use `StudyIntro.storyboard` provided with the framework but **you must** add it to your app's target yourself.
Customization is done via configuration, which you can either do manually in code or -- much better -- by using a JSON file loaded by the `StudyIntroConfiguration` class.

Here's an example that you could use from your App Delegate.
This assumes you have a file `StudyOverview.json` with the proper structure in your bundle:

```swift
func setupUI() {
    let intro = try! StudyIntroCollectionViewController.fromStoryboard("StudyIntro")
	intro.config = try! StudyIntroConfiguration(json: "StudyOverview")
	let navi = UINavigationController(rootViewController: intro)
	window?.rootViewController = navi
}
```

### Consent

Add your blank consent PDF named `Consent.pdf` to the app bundle to make it accessible from a _welcome_ intro item.
