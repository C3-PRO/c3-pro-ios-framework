//
//  Geocoder.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 7/20/15.
//  Copyright © 2015 Boston Children's Hospital. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import CoreLocation
import SMART


/** Callback called when geocoding finishes. Supplies `CLLocation`, if determined, or `Error`. */
public typealias GeocoderLocationCallback = ((CLLocation?, Error?) -> Void)

/** Callback called when geocoding finishes. Supplies `CLPlacemark`), if determined, or `Error`. */
public typealias GeocoderPlacemarkCallback = ((CLPlacemark?, Error?) -> Void)

/** Callback called when geocoding finishes. Supplies `SMART.Address`, if determined, or `Error`. */
public typealias GeocoderAddressCallback = ((Address?, Error?) -> Void)


/**
Class to ease geocoding tasks. Primarily designed to retrieve current location, e.g. to obtain a ZIP code.

If you use the geocoder you **must include** a short description of why you're accessing the user's location under the key
`NSLocationWhenInUseUsageDescription` in the app's Info.plist. Otherwise you will never receive the location callback. The user will see
this string in an alert window the first time the geocoder is used.

You probably want to use one of these methods for geocoding:

- `currentAddress()`:               Returning the current `Address`
- `hipaaCompliantCurrentAddress()`: Returning the current `Address` to HIPAA specs
- `geocodeCurrentLocation()`:       A `CLPlacemark` of the current location
- `currentLocation()`:              A `CLLocation` of the current location

For conversions from one thing to another:

- `hipaaCompliantAddress()`:   Make the given `Address` HIPAA-compliant
- `address(from:)`:            Convert `CLPlacemark` to `Address`
- `reverseGeocode(location:)`: Retrieve a `CLPlacemark` from `CLLocation`
*/
open class Geocoder {
	
	var locationManager: CLLocationManager?
	
	var locationDelegate: LocationManagerDelegate?
	
	var geocoder: CLGeocoder?
	
	var locationCallback: GeocoderLocationCallback?
	
	var isReverseGeocoding = false
	
	
	/** Designated initializer. */
	public init() {  }
	
	
	// MARK: - Location Manager
	
	func startManager(_ manager: CLLocationManager, isRetry: Bool = false) {
		if .notDetermined == CLLocationManager.authorizationStatus() {
			if !isRetry {
				locationManagerAuthorize(manager)
			}
			// else we let it run; this callback comes back before the user had a chance to read the alert
		}
		else {
			locationManagerStart(manager)
		}
	}
	
	func locationManagerAuthorize(_ manager: CLLocationManager) {
		c3_logIfDebug("Authorizing location determination")
		if let delegate = manager.delegate as? LocationManagerDelegate {
			delegate.didChangeAuthCallback = { status in
				if .notDetermined == status {
					c3_logIfDebug("Status is \"Not Determined\"; did you set `NSLocationWhenInUseUsageDescription` in your plist?")
				}
				self.startManager(manager, isRetry: true)
			}
		}
		manager.requestWhenInUseAuthorization()
	}
	
	/** Calls `startUpdatingLocation` and `stopUpdatingLocation`, then calls the callback with the current/latest location. */
	func locationManagerStart(_ manager: CLLocationManager) {
		c3_logIfDebug("Starting location determination")
		locationDelegate!.didUpdateLocations = { locations in
			self.locationManager?.stopUpdatingLocation()
			self.locationManagerDidReceiveLocations(locations)
		}
		locationManager!.startUpdatingLocation()
	}
	
	func locationManagerDidReceiveLocations(_ locations: [CLLocation]) {
		c3_logIfDebug("Location determination completed")
		locationCallback?(locations.last, nil)
		locationCallback = nil
		locationDelegate = nil
		locationManager = nil
	}
	
	func locationManagerDidFail(_ error: Error?) {
		c3_logIfDebug("Location determination failed with error: \(String(describing: error))")
		locationCallback?(nil, error)
		locationCallback = nil
		locationDelegate = nil
		locationManager = nil
	}
	
	/// A bool indicating whether the receiver is currently geocoding
	open var isGeocoding: Bool {
		return (nil != locationCallback) && !isReverseGeocoding
	}
	
	
	// MARK: - Geocoding
	
	/**
	Determines the current location and, on success, presents a "CLLocation" instance in the callback.
	
	- parameter callback: The callback to call after geocoding, supplies either a CLLocation instance, an error or neither (on abort)
	*/
	open func currentLocation(callback inCallback: @escaping GeocoderLocationCallback) {
		if let cb = locationCallback {
			cb(nil, nil)
			locationCallback = nil
		}
		
		// exit early if location services are disabled or denied/restricted
		if !CLLocationManager.locationServicesEnabled() || .denied == CLLocationManager.authorizationStatus() || .restricted == CLLocationManager.authorizationStatus() {
			inCallback(nil, C3Error.locationServicesDisabled)
			return
		}
		
		// setup and start location manager
		locationCallback = inCallback
		locationDelegate = LocationManagerDelegate()
		locationManager = CLLocationManager()
		locationManager!.delegate = locationDelegate
		locationManager!.desiredAccuracy = kCLLocationAccuracyKilometer
		
		startManager(locationManager!)
	}
	
	/**
	Determines and reverse-geocodes the phone's current location. Calls `currentLocation()`, then geocodes that location.
	
	- parameter callback: The callback to call when done, supplies either a CLPlacemark or an error or neither (on abort)
	*/
	open func geocodeCurrentLocation(callback: @escaping GeocoderPlacemarkCallback) {
		currentLocation() { location, error in
			if nil != error || nil == location {
				callback(nil, error)
			}
			else {
				self.reverseGeocode(location: location!, callback: callback)
			}
		}
	}
	
