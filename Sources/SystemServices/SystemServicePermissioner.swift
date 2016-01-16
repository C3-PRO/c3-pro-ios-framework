//
//  SystemServicePermissioner.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 1/15/16.
//  Copyright © 2016 Boston Children's Hospital. All rights reserved.
//

import UIKit
import CoreLocation
import CoreMotion
import HealthKit
import AVFoundation


/**
A class to ask a user to grant access to different system-level services, such as CoreMotion, HealthKit and Notification delivery.

Works together with `SystemService`.
*/
public class SystemServicePermissioner {
	
	var locationManager: CLLocationManager?
	
	var locationDelegate: SystemRequesterGeoLocationDelegate?
	
	var coreMotionManager: CMMotionActivityManager?
	
	/// If CoreMotion access was previously requested, this will hold the result.
	var coreMotionPermitted: Bool?
	
	
	// MARK: - Permission Status
	
	/**
	Attempts to find out whether permission to the respective service has already been granted.
	
	- parameter service: The SystemService to inquire for
	- parameter callback: A block to be executed when status has been determined; executed on the main queue
	*/
	public func hasPermissionForService(service: SystemService) -> Bool {
		switch service {
		case .GeoLocationWhenUsing:
			return hasGeoLocationPermissions(false)
		case .GeoLocationAlways:
			return hasGeoLocationPermissions(true)
			
		case .LocalNotifications(let categories):
			return hasLocalNotificationsPermissions(categories)
			
		case .CoreMotion:
			return hasCoreMotionPermissions()
		case .HealthKit(let types):
			return hasHealthKitPermissions(types)
			
		case .Microphone:
			return hasMicrophonePermissions()
		}
	}
	
	func hasGeoLocationPermissions(always: Bool) -> Bool {
		let status = CLLocationManager.authorizationStatus()
		return (.AuthorizedAlways == status || (!always && .AuthorizedWhenInUse == status))
	}
	
	func hasLocalNotificationsPermissions(categories: Set<UIUserNotificationCategory>) -> Bool {
		let settings = UIApplication.sharedApplication().currentUserNotificationSettings()
		return ((settings?.types ?? UIUserNotificationType.None) != UIUserNotificationType.None)
	}
	
	/**
	Has no way to query current CoreMotion permissions without prompting the user, hence will only return true if it has previously
	requested permission which was granted.
	*/
	func hasCoreMotionPermissions() -> Bool {
		return coreMotionPermitted ?? false
	}
	
	/**
	Always returns false without inspecting HealthKit types.
	*/
	func hasHealthKitPermissions(types: HealthKitTypes) -> Bool {
		return false
	}
	
	func hasMicrophonePermissions() -> Bool {
		return (AVAudioSession.sharedInstance().recordPermission() == AVAudioSessionRecordPermission.Granted)
	}
	
	
	// MARK: - Requesting Permissions
	
	/**
	Requests permission to the specified system service, asynchronously.
	
	- parameter service: The SystemService to request access to
	- parameter callback: A block to be executed when the request has been granted or denied; executed on the main queue
	*/
	public func requestPermissionForService(service: SystemService, callback: ((error: ErrorType?) -> Void)) {
		switch service {
		case .GeoLocationWhenUsing:
			requestGeoLocationPermissions(false, callback: callback)
		case .GeoLocationAlways:
			requestGeoLocationPermissions(true, callback: callback)
		
		case .LocalNotifications(let categories):
			requestLocalNotificationsPermissions(categories, callback: callback)
		
		case .CoreMotion:
			requestCoreMotionPermissions(callback)
		case .HealthKit(let types):
			requestHealthKitPermissions(types, callback: callback)
		
		case .Microphone:
			requestMicrophonePermissions(callback)
		}
	}
	
	/**
	Requests permissions to access geolocation information unless permission is already granted.
	
	- parameter always: Whether location access should always be granted, not just while using the app
	- parameter callback: A block to be executed when the request has been granted or denied; executed on the main queue
	*/
	func requestGeoLocationPermissions(always: Bool, callback: ((error: ErrorType?) -> Void)) {
		let status = CLLocationManager.authorizationStatus()
		if .AuthorizedAlways == status || (!always && .AuthorizedWhenInUse == status) {
			c3_performOnMainQueue() {
				callback(error: nil)
			}
			return
		}
		if nil != locationManager {
			chip_warn("Location permission request is already ongoing, not requesting again")
			c3_performOnMainQueue() {
				callback(error: nil)
			}
			return
		}
		
		// instantiate manager and -delegate, then request appropriate permissions
		locationManager = CLLocationManager()
		locationDelegate = SystemRequesterGeoLocationDelegate(complete: { [weak self] error in
			self?.locationManager = nil
			self?.locationDelegate = nil
			c3_performOnMainQueue() {
				callback(error: error)
			}
		})
		locationManager!.delegate = locationDelegate!
		if always {
			locationManager!.requestAlwaysAuthorization()
		}
		else {
			locationManager!.requestWhenInUseAuthorization()
		}
	}
	
