//
//  Geocoder.swift
//  ResearchCHIP
//
//  Created by Pascal Pfiffner on 7/20/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import Foundation
import CoreLocation


public typealias GeocoderCallback = ((location: CLLocation?) -> Void)


/**
	Class to ease geocoding tasks. Primarily designed to retrieve current location, e.g. to obtain a ZIP code.
 */
public class Geocoder
{
	var manager: CLLocationManager?
	
	var delegate: GeocoderDelegate?
	
	var callback: GeocoderCallback?
	
	public init() {
		
	}
	
	
	// MARK: - Geocoding
	
	public func currentLocation(callback inCallback: GeocoderCallback) {
		if let cb = callback {
			cb(location: nil)
			callback = nil
		}
		
		if !CLLocationManager.locationServicesEnabled() || .Denied == CLLocationManager.authorizationStatus() || .Restricted == CLLocationManager.authorizationStatus() {
			inCallback(location: nil)
			return
		}
		
		callback = inCallback
		delegate = GeocoderDelegate()
		manager = CLLocationManager()
		manager!.delegate = delegate
		manager!.desiredAccuracy = kCLLocationAccuracyKilometer
		
		if .NotDetermined == CLLocationManager.authorizationStatus() {
			geocodeAuthorize()			// no need to wait for the callback, can start requesting location updates immediately
		}
		geocodeStart()
	}
	
	func geocodeAuthorize() {
		chip_logIfDebug("Authorizing geocoding")
		manager!.requestWhenInUseAuthorization()
	}
	
	/** Calls `startUpdatingLocation` and `stopUpdatingLocation`, then calls the callback with the current/latest location. */
	func geocodeStart() {
		chip_logIfDebug("Starting geocoding")
		delegate!.didUpdateLocations = { locations in
			self.manager?.stopUpdatingLocation()
			self.geocodeDidReceiveLocations(locations)
		}
		manager!.startUpdatingLocation()
	}
	
	func geocodeDidReceiveLocations(locations: [CLLocation]) {
		callback?(location: locations.last)
		callback = nil
		delegate = nil
		manager = nil
	}
}


class GeocoderDelegate: NSObject, CLLocationManagerDelegate
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