	/**
	Reverse geocodes the given location.
	
	- parameter location: The location to look up
	- parameter callback: The callback to call when done, supplies either a CLPlacemark or an error or neither (on abort)
	*/
	open func reverseGeocode(location: CLLocation, callback: @escaping GeocoderPlacemarkCallback) {
		c3_logIfDebug("Starting reverse geocoding")
		isReverseGeocoding = true
		geocoder = CLGeocoder()
		geocoder!.reverseGeocodeLocation(location) { placemarks, error in
			c3_logIfDebug("Reverse geocoding completed")
			self.isReverseGeocoding = false
			if nil != error || nil == placemarks {
				callback(nil, error)
			}
			else {
				callback(placemarks!.first, nil)
			}
		}
	}
	
	/**
	In the callback returns a FHIR "Address" instance of the current location, populated with country and state if possible. Calls
	`geocodeCurrentLocation()` to determine the current location, then reverse-geocodes that location/placemark.
	
	- parameter callback: The callback to call after geocoding, supplies either an Address element, an error or neither (on abort)
	*/
	open func currentAddress(callback: @escaping GeocoderAddressCallback) {
		geocodeCurrentLocation { placemark, error in
			if nil != error || nil == placemark {
				callback(nil, error)
			}
			else {
				callback(self.addressFrom(placemark: placemark!), nil)
			}
		}
	}
	
	/**
	Populate an "Address" element representing the given placemark, including country (ISO representation preferred), state and ZIP.
	
	- returns: A populated FHIR "Address" element
	*/
	open func addressFrom(placemark: CLPlacemark) -> Address {
		let address = Address()
		address.country = placemark.isoCountryCode?.fhir_string ?? placemark.country?.fhir_string
		if let state = placemark.administrativeArea?.fhir_string {
			address.state = state
		}
		if let city = placemark.locality?.fhir_string {
			address.city = city
		}
		if let zip = placemark.postalCode?.fhir_string {
			address.postalCode = zip
		}
		return address
	}
	
	
	// MARK: - HIPAA Compliant Geocoding
	
	/**
	In the callback returns a FHIR "Address" instance of the current location, populated according to HIPAA Safe Harbor guidelines. Calls
	`geocodeCurrentLocation()` to determine the current location, then reverse-geocodes and de-identifies that location/placemark.
	
	- parameter callback: The callback to call after geocoding, supplies either an Address element, an error or neither (on abort)
	*/
	open func hipaaCompliantCurrentAddress(callback: @escaping GeocoderAddressCallback) {
		currentAddress { address, error in
			if nil != error || nil == address {
				callback(nil, error)
			}
			else {
				callback(self.hipaaCompliantAddress(address!), nil)
			}
		}
	}
	
	/**
	In the callback returns a FHIR "Address" instance of the given location, populated according to HIPAA Safe Harbor guidelines.
	
	- parameter callback: The callback to call after geocoding, supplies either an Address element, an error or neither (on abort)
	*/
	open func hipaaCompliantAddress(from location: CLLocation, callback: @escaping GeocoderAddressCallback) {
		reverseGeocode(location: location) { placemark, error in
			if nil != error || nil == placemark {
				callback(nil, error)
			}
			else {
				callback(self.hipaaCompliantAddress(self.addressFrom(placemark: placemark!)), nil)
			}
		}
	}
	
	/**
	Populate an "Address" element representing the given placemark according to HIPAA's Safe Harbor guidelines. This means `Address` will
	contain the ISO country code, the first three digits of the ZIP if the country code is "US" (with exceptions, as defined in
	`restrictedThreeDigitZIPs()`) and the state.
	
	- returns: A sparsely populated FHIR "Address" element
	*/
	open func hipaaCompliantAddress(_ address: Address) -> Address {
		let hipaa = Address()
		hipaa.country = address.country
		
		// US: 3-digit ZIP
		if let us = address.country?.string, us.lowercased().hasPrefix("us") {
			if let fullZip = address.postalCode?.string, fullZip.count >= 3 {
				let zip = fullZip[fullZip.startIndex..<fullZip.index(fullZip.startIndex, offsetBy: 3)]
				hipaa.postalCode = FHIRString(Geocoder.restrictedThreeDigitZIPs().contains(zip) ? "000" : zip)
			}
			if let state = address.state {
				hipaa.state = state
			}
		}
		
		// other country: state but no ZIP
		else {
			hipaa.state = address.state
		}
		return hipaa
	}
	
	/**
	Returns an array of 3-digit US ZIP codes that **can not** be used in a HIPAA compliant fashion for reporting de-identified data.
	See: http://www.hhs.gov/ocr/privacy/hipaa/understanding/coveredentities/De-identification/guidance.html#zip
	*/
	open class func restrictedThreeDigitZIPs() -> [String] {
		return ["036", "059", "063", "102", "203", "556", "692", "790", "821", "823", "830", "831", "878", "879", "884", "890", "893"]
	}
}


/** Delegate to `Geocoder` implementing the `CLLocationManagerDelegate` delegate methods. */
class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
	
	var didChangeAuthCallback: ((_ status: CLAuthorizationStatus) -> Void)?
	
	var didUpdateLocations: ((_ locations: [CLLocation]) -> Void)?
	
	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		didChangeAuthCallback?(status)
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		didUpdateLocations?(locations)
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		didUpdateLocations?([])
	}
}

