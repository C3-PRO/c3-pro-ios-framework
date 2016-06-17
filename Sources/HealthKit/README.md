HealthKit & CoreMotion
======================

Activity data interesting for research is available from two places from iOS: **HealthKit** and **CoreMotion**.

This module provides facilities to easily retrieve data from HealthKit, but more importantly helps persisting CoreMotion activity data beyond the 7 day OS default.
See below for details.


HealthKit Extensions
====================

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

- `c3_latestSampleOfType()`: retrieve the latest sample of the given type.
- `c3_samplesOfTypeBetween()`: retrieve all samples of a given type between two dates.
- `c3_summaryOfSamplesOfTypeBetween()`: return a summary of all samples of a given type. 
    Use this to get an **aggregate count** of something over a given period


```swift
import HealthKit
import C3PRO

let store = HKHealthStore()

store.c3_latestSampleOfType(HKQuantityTypeIdentifierHeight) { quantity, error in
    if let error = error {
        c3_warn("Error reading latest body height: \(error)")
    }
    else if let quantity = quantity {
        let unit = HKUnit.meterUnit()
        let fhir = try! quantity.c3_asFHIRQuantityInUnit(unit)
        print("-->  \(fhir.asJSON())")
    }
    else {
        // no such quantity samples
    }
}


let end = NSDate()
let comps = NSDateComponents()
comps.day = -14
let start = NSCalendar.currentCalendar().dateByAddingComponents(comps, toDate: end, options: [])!

store.c3_summaryOfSamplesOfTypeBetween(HKQuantityTypeIdentifierFlightsClimbed, start: start, end: end) { result, error in
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


CoreMotion
==========

_CoreMotion_ continuously attempts to determine what the user is currently doing, and creates a _CMMotionActivity_ object whenever the activity type changes.
Those instances can indicate one or more (!) of the following activity _types_:

- stationary
- automotive
- walking
- running
- cycling

In addition, they indicate their _confidence_ in the assessment as low, medium or high.

These instances can be queried and the OS stores them for up to 7 days.
To have access to longer date periods, this module stores these activities to a local SQLite database in a compact format so you have access to more than 7 days of activity data.

### Module Interface

#### IN
- persists _CMMotionActivity_ to SQLite

#### OUT
- `TBD`


CoreMotionReporter
------------------

- `archiveActivities(callback:)`: archive all activities that occurred since last sampling (if any), do a bit of preprocessing and dump to the database
- `TBD`: read activity data from the SQLite database

### Archiving

The reporter does a bit of preprocessing that you can customize (or disable) if you want.
See the documentation of the `archiveActivities(processor:callback:)` method for how to supply your own, and `preprocessMotionActivities(activities:)` for how the default preprocessor works.
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
            completionHandler(.Failed)
        }
        else {
            completionHandler(numNewActivities > 0 ? .NewData : .NoData)
        }
    }
}
```

You can also call `archiveActivities(callback:)` after the user launches the app.
This method will only query for new activities that were reported since the last archived activity, and at most every 2 minutes.

### Reporting