	func requestLocalNotificationsPermissions(categories: Set<UIUserNotificationCategory>, callback: ((error: ErrorType?) -> Void)) {
		let app = UIApplication.sharedApplication()
		var settings = app.currentUserNotificationSettings()
		
		if nil == settings?.categories || !(settings!.categories!).isSupersetOf(categories) {
			let types: UIUserNotificationType = [.Alert, .Badge, .Sound]
			settings = UIUserNotificationSettings(forTypes: types, categories: categories)
			app.registerUserNotificationSettings(settings!)
			// callbacks are only delivered to `application:didRegisterUserNotificationSettings:`. It is best to just assume it went
			// through and then, before scheduling a local notification, check permissions again.
		}
		c3_performOnMainQueue() {
			callback(error: nil)
		}
	}
	
	/**
	Requests permission to access CoreMotion data. Does that by querying activity from now to now and captures whether the
	CMErrorMotionActivityNotAuthorized error comes back or not.
	*/
	func requestCoreMotionPermissions(callback: ((error: ErrorType?) -> Void)) {
		if nil != coreMotionManager {
			chip_warn("CoreMotion permission request is already ongoing, not requesting again")
			c3_performOnMainQueue() {
				callback(error: nil)
			}
			return
		}
		
		coreMotionManager = CMMotionActivityManager()
		coreMotionManager!.queryActivityStartingFromDate(NSDate(), toDate: NSDate(), toQueue: NSOperationQueue()) { [weak self] activity, error in
			self?.coreMotionManager = nil
			c3_performOnMainQueue() {
				if let error = error where error.domain == CMErrorDomain && error.code == Int(CMErrorMotionActivityNotAuthorized.rawValue) {
					self?.coreMotionPermitted = false
					callback(error: error)
				}
				else {
					self?.coreMotionPermitted = true
					callback(error: nil)
				}
			}
		}
	}
	
	/**
	Requests permissions to read and share certain HealthKit data types.
	
	- parameter types: The HealthKitTypes that want to be accessed
	- parameter callback: A callback - containing an error if something went wrong, nil otherwise - when authorization completes
	*/
	func requestHealthKitPermissions(types: HealthKitTypes, callback: ((error: ErrorType?) -> Void)) {
		guard HKHealthStore.isHealthDataAvailable() else {
			c3_performOnMainQueue() {
				callback(error: C3Error.HealthKitNotAvailable)
			}
			return
		}
		let store = HKHealthStore()		// TODO: better to only have one store during the app's lifetime, fix it
		var readTypes = Set<HKObjectType>()
		readTypes = readTypes.union(types.characteristicTypesToRead as Set<HKObjectType>)
		readTypes = readTypes.union(types.quantityTypesToRead as Set<HKObjectType>)
		
		store.requestAuthorizationToShareTypes(types.quantityTypesToWrite, readTypes: readTypes) { success, error in
			c3_performOnMainQueue() {
				callback(error: error)
			}
		}
	}
	
	/**
	Requests permission to access the microphone.
	*/
	func requestMicrophonePermissions(callback: ((error: ErrorType?) -> Void)) {
		AVAudioSession.sharedInstance().requestRecordPermission { success in
			c3_performOnMainQueue() {
				callback(error: success ? nil : C3Error.LocationServicesDisabled)
			}
		}
	}
}


/**
Instances of this class are used as delegate when requesting access to CoreLocation data.
*/
class SystemRequesterGeoLocationDelegate: NSObject, CLLocationManagerDelegate {
	
	var didComplete: ((error: ErrorType?) -> Void)
	
	init(complete: ((error: ErrorType?) -> Void)) {
		didComplete = complete
	}
	
	func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
		manager.stopUpdatingLocation()
	}
	
	func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
		switch status {
		case .NotDetermined:
			break
		case .AuthorizedAlways:
			manager.stopUpdatingLocation()
			didComplete(error: nil)
		case .AuthorizedWhenInUse:
			manager.stopUpdatingLocation()
			didComplete(error: nil)
		case .Denied:
			manager.stopUpdatingLocation()
			didComplete(error: C3Error.LocationServicesDisabled)
		case .Restricted:
			manager.stopUpdatingLocation()
			didComplete(error: C3Error.LocationServicesDisabled)
		}
	}
}

