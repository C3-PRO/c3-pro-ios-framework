HealthKit & CoreMotion
======================

Activity data interesting for research is available from two places from iOS: **HealthKit** and **CoreMotion**.

This module provides facilities to easily retrieve data from HealthKit, but more importantly helps persisting CoreMotion activity data beyond the 7 day OS default.
Minimal activity data preprocessing is included and can easily be customized.

**Note** that as of iOS 10, you must provide a short explanation for `NSHealthShareUsageDescription`, if you use HealthKit, and `NSMotionUsageDescription`, if you use CoreMotion, in your app's _Info.plist_, in addition to enabling _HealthKit_ capabilities for your app.
You are also responsible to ask the user for permission before using the methods shown below, otherwise you'll simply get errors.
See [Sources/SystemServices](../../Sources/SystemServices/) for help on how to achieve that.


Activity Reporter
=================

The `ActivityReporter` protocol is adopted by:

- `HealthKitReporter`, querying HealthKit activity data
- `CoreMotionReporter`, querying persisted CoreMotion activity data
- `ActivityCollector`, combining HealthKit and CoreMotion activity data

### Module Interface

#### OUT
- `ActivityReport` and `ActivityReportPeriod`

### Methods of Interest

- `reportForActivityPeriod(startingAt:until:callback:)` to retrieve an activity report over the given period
- `progressivelyCollatedActivityData(callback:)` to retrieve an activity report with increasingly longer time periods going into the past; starting at daily reports over weekly into monthly periods

```swift
import Foundation
import C3PRO

let dir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
let path = (dir as NSString).stringByAppendingPathComponent("activities.db")
let motionReporter = CoreMotionReporter(path: path)
motionReporter.progressivelyCollatedActivityData() { report, error in
    if let error = error {
        // something went wrong
    }
    else if let periods = report?.periods {
        for period in periods {
            print("Report: \(period.debugDescription ?? "{none}")")
        }
    }
    else {
        // no data
    }
}
```

If you use `ActivityCollector` in the above example, which you'd use the exact same way except for how you instantiate, you'd also get a report of _HealthKit_ activity.


Core Motion Data Persistence
----------------------------

_CoreMotion_ continuously attempts to determine what the user is currently doing, and creates a _CMMotionActivity_ object whenever the activity type changes.
Those instances can indicate one or more (!) of the following activity _types_:

- stationary
- automotive
- walking
- running
- cycling

In addition, they indicate their _confidence_ in the assessment as low, medium or high.

These instances can be queried and the OS stores them for up to 7 days.
To have access to longer date periods, `CoreMotionReporter` can store these activities to a local SQLite database in a compact format so you have access to more than 7 days of activity data.

### Module Interface

#### IN
- queries `CMMotionActivityManager` for recent _CMMotionActivity_

#### OUT
- stores activity to SQLite


### Methods of Interest

- `archiveActivities(processor:callback:)`: archive all activities that occurred since last sampling (if any), do a bit of preprocessing and dump to the database
- `reportForActivityPeriod(startingAt:until:interpreter:callback:)`: retrieve activity data from the SQLite database (also see `ActivityReporter`)


### Archiving

The reporter does a bit of preprocessing that you can customize (or disable) if you want.
See the documentation of the `archiveActivities(processor:callback:)` method for how to supply your own, and `CoreMotionStandardActivityInterpreter`'s `preprocess(activities:)` for how the default preprocessor works.
Activity start dates are stored to 100ms accuracy.

Even if you expect your users to use your app at least once per week, you probably want to have iOS wake your app periodically so you can persist motion activity to SQLite.
Do do this we can abuse the _background fetch_ background mode of iOS.
Remember though that the device may be locked when the trigger happens, make sure file protection does not prevent you from accessing your SQLite database.

- Enable the _“Background Fetch”_ background mode in your app capabilities
- Set the minimum fetch interval to `UIApplicationBackgroundFetchIntervalMinimum` in `application:didFinishLaunchingWithOptions:`.
- Properly implement `application:performFetchWithCompletionHandler:`, so:

```swift
func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    ...
    application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
    ...
}

func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
    let reporter = CoreMotionReporter(path: <# database path #>)
    reporter.archiveActivities { numNewActivities, error in
        if let _ = error {
            completionHandler(.failed)
        }
        else {
            completionHandler(numNewActivities > 0 ? .newData : .noData)
        }
    }
}
```

You can also call `archiveActivities(callback:)` after the user launches the app.
This method will only query for new activities that were reported since the last archived activity, and at most every 2 minutes.


Extensions
==========

Extensions for _HealthKit_ classes for convenience.

### Module Interface

#### IN
- `HKQuantity` or `HKQuantitySample` to convert to FHIR.

#### OUT
- `Quantity` FHIR resource.
- `HKQuantity` instance(s) queried from `HKHealthStore`.


HKHealthStore
-------------

Methods that query the store for samples:

- `c3_latestSample(ofType:)`:  retrieve the latest sample of the given type.
- `c3_samplesOfTypeBetween()`: retrieve all samples of a given type between two dates.
- `c3_summaryOfSamplesOfTypeBetween()`: return a summary of all samples of a given type. 
    Use this to get an **aggregate count** of something over a given period


```swift
import HealthKit
import C3PRO

let store = HKHealthStore()

store.c3_latestSample(ofType: HKQuantityTypeIdentifier.height) { quantity, error in
    if let error = error {
        c3_warn("Error reading latest body height: \(error)")
    }
    else if let quantity = quantity {
        let unit = HKUnit.meter()
        let fhir = try! quantity.c3_asFHIRQuantityInUnit(unit)
        print("-->  \(fhir.asJSON())")
    }
    else {
        // no such quantity samples
    }
}


let end = Date()
var comps = DateComponents()
comps.day = -14
let start = Calendar.current.date(byAdding: comps, to: end)!

store.c3_summaryOfSamplesOfTypeBetween(HKQuantityTypeIdentifier.flightsClimbed, start: start, end: end) { result, error in
    if let result = result {
        let fhir = try! result.c3_asFHIRQuantity()
        print("-->  \(fhir.asJSON())")
    }
    else if let error = error {
        c3_warn("Failed to retrieve flights climbed: \(error)")
    }
    else {
        // no such quantity samples
    }
}
```


HKQuantity
----------

Extensions to `HKQuantitySample`, `HKQuantity` and `HKQuantityType` to ease working on them with FHIR:

- `HKQuantitySample.c3_asFHIRQuantity()` returns a FHIR _Quantity_ (or throws)
- `HKQuantity.c3_asFHIRQuantityInUnit(HKUnit)` returns a FHIR _Quantity_ (or throws)
- `HKQuantityType.c3_preferredUnit()` returns the preferred HKUnit for the type

