//
//  SystemService.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 1/15/16.
//  Copyright © 2016 Boston Children's Hospital. All rights reserved.
//

import UIKit
import HealthKit


public enum SystemService: CustomStringConvertible {
	
	/// Access to the user's location while using the app. Must provide the reason why you want access.
	case GeoLocationWhenUsing(String)
	
	/// Access to the user's location even when in background. Must provide the reason why you want access here and set
	/// `NSLocationAlwaysUsageDescription` in Info.plist
	case GeoLocationAlways(String)
	
	/// Permission to deliver local notifications.
	case LocalNotifications(Set<UIUserNotificationCategory>)
	
//	case RemoteNotifications
	
	/// Permission to access CoreMotion data.
	case CoreMotion
	
	/// Permission to use HealthKit data. Provide `NSHealthShareUsageDescription` and/or `NSHealthUpdateUsageDescription` in Info.plist.
	case HealthKit(HealthKitTypes)
	
	/// Permission to access the device microphone.
	case Microphone
	
	
	// MARK: - Titles, Names and Strings
	
	/// The title or name of the service.
	public var description: String {
		switch self {
		case .GeoLocationWhenUsing:
			return "Location Services".c3_localized
		case .GeoLocationAlways:
			return "Location Services".c3_localized
		case .LocalNotifications:
			return "Notifications".c3_localized
		case .CoreMotion:
			return "Motion Activity".c3_localized
		case .HealthKit:
			return "HealthKit".c3_localized
		case .Microphone:
			return "Microphone".c3_localized
		}
	}
	
	/// The description of what the service entails/why it's needed.
	public var usageReason: String {
		switch self {
		case .GeoLocationWhenUsing(let reason):
			return reason
		case .GeoLocationAlways(let reason):
			return reason
		case .LocalNotifications:
			return "Enabling notifications allows the app to show reminders.".c3_localized
		case .CoreMotion:
			return "Using the motion co-processor allows the app to determine your activity, helping the study to better understand how activity level may influence disease.".c3_localized
		case .HealthKit:
			return "Individually specify which general health information the app may read from and write to HealthKit".c3_localized
		case .Microphone:
			return "Access to microphone is required for your Voice Recording Activity.".c3_localized
		}
	}
	
	/// Localized instructions telling how to re-enable the system service. Queries `CFBundleDisplayName` from the bundle's Info.plist to
	/// substitute the app name.
	public var localizedHowToReEnable: String {
		let appName = (NSBundle.mainBundle().infoDictionary?["CFBundleDisplayName"] as? String ?? NSBundle.mainBundle().infoDictionary?["CFBundleName"] as? String) ?? "App Name".c3_localized
		switch self {
		case .GeoLocationWhenUsing:
			return "Please go to the Settings app ➔ “\(appName)” ➔ “Location” to re-enable.".c3_localized
		case .GeoLocationAlways:
			return "Please go to the Settings app ➔ “\(appName)” ➔ “Location” to re-enable.".c3_localized
		case .LocalNotifications:
			return "Please go to the Settings app ➔ “\(appName)” ➔ “Notifications” and turn “Allow Notifications” on.".c3_localized
		case .CoreMotion:
			return "Please go to the Settings app ➔ “\(appName)” and turn “Motion & Fitness” on".c3_localized
		case .HealthKit:
			return "Please go to the Settings app ➔ “Privacy ”➔ “Health” ➔ \(appName) to re-enable.".c3_localized
		case .Microphone:
			return "Please go to the Settings app ➔ “\(appName)” and turn “Microphone” on".c3_localized
		}
	}
	
	/// Whether the settings can be managed from within the app's settings pane (not a top-level pane, such as “Privacy”)
	public var wantsAppSettingsPane: Bool {
		switch self {
		case .HealthKit:
			return false
		default:
			return true
		}
	}
}


public struct HealthKitTypes {
	
	public var characteristicTypesToRead = Set<HKCharacteristicType>()
	
	public var quantityTypesToRead = Set<HKQuantityType>()
	
	public var quantityTypesToWrite = Set<HKQuantityType>()
	
	public init(readCharacteristics: Set<HKCharacteristicType>, readQuantities: Set<HKQuantityType>, writeQuantities: Set<HKQuantityType>) {
		characteristicTypesToRead = readCharacteristics
		quantityTypesToRead = readQuantities
		quantityTypesToWrite = writeQuantities
	}
	
	
	public var isEmpty: Bool {
		return (0 == characteristicTypesToRead.count + quantityTypesToRead.count + quantityTypesToWrite.count)
	}
}

