//
//  UserTask.swift
//  c3-pro
//
//  Created by Pascal Pfiffner on 5/19/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


/// The type of the task.
public enum UserTaskType: String {
	case unknown = "unknown"
	case consent = "consent"
	case survey = "survey"
	
	public var localizedName: String {
		switch self {
		case .consent: return "Consent".c3_localized
		case .survey:  return "Survey".c3_localized
		default:       return "Unknown".c3_localized
		}
	}
}

public let UserDidReceiveTaskNotification = Notification.Name(rawValue: "UserDidReceiveTask")

public let UserDidCompleteTaskNotification = Notification.Name(rawValue: "UserDidCompleteTask")

/// The key for Notification user dictionaries where one finds the associated User instance.
public let kUserTaskNotificationUserKey = "user"

/// To be used in notification's `userInfo` dictionaries.
public let kUserTaskNotificationTaskIdKey = "user-task-id"



/**
A task a user needs to complete, such as consenting or taking a survey.
*/
public protocol UserTask {
	
	/// Unique identifier for the task instance, e.g. a UUID, as opposed to `taskId`.
	var id: String { get }
	
	/// An identifier for the task, e.g. "survey-1"; there can be multiple task instances for the same `taskId`.
	var taskId: String { get }
	
	/// The type of the task.
	var type: UserTaskType { get }
	
	/// The title of this task.
	var title: String? { get set }
	
	/// Which user this task is assigned to
	var assignedTo: User? { get set }
	
	/// The notification type of this task.
	var notificationType: NotificationManagerNotificationType? { get set }
	
	/// The day this task is due.
	var dueDate: Date? { get set }
	
	/// Whether this task is due and has neither been completed nor expired.
	var due: Bool { get }
	
	var humanDueDate: String? { get }
	
	/// The day this task has been completed.
	var completedDate: Date? { get set }
	
	/// The day this task has expired or will expire (also the max date to which the user can delay the task).
	var expiredDate: Date? { get set }
	
	/// Human-readable date this task has either been completed or has expired.
	var humanCompletedExpiredDate: String? { get }
	
	/// Whether this task is pending.
	var pending: Bool { get }
	
	/// Whether this task has been completed.
	var completed: Bool { get }
	
	/// Whether this task has expired.
	var expired: Bool { get }
	
	/// Whether this task can be reviewed.
	var canReview: Bool { get }
	
	/// The resource resulting from this task, if any.
	var resultResource: Resource? { get }
	
	
	init(id: String, taskId: String, type: UserTaskType)
	
	
	// MARK: - Creation & Completion
	
	/** Call this method to let the user know about the new task and emit a notification. Should emit "UserDidReceiveTaskNotification". */
	func add(to user: User) throws
	
	/** Call this method to mark a task complete. */
	func completed(on date: Date, with context: Any?)
	
	
	// MARK: - Serialization
	
	init(serialized: [String: Any]) throws
	
	func serialized() -> [String: Any]
	
	func serializedMinimal() -> [String: Any]
}


extension UserTask {
	
	static func ==(a: UserTask, b: UserTask) -> Bool {
		return a.id == b.id
	}
}

