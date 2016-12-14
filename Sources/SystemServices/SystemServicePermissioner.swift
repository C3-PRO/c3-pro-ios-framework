//
//  SystemServicePermissioner.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 1/15/16.
//  Copyright © 2016 Boston Children's Hospital. All rights reserved.
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

import UIKit
import CoreLocation
import CoreMotion
import HealthKit
import AVFoundation


/**
A class to ask a user to grant access to different system-level services, such as CoreMotion, HealthKit and Notification delivery.

Works together with `SystemService`.
*/
open class SystemServicePermissioner {
	
	var locationManager: CLLocationManager?
	
	var locationDelegate: SystemRequesterGeoLocationDelegate?
	
	var coreMotionManager: CMMotionActivityManager?
	
	
	/** Designated initializer, takes no arguments. */
	public init() {
	}
	
	
	// MARK: - Permission Status
	
	/**
	Attempts to find out whether permission to the respective service has already been granted.
	
	- parameter service:  The SystemService to inquire for
	- parameter callback: A block to be executed when status has been determined; executed on the main queue
	*/
	open func hasPermission(for service: SystemService) -> Bool {
		switch service {
		case .geoLocationWhenUsing:
			return hasGeoLocationPermissions(always: false)
		case .geoLocationAlways:
			return hasGeoLocationPermissions(always: true)
			
		case .localNotifications(let categories):
			return hasLocalNotificationsPermissions(for: categories)
			
		case .coreMotion:
			return hasCoreMotionPermissions()
		case .healthKit(let types):
			return hasHealthKitPermissions(for: types)
			
		case .microphone:
			return hasMicrophonePermissions()
		}
	}
	
	public func hasGeoLocationPermissions(always: Bool) -> Bool {
		let status = CLLocationManager.authorizationStatus()
		return (.authorizedAlways == status || (!always && .authorizedWhenInUse == status))
	}
	
	public func hasLocalNotificationsPermissions(for categories: Set<UIUserNotificationCategory>) -> Bool {
		let settings = UIApplication.shared.currentUserNotificationSettings
		return ((settings?.types ?? UIUserNotificationType()) != UIUserNotificationType())
	}
	
	public func hasCoreMotionPermissions() -> Bool {
		return CMMotionActivityManager.isActivityAvailable()
	}
	
	/**
	Always returns false without inspecting HealthKit types.
	
	- parameter types: The types for which to have access (ignored for now)
	*/
	public func hasHealthKitPermissions(for types: HealthKitTypes) -> Bool {
		return false
	}
	
	public func hasMicrophonePermissions() -> Bool {
		return (AVAudioSession.sharedInstance().recordPermission() == AVAudioSessionRecordPermission.granted)
	}
	
	
	// MARK: - Requesting Permissions
	
	/**
	Requests permission to the specified system service, asynchronously.
	
	- parameter service:  The SystemService to request access to
	- parameter callback: A block to be executed when the request has been granted or denied; executed on the main queue
	*/
	open func requestPermission(for service: SystemService, callback: @escaping ((Error?) -> Void)) {
		switch service {
		case .geoLocationWhenUsing:
			requestGeoLocationPermissions(always: false, callback: callback)
		case .geoLocationAlways:
			requestGeoLocationPermissions(always: true, callback: callback)
		
		case .localNotifications(let categories):
			requestLocalNotificationsPermissions(for: categories, callback: callback)
		
		case .coreMotion:
			requestCoreMotionPermissions(callback: callback)
		case .healthKit(let types):
			requestHealthKitPermissions(for: types, callback: callback)
		
		case .microphone:
			requestMicrophonePermissions(callback: callback)
		}
	}
	
