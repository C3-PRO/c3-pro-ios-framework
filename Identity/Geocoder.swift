//
//  Geocoder.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 7/20/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import Foundation
import CoreLocation
import SMART


public typealias GeocoderLocationCallback = ((location: CLLocation?, error: NSError?) -> Void)

public typealias GeocoderPlacemarkCallback = ((placemark: CLPlacemark?, error: NSError?) -> Void)

public typealias GeocoderAddressCallback = ((address: Address?, error: NSError?) -> Void)

let CHIPGeocoderErrorKey = "CHIPGeocoderError"


/**
	Class to ease geocoding tasks. Primarily designed to retrieve current location, e.g. to obtain a ZIP code.
 */
public class Geocoder
{
	var locationManager: CLLocationManager?
	
	var locationDelegate: LocationManagerDelegate?
	
	var geocoder: CLGeocoder?
	
	var locationCallback: GeocoderLocationCallback?
	
	public init() {  }
	
	
	// MARK: - Location Manager
	
	/**
	Determines the current location and, on success, presents a "CLLocation" instance in the callback.
	
	:param callback: The callback to call after geocoding, supplies either a CLLocation instance, an NSError instance or neither (on abort)
	*/
	public func currentLocation(callback inCallback: GeocoderLocationCallback) {
		if let cb = locationCallback {
			cb(location: nil, error: nil)
			locationCallback = nil
		}
		
		// exit early if location services are disabled or denied/restricted
		if !CLLocationManager.locationServicesEnabled() || .Denied == CLLocationManager.authorizationStatus() || .Restricted == CLLocationManager.authorizationStatus() {
			inCallback(location: nil, error: chip_genErrorGeocoder("Location services are disabled or have been restricted"))
			return
		}
		
		// setup and start location manager
		locationCallback = inCallback
		locationDelegate = LocationManagerDelegate()
		locationManager = CLLocationManager()
		locationManager!.delegate = locationDelegate
		locationManager!.desiredAccuracy = kCLLocationAccuracyKilometer
		
		if .NotDetermined == CLLocationManager.authorizationStatus() {
			locationManagerAuthorize()			// no need to wait for the callback, can start requesting location updates immediately
		}
		locationManagerStart()
	}
	
	func locationManagerAuthorize() {
		chip_logIfDebug("Authorizing location determination")
		locationManager!.requestWhenInUseAuthorization()
	}
	
	/** Calls `startUpdatingLocation` and `stopUpdatingLocation`, then calls the callback with the current/latest location. */
	func locationManagerStart() {
		chip_logIfDebug("Starting location determination")
		locationDelegate!.didUpdateLocations = { locations in
			self.locationManager?.stopUpdatingLocation()
			self.locationManagerDidReceiveLocations(locations)
		}
		locationManager!.startUpdatingLocation()
	}
	
	func locationManagerDidReceiveLocations(locations: [CLLocation]) {
		locationCallback?(location: locations.last, error: nil)
		locationCallback = nil
		locationDelegate = nil
		locationManager = nil
	}
	
	
	// MARK: - Geocoding
	
	/**
	In the callback returns a FHIR "Address" instance of the current location, populated according to HIPAA Safe Harbor guidelines. Calls
	`geocodeCurrentLocation()` to determine the current location, then reverse-geocodes and de-identifies that location/placemark.
	
	:param callback: The callback to call after geocoding, supplies either an Address element, an NSError instance or neither (on abort)
	*/
	public func hipaaCompliantCurrentLocation(callback: GeocoderAddressCallback) {
		geocodeCurrentLocation { placemark, error in
			if nil != error || nil == placemark {
				callback(address: nil, error: error)
			}
			else {
				callback(address: self.hipaaCompliantAddressFromPlacemark(placemark!), error: nil)
			}
		}
	}
	
	/**
	In the callback returns a FHIR "Address" instance of the given location, populated according to HIPAA Safe Harbor guidelines.
	
	:param callback: The callback to call after geocoding, supplies either an Address element, an NSError instance or neither (on abort)
	*/
	public func hipaaCompliantLocation(location: CLLocation, callback: GeocoderAddressCallback) {
		geocodeLocation(location) { placemark, error in
			if nil != error || nil == placemark {
				callback(address: nil, error: error)
			}
			else {
				callback(address: self.hipaaCompliantAddressFromPlacemark(placemark!), error: nil)
			}
		}
	}
	
	/**
	Populate an "Address" element representing the given placemark according to HIPAA's Safe Harbor guidelines.
	
	:returns: A sparsely populated FHIR "Address" element
	*/
	func hipaaCompliantAddressFromPlacemark(placemark: CLPlacemark) -> Address {
		let hipaa = Address(json: nil)
		hipaa.country = placemark.country
		
		// US: 3-digit ZIP
		if "US" == placemark.ISOcountryCode {
			if let fullZip = placemark.postalCode where count(fullZip) >= 3 {
				let zip = fullZip[fullZip.startIndex..<advance(fullZip.startIndex, 3)]
				hipaa.postalCode = contains(Geocoder.restrictedThreeDigitZIPs(), zip) ? "000" : zip
			}
			if let state = placemark.administrativeArea {
				hipaa.state = state
			}
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
	
	/**
	Determines and reverse-geocodes the phone's current location. Calls `currentLocation()`, then geocodes that location.
	
	:param callback: The callback to call when done, supplies either a CLPlacemark or an NSError or neither (on abort)
	*/
	public func geocodeCurrentLocation(callback: GeocoderPlacemarkCallback) {
		currentLocation() { location, error in
			if nil != error || nil == location {
				callback(placemark: nil, error: error)
			}
			else {
				self.geocodeLocation(location!, callback: callback)
			}
		}
	}
	
	/**
	Reverse geocodes the given location.
	
	:param location: The location to look up
	:param callback: The callback to call when done, supplies either a CLPlacemark or an NSError or neither (on abort)
	*/
	public func geocodeLocation(location: CLLocation, callback: GeocoderPlacemarkCallback) {
		chip_logIfDebug("Starting reverse geocoding")
		geocoder = CLGeocoder()
		geocoder!.reverseGeocodeLocation(location) { placemarks, error in
			if nil != error || nil == placemarks {
				callback(placemark: nil, error: error)
			}
			else {
				callback(placemark: placemarks!.first as? CLPlacemark, error: nil)
			}
		}
	}
}


class LocationManagerDelegate: NSObject, CLLocationManagerDelegate
{
	var didChangeAuthCallback: ((status: CLAuthorizationStatus) -> Void)?
	
	var didUpdateLocations: ((locations: [CLLocation]) -> Void)?
	
	func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
		didChangeAuthCallback?(status: status)
	}
	
	func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
		didUpdateLocations?(locations: locations as? [CLLocation] ?? [])
	}
	
	func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
		didUpdateLocations?(locations: [])
	}
}


/**
	Convenience function to create an NSError in the Geocoder error domain.
 */
public func chip_genErrorGeocoder(message: String, code: Int = 0) -> NSError {
	return NSError(domain: CHIPGeocoderErrorKey, code: code, userInfo: [NSLocalizedDescriptionKey: message])
}

