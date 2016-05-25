HealthKit & CoreMotion
======================




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