	/**
	Requests permissions to access geolocation information unless permission is already granted.
	
	- parameter always: Whether location access should always be granted, not just while using the app
	- parameter callback: A block to be executed when the request has been granted or denied; executed on the main queue
	*/
	func requestGeoLocationPermissions(always: Bool, callback: @escaping ((Error?) -> Void)) {
		let status = CLLocationManager.authorizationStatus()
		if .authorizedAlways == status || (!always && .authorizedWhenInUse == status) {
			c3_performOnMainQueue() {
				callback(nil)
			}
			return
		}
		if nil != locationManager {
			c3_warn("Location permission request is already ongoing, not requesting again")
			c3_performOnMainQueue() {
				callback(nil)
			}
			return
		}
		
		// instantiate manager and -delegate, then request appropriate permissions
		locationManager = CLLocationManager()
		locationDelegate = SystemRequesterGeoLocationDelegate(complete: { [weak self] error in
			self?.locationManager = nil
			self?.locationDelegate = nil
			c3_performOnMainQueue() {
				callback(error)
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
	
	func requestLocalNotificationsPermissions(for categories: Set<UIUserNotificationCategory>, callback: @escaping ((Error?) -> Void)) {
		let app = UIApplication.shared
		var settings = app.currentUserNotificationSettings
		
		if nil == settings?.categories || !(settings!.categories!).isSuperset(of: categories) {
			let types: UIUserNotificationType = [.alert, .badge, .sound]
			settings = UIUserNotificationSettings(types: types, categories: categories)
			app.registerUserNotificationSettings(settings!)
			// callbacks are only delivered to `application:didRegisterUserNotificationSettings:`. It is best to just assume it went
			// through and then, before scheduling a local notification, check permissions again.
		}
		c3_performOnMainQueue() {
			callback(nil)
		}
	}
	
	/**
	Requests permission to access CoreMotion data. Does that by querying activity from now to now and captures whether the
	CMErrorMotionActivityNotAuthorized error comes back or not.
	*/
	func requestCoreMotionPermissions(callback: @escaping ((Error?) -> Void)) {
		if nil != coreMotionManager {
			c3_warn("CoreMotion permission request is already ongoing, not requesting again")
			c3_performOnMainQueue() {
				callback(nil)
			}
			return
		}
		
		coreMotionManager = CMMotionActivityManager()
		coreMotionManager!.queryActivityStarting(from: Date(), to: Date(), to: OperationQueue()) { [weak self] activity, error in
			self?.coreMotionManager = nil
			c3_performOnMainQueue() {
				if let error = error, error._domain == CMErrorDomain && error._code == Int(CMErrorMotionActivityNotAuthorized.rawValue) {
					callback(error)
				}
				else {
					callback(nil)
				}
			}
		}
	}
	
	/**
	Requests permissions to read and share certain HealthKit data types.
	
	- parameter for:      The HealthKitTypes that want to be accessed
	- parameter callback: A callback - containing an error if something went wrong, nil otherwise - when authorization completes
	*/
	func requestHealthKitPermissions(for types: HealthKitTypes, callback: @escaping ((Error?) -> Void)) {
		guard HKHealthStore.isHealthDataAvailable() else {
			c3_performOnMainQueue() {
				callback(C3Error.healthKitNotAvailable)
			}
			return
		}
		let store = HKHealthStore()		// TODO: better to only have one store during the app's lifetime, fix it
		var readTypes = Set<HKObjectType>()
		readTypes = readTypes.union(types.characteristicTypesToRead as Set<HKObjectType>)
		readTypes = readTypes.union(types.quantityTypesToRead as Set<HKObjectType>)
		
		store.requestAuthorization(toShare: types.quantityTypesToWrite, read: readTypes) { success, error in
			c3_performOnMainQueue() {
				callback(error)
			}
		}
	}
	
	/**
	Requests permission to access the microphone.
	*/
	func requestMicrophonePermissions(callback: @escaping ((Error?) -> Void)) {
		AVAudioSession.sharedInstance().requestRecordPermission { success in
			c3_performOnMainQueue() {
				callback(success ? nil : C3Error.locationServicesDisabled)
			}
		}
	}
}


/**
Instances of this class are used as delegate when requesting access to CoreLocation data.
*/
class SystemRequesterGeoLocationDelegate: NSObject, CLLocationManagerDelegate {
	
	var didComplete: ((Error?) -> Void)
	
	init(complete: @escaping ((Error?) -> Void)) {
		didComplete = complete
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		manager.stopUpdatingLocation()
	}
	
	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		switch status {
		case .notDetermined:
			break
		case .authorizedAlways:
			manager.stopUpdatingLocation()
			didComplete(nil)
		case .authorizedWhenInUse:
			manager.stopUpdatingLocation()
			didComplete(nil)
		case .denied:
			manager.stopUpdatingLocation()
			didComplete(C3Error.locationServicesDisabled)
		case .restricted:
			manager.stopUpdatingLocation()
			didComplete(C3Error.locationServicesDisabled)
		}
	}
}

