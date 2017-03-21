//
//  NotificationManager.swift
//  c3-pro
//
//  Created by Pascal Pfiffner on 7/17/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import UIKit


/**
The possible local notification types, possibly associated with a NotificationManagerNotificationCategory.
*/
public enum NotificationManagerNotificationType: String {
	case none = "none"
	case once = "once"
	case delayable = "delayable"
	
	func category() -> NotificationManagerNotificationCategory? {
		switch self {
		case .none:
			return nil
		case .once:
			return NotificationManagerNotificationCategory.once
		case .delayable:
			return NotificationManagerNotificationCategory.delay
		}
	}
}


/**
Categories possible for local notificatios. Categories may be associated with NotificationManagerNotificationAction-s.
*/
public enum NotificationManagerNotificationCategory: String {
	case once = "once"
	case delay = "delay"
	
	/** Returns a preconfigured `UIUserNotificationCategory`. */
	var userNotificationCategory: UIUserNotificationCategory {
		let category = UIMutableUserNotificationCategory()
		category.identifier = rawValue
		switch self {
		case .once:
			break
		case .delay:
			let actions = [
				NotificationManagerNotificationAction.delay1Hour.notificationAction,
				NotificationManagerNotificationAction.delay1Day.notificationAction,
			]
			category.setActions(actions, for: .minimal)
			category.setActions(actions, for: .default)
		}
		return category
	}
}


/**
Actions to be performed on local notifications.
*/
public enum NotificationManagerNotificationAction: String {
	case delay1Hour = "delay1hour"
	case delay1Day = "delay1day"
	
	/** Returns a preconfigured `UIUserNotificationAction`. */
	var notificationAction: UIUserNotificationAction {
		let action = UIMutableUserNotificationAction()
		action.identifier = rawValue
		action.activationMode = .background
		action.isDestructive = false
		action.isAuthenticationRequired = false
		switch self {
		case .delay1Hour:
			action.title = "Remind in 1 hour".c3_localized
		case .delay1Day:
			action.title = "Remind me tomorrow".c3_localized
		}
		return action
	}
	
	/** Applies itself to a given notification instance. */
	func apply(to notification: UILocalNotification) {
		switch self {
		case .delay1Hour:
			notification.fireDate = (notification.fireDate ?? Date()).addingTimeInterval(3600)
		case .delay1Day:
			if .day != notification.repeatInterval {
				let date = notification.fireDate ?? Date()		// fireDate is never nil, but let's not use force!
				var comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
				comps.day = (comps.day ?? 0) + 1
				notification.fireDate = Calendar.current.date(from: comps)
			}
		}
		
		// mark as rescheduled and reschedule
		var userInfo = notification.userInfo ?? [AnyHashable: Any]()
		userInfo[NotificationManager.notificationWasRescheduledKey] = true
		notification.userInfo = userInfo
		UIApplication.shared.scheduleLocalNotification(notification)
	}
}


/**
Singleton object that can schedule and cancel different local notifications.
*/
public class NotificationManager {
	
	public static let shared = NotificationManager()
	
	/// User info dictionary key that holds the type of the notification.
	public static let notificationTypeKey = Notification.Name(rawValue: "notificationType")
	
	/// User info dictionary key that holds a Bool on whether this particular notification was rescheduled.
	public static let notificationWasRescheduledKey = Notification.Name(rawValue: "wasRescheduled")

	/// Init is private, you must use the singleton using `shared`.
	private init() {}
	
	
	// MARK: - Managing Notifications
	
	/**
	Schedules the given notification according to the given type. If a notification's `fireDate` is in the past, displays the notification
	immediately.
	
	NOTE: You are responsible to have called `ensureProperNotificationSettings()` at some point before trying to schedule a notification.
	
	- parameter notification: The notification to schedule; MUST have `fireDate` unless .none is the type
	- parameter type:         The type of the notification
	*/
	public func schedule(_ notification: UILocalNotification, type: NotificationManagerNotificationType) {
		if .none == type {
			return
		}
		assert(nil != notification.fireDate)
		
		notification.timeZone = NSTimeZone.local
		notification.soundName = UILocalNotificationDefaultSoundName
		
		notification.userInfo = [
			NotificationManager.notificationTypeKey: type.rawValue,
		]
		if let category = type.category() {
			notification.category = category.rawValue
		}
		
		if let fireDate = notification.fireDate, fireDate < Date() {
			UIApplication.shared.presentLocalNotificationNow(notification)
		}
		else {
			UIApplication.shared.scheduleLocalNotification(notification)
		}
	}
	
	/**
	Should be called at app launch to ensure notifications are properly configured. Careful though, registering user notification settings
	will ask the user to permit sending local notifications. So maybe hold off until scheduling the first notification.
	*/
	public func ensureProperNotificationSettings() {
		let app = UIApplication.shared
		var settings = app.currentUserNotificationSettings
		let desired = type(of: self).userNotificationCategories()
		
		if nil == settings?.categories || !(settings!.categories!).isSuperset(of: desired) {
			let types: UIUserNotificationType = [.alert, .badge, .sound]
			settings = UIUserNotificationSettings(types: types, categories: desired)
			app.registerUserNotificationSettings(settings!)
		}
	}
	
	/**
	Cancels all existing notifications of the given types (or all if types is empty).
	
	- parameter ofTypes: An array of notification types to cancel; leave empty to cancel all notifications
	- parameter evenRescheduled: Also cancel notifications that have been rescheduled
	*/
	public func cancelExistingNotifications(ofTypes types: [NotificationManagerNotificationType], evenRescheduled: Bool = false) {
		let app = UIApplication.shared
		if let all = app.scheduledLocalNotifications {
			for existing in all {
				if let identifier = existing.userInfo?[NotificationManager.notificationTypeKey] as? String {
					if types.isEmpty || (types.map() { $0.rawValue }).contains(identifier) {
						if evenRescheduled || nil == existing.userInfo?[NotificationManager.notificationWasRescheduledKey] {
							app.cancelLocalNotification(existing)
						}
					}
				}
			}
		}
	}
	
	
	// MARK: - Notification Actions
	
	public func applyNotificationAction(_ action: NotificationManagerNotificationAction, toNotification notification: UILocalNotification) {
		action.apply(to: notification)
	}
	
	
	// MARK: - Notification Categories
	
	class func userNotificationCategories() -> Set<UIUserNotificationCategory> {
		var set = Set<UIUserNotificationCategory>()
		set.insert(NotificationManagerNotificationCategory.delay.userNotificationCategory)
		return set
	}
}

