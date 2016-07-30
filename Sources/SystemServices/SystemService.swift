//
//  SystemService.swift
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
import HealthKit


/**
Enum describing various system services such as geo-location, local notifications, CoreMotion and HealthKit.

The items have a `usageReason` attached to them which can be shown to users for explanation when requesting access. There's also a
`localizedHowToReEnable` string that instructs users on how to re-enable the respective service.
*/
public enum SystemService: CustomStringConvertible {
	
	/// Access to the user's location while using the app. Must provide the reason why you want access.
	case geoLocationWhenUsing(String)
	
	/// Access to the user's location even when in background. Must provide the reason why you want access here and set
	/// `NSLocationAlwaysUsageDescription` in Info.plist
	case geoLocationAlways(String)
	
	/// Permission to deliver local notifications.
	case localNotifications(Set<UIUserNotificationCategory>)
	
//	case RemoteNotifications
	
	/// Permission to access CoreMotion data.
	case coreMotion
	
	/// Permission to use HealthKit data. Provide `NSHealthShareUsageDescription` and/or `NSHealthUpdateUsageDescription` in Info.plist.
	case healthKit(HealthKitTypes)
	
	/// Permission to access the device microphone.
	case microphone
	
	
	// MARK: - Titles, Names and Strings
	
	/// The title or name of the service.
	public var description: String {
		switch self {
		case .geoLocationWhenUsing:
			return "Location Services".c3_localized
		case .geoLocationAlways:
			return "Location Services".c3_localized
		case .localNotifications:
			return "Notifications".c3_localized
		case .coreMotion:
			return "Motion Activity".c3_localized
		case .healthKit:
			return "HealthKit".c3_localized
		case .microphone:
			return "Microphone".c3_localized
		}
	}
	
	/// The description of what the service entails/why it's needed.
	public var usageReason: String {
		switch self {
		case .geoLocationWhenUsing(let reason):
			return reason
		case .geoLocationAlways(let reason):
			return reason
		case .localNotifications:
			return "Enabling notifications allows the app to show reminders.".c3_localized
		case .coreMotion:
			return "Using the motion co-processor allows the app to determine your activity, helping the study to better understand how activity level may influence disease.".c3_localized
		case .healthKit:
			return "Individually specify which general health information the app may read from and write to HealthKit".c3_localized
		case .microphone:
			return "Access to microphone is required for your Voice Recording Activity.".c3_localized
		}
	}
	
	/// Localized instructions telling how to re-enable the system service. Queries `CFBundleDisplayName` from the bundle's Info.plist to
	/// substitute the app name.
	public var localizedHowToReEnable: String {
		let appName = (Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? Bundle.main.infoDictionary?["CFBundleName"] as? String) ?? "App Name".c3_localized
		switch self {
		case .geoLocationWhenUsing:
			return "Please go to the Settings app ➔ “\(appName)” ➔ “Location” to re-enable.".c3_localized
		case .geoLocationAlways:
			return "Please go to the Settings app ➔ “\(appName)” ➔ “Location” to re-enable.".c3_localized
		case .localNotifications:
			return "Please go to the Settings app ➔ “\(appName)” ➔ “Notifications” and turn “Allow Notifications” on.".c3_localized
		case .coreMotion:
			return "Please go to the Settings app ➔ “\(appName)” and turn “Motion & Fitness” on".c3_localized
		case .healthKit:
			return "Please go to the Settings app ➔ “Privacy ”➔ “Health” ➔ \(appName) to re-enable.".c3_localized
		case .microphone:
			return "Please go to the Settings app ➔ “\(appName)” and turn “Microphone” on".c3_localized
		}
	}
	
	/// Whether the settings can be managed from within the app's settings pane (not a top-level pane, such as “Privacy”)
	public var wantsAppSettingsPane: Bool {
		switch self {
		case .healthKit:
			return false
		default:
			return true
		}
	}
}


/**
Allows to specify different types of data from HealthKit that wants to be read or written.
*/
public struct HealthKitTypes {
	
	/// HealthKit characteristics, such as gender and date of birth, to be read from HealthKit.
	public var characteristicTypesToRead = Set<HKCharacteristicType>()
	
	/// HealthKit quantities to be read.
	public var quantityTypesToRead = Set<HKQuantityType>()
	
	/// HealthKit quantities to be written.
	public var quantityTypesToWrite = Set<HKQuantityType>()
	
	/**
	Designated initializer.
	
	- parameter readCharacteristics: characteristics, such as gender and date of birth, to be read from HealthKit
	- parameter readQuantities: quantities to be read
	- parameter writeQuantities: quantities to be written
	*/
	public init(readCharacteristics: Set<HKCharacteristicType>, readQuantities: Set<HKQuantityType>, writeQuantities: Set<HKQuantityType>) {
		characteristicTypesToRead = readCharacteristics
		quantityTypesToRead = readQuantities
		quantityTypesToWrite = writeQuantities
	}
	
	
	/// Returns false if no type has been specified.
	public var isEmpty: Bool {
		return (0 == characteristicTypesToRead.count + quantityTypesToRead.count + quantityTypesToWrite.count)
	}
}

