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


public typealias GeocoderLocationCallback = ((location: CLLocation?, error: ErrorType?) -> Void)

public typealias GeocoderPlacemarkCallback = ((placemark: CLPlacemark?, error: ErrorType?) -> Void)

public typealias GeocoderAddressCallback = ((address: Address?, error: ErrorType?) -> Void)


/**
Class to ease geocoding tasks. Primarily designed to retrieve current location, e.g. to obtain a ZIP code.
*/
public class Geocoder {
	
	var locationManager: CLLocationManager?
	
	var locationDelegate: LocationManagerDelegate?
	
	var geocoder: CLGeocoder?
	
	var locationCallback: GeocoderLocationCallback?
	
	var isReverseGeocoding = false
	
	
	/** Designated initializer. */
	public init() {  }
	
	
	// MARK: - Location Manager
	
	/**
	Determines the current location and, on success, presents a "CLLocation" instance in the callback.
	
	- parameter callback: The callback to call after geocoding, supplies either a CLLocation instance, an error or neither (on abort)
	*/
	public func currentLocation(callback inCallback: GeocoderLocationCallback) {
		if let cb = locationCallback {
			cb(location: nil, error: nil)
			locationCallback = nil
		}
		
		// exit early if location services are disabled or denied/restricted
		if !CLLocationManager.locationServicesEnabled() || .Denied == CLLocationManager.authorizationStatus() || .Restricted == CLLocationManager.authorizationStatus() {
			inCallback(location: nil, error: C3Error.LocationServicesDisabled)
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
	
	func startManager(manager: CLLocationManager, isRetry: Bool = false) {
		if .NotDetermined == CLLocationManager.authorizationStatus() {
			if !isRetry {
				locationManagerAuthorize(manager)
			}
			// else we let it run; this callback comes back before the user had a chance to read the alert
		}
		else {
			locationManagerStart(manager)
		}
	}
	
	func locationManagerAuthorize(manager: CLLocationManager) {
		chip_logIfDebug("Authorizing location determination")
		if let delegate = manager.delegate as? LocationManagerDelegate {
			delegate.didChangeAuthCallback = { status in
				if .NotDetermined == status {
					chip_logIfDebug("Status is \"Not Determined\"; did you set `NSLocationWhenInUseUsageDescription` in your plist?")
				}
				self.startManager(manager, isRetry: true)
			}
		}
		manager.requestWhenInUseAuthorization()
	}
	
	/** Calls `startUpdatingLocation` and `stopUpdatingLocation`, then calls the callback with the current/latest location. */
	func locationManagerStart(manager: CLLocationManager) {
		chip_logIfDebug("Starting location determination")
		locationDelegate!.didUpdateLocations = { locations in
			self.locationManager?.stopUpdatingLocation()
			self.locationManagerDidReceiveLocations(locations)
		}
		locationManager!.startUpdatingLocation()
	}
	
	func locationManagerDidReceiveLocations(locations: [CLLocation]) {
		chip_logIfDebug("Location determination completed")
		locationCallback?(location: locations.last, error: nil)
		locationCallback = nil
		locationDelegate = nil
		locationManager = nil
	}
	
	func locationManagerDidFail(error: ErrorType?) {
		chip_logIfDebug("Location determination failed with error: \(error)")
		locationCallback?(location: nil, error: error)
		locationCallback = nil
		locationDelegate = nil
		locationManager = nil
	}
	
	/// A bool indicating whether the receiver is currently geocoding
	public var isGeocoding: Bool {
		return (nil != locationCallback) && !isReverseGeocoding
	}
	
	
	// MARK: - Geocoding
	
	/**
	Determines and reverse-geocodes the phone's current location. Calls `currentLocation()`, then geocodes that location.
	
	- parameter callback: The callback to call when done, supplies either a CLPlacemark or an error or neither (on abort)
	*/
	public func geocodeCurrentLocation(callback: GeocoderPlacemarkCallback) {
		currentLocation() { location, error in
			if nil != error || nil == location {
				callback(placemark: nil, error: error)
			}
			else {
				self.reverseGeocodeLocation(location!, callback: callback)
			}
		}
	}
	
	/**
	Reverse geocodes the given location.
	
	- parameter location: The location to look up
	- parameter callback: The callback to call when done, supplies either a CLPlacemark or an error or neither (on abort)
	*/
	public func reverseGeocodeLocation(location: CLLocation, callback: GeocoderPlacemarkCallback) {
		chip_logIfDebug("Starting reverse geocoding")
		isReverseGeocoding = true
		geocoder = CLGeocoder()
		geocoder!.reverseGeocodeLocation(location) { placemarks, error in
			chip_logIfDebug("Reverse geocoding completed")
			self.isReverseGeocoding = false
			if nil != error || nil == placemarks {
				callback(placemark: nil, error: error)
			}
			else {
				callback(placemark: placemarks!.first, error: nil)
			}
		}
	}
	
	/**
	In the callback returns a FHIR "Address" instance of the current location, populated with country and state if possible. Calls
	`geocodeCurrentLocation()` to determine the current location, then reverse-geocodes that location/placemark.
	
	- parameter callback: The callback to call after geocoding, supplies either an Address element, an error or neither (on abort)
	*/
	public func currentAddress(callback: GeocoderAddressCallback) {
		geocodeCurrentLocation { placemark, error in
			if nil != error || nil == placemark {
				callback(address: nil, error: error)
			}
			else {
				callback(address: self.addressFromPlacemark(placemark!), error: nil)
			}
		}
	}
	
	/**
	Populate an "Address" element representing the given placemark, including country (ISO representation preferred), state and ZIP.
	
	- returns: A populated FHIR "Address" element
	*/
	public func addressFromPlacemark(placemark: CLPlacemark) -> Address {
		let address = Address(json: nil)
		address.country = placemark.ISOcountryCode ?? placemark.country
		if let state = placemark.administrativeArea {
			address.state = state
		}
		if let city = placemark.locality {
			address.city = city
		}
		if let zip = placemark.postalCode {
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
	public func hipaaCompliantCurrentAddress(callback: GeocoderAddressCallback) {
		currentAddress { address, error in
			if nil != error || nil == address {
				callback(address: nil, error: error)
			}
			else {
				callback(address: self.hipaaCompliantAddress(address!), error: nil)
			}
		}
	}
	
	/**
	In the callback returns a FHIR "Address" instance of the given location, populated according to HIPAA Safe Harbor guidelines.
	
	- parameter callback: The callback to call after geocoding, supplies either an Address element, an error or neither (on abort)
	*/
	public func hipaaCompliantAddressFromLocation(location: CLLocation, callback: GeocoderAddressCallback) {
		reverseGeocodeLocation(location) { placemark, error in
			if nil != error || nil == placemark {
				callback(address: nil, error: error)
			}
			else {
				callback(address: self.hipaaCompliantAddress(self.addressFromPlacemark(placemark!)), error: nil)
			}
		}
	}
	
	/**
	Populate an "Address" element representing the given placemark according to HIPAA's Safe Harbor guidelines. This means `Address` will
	contain the ISO country code, the first three digits of the ZIP if the country code is "US" (with exceptions, as defined in
	`restrictedThreeDigitZIPs()`) and the state.
	
	- returns: A sparsely populated FHIR "Address" element
	*/
	func hipaaCompliantAddress(address: Address) -> Address {
		let hipaa = Address(json: nil)
		hipaa.country = address.country
		
		// US: 3-digit ZIP
		if let us = address.country where us.lowercaseString.hasPrefix("us") {
			if let fullZip = address.postalCode where fullZip.characters.count >= 3 {
				let zip = fullZip[fullZip.startIndex..<fullZip.startIndex.advancedBy(3)]
				hipaa.postalCode = Geocoder.restrictedThreeDigitZIPs().contains(zip) ? "000" : zip
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
	public class func restrictedThreeDigitZIPs() -> [String] {
		return ["036", "059", "063", "102", "203", "556", "692", "790", "821", "823", "830", "831", "878", "879", "884", "890", "893"]
	}
}


/** Delegate to `Geocoder` implementing the `CLLocationManagerDelegate` delegate methods. */
class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
	
	var didChangeAuthCallback: ((status: CLAuthorizationStatus) -> Void)?
	
	var didUpdateLocations: ((locations: [CLLocation]) -> Void)?
	
	func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
		didChangeAuthCallback?(status: status)
	}
	
	func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		didUpdateLocations?(locations: locations ?? [])
	}
	
	func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
		didUpdateLocations?(locations: [])
	}
}

