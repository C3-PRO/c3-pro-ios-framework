HealthKit Extensions
====================

Extensions of HealthKit classes for convenience.


HKHealthStore
-------------

Methods that query the store for samples:

- `chip_latestSampleOfType()`: retrieve the latest sample of the given type.
- `chip_samplesOfTypeBetween()`: retrieve all samples of a given type between two dates.
- `chip_summaryOfSamplesOfTypeBetween()`: return a summary of all samples of a given type. 
    Use this to get an **aggregate count** of something over a given period


```swift
import HealthKit
import C3PRO

let store = HKHealthStore()

store.chip_latestSampleOfType(HKQuantityTypeIdentifierHeight) { quantity, error in
    if let error = error {
        chip_warn("Error reading latest body height: \(error)")
    }
    else if let quantity = quantity {
        let unit = HKUnit.meterUnit()
        let fhir = try! quantity.chip_asFHIRQuantityInUnit(unit)
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

store.chip_summaryOfSamplesOfTypeBetween(HKQuantityTypeIdentifierFlightsClimbed, start: start, end: end) { result, error in
    if let result = result {
        let fhir = try! result.chip_asFHIRQuantity()
        print("-->  \(fhir.asJSON())")
    }
    else if let error = error {
        chip_warn("Failed to retrieve flights climbed: \(error)")
    }
    else {
        // no such quantity samples
    }
}
```


HKQuantity
----------

Extensions to `HKQuantitySample`, `HKQuantity` and `HKQuantityType` to ease working on them with FHIR:

- `HKQuantitySample.chip_asFHIRQuantity()` returns a FHIR _Quantity_ (or throws)
- `HKQuantity.chip_asFHIRQuantityInUnit(HKUnit)` returns a FHIR _Quantity_ (or throws)
- `HKQuantityType.chip_preferredUnit()` returns the preferred HKUnit for the type

