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
	public var name: String {
		switch self {
		case .GeoLocationWhenUsing:
			return NSLocalizedString("Location Services", comment: "")
		case .GeoLocationAlways:
			return NSLocalizedString("Location Services", comment: "")
		case .LocalNotifications:
			return NSLocalizedString("Notifications", comment: "")
		case .CoreMotion:
			return NSLocalizedString("Motion Activity", comment: "")
		case .HealthKit:
			return NSLocalizedString("HealthKit", comment: "")
		case .Microphone:
			return NSLocalizedString("Microphone", comment: "")
		}
	}
	
	/// The description of what the service entails/why it's needed.
	public var description: String {
		switch self {
		case .GeoLocationWhenUsing(let reason):
			return reason
		case .GeoLocationAlways(let reason):
			return reason
		case .LocalNotifications:
			return NSLocalizedString("Enabling notifications allows the app to show reminders.", comment: "")
		case .CoreMotion:
			return NSLocalizedString("Using the motion co-processor allows the app to determine your activity, helping the study to better understand how activity level may influence disease.", comment: "")
		case .HealthKit:
			return NSLocalizedString("Individually specify which general health information the app may read from and write to HealthKit", comment: "")
		case .Microphone:
			return NSLocalizedString("Access to microphone is required for your Voice Recording Activity.", comment: "")
		}
	}
	
	public func localizedHowToReEnable() -> String {
		return ""
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

