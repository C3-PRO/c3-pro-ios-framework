//
//  ProfileManager.swift
//  C Tracker SCCS
//
//  Created by Pascal Pfiffner on 07.09.16.
//  Copyright © 2016 SCCS. All rights reserved.
//

import UIKit
import SMART
import HealthKit
import ResearchKit

let kProfileManagerSampleUserId = "0000-SAMPLE-NOT-REAL-DATA"


/**
The profile manager handles the app user, which usually is the user that consented to participating in the study.

Use an instance of this class to handle everything surrounding the profile of your study participant. This includes:

- enrolling a user
- holding on to an instance of the data server that should be used
- setting up a schedule
- handling user tasks
- withdrawing a user
*/
open class ProfileManager {
	
	public static let didChangeProfileNotification = Notification.Name("ProfileManagerDidChangeProfileNotification")
	
	public static let userDidWithdrawFromStudyNotification = Notification.Name("UserDidWithdrawFromStudyNotification")
	
	/// The user managed by the receiver.
	public internal(set) var user: User?
	
	/// The type implementing the `User` protocol to use.
	public let userType: User.Type
	
	/// The type implementing the `UserTask` protocol to use.
	public let taskType: UserTask.Type
	
	/// The profile persister taking care of persisting user, schedule and co.
	public internal(set) var persister: ProfilePersister?
	
	/// The data server to be used.
	public internal(set) var dataServer: Server?
	
	/// Internally used to hold on to a token server instance.
	public internal(set) var tokenServer: OAuth2Requestable?
	
	/// Settings to use for this study profile.
	public internal(set) var settings: ProfileManagerSettings?
	
	/// The task preparer that can be used to prepare user tasks.
	public var taskPreparer: UserTaskPreparer? {
		if let taskPreparer = _taskPreparer {
			return taskPreparer
		}
		guard let user = user, let server = dataServer else {
			return nil
		}
		_taskPreparer = UserTaskPreparer(user: user, server: server)
		return _taskPreparer
	}
	private var _taskPreparer: UserTaskPreparer?
	
	/// If set, the handler is notified when a user completes a task and does its thing.
	public var taskHandler: ProfileTaskHandler?
	
	/// Handles system permissioning.
	public var permissioner: SystemServicePermissioner {
		if nil == _permissioner {
			_permissioner = SystemServicePermissioner()
		}
		return _permissioner!
	}
	private var _permissioner: SystemServicePermissioner?
	
	
	/**
	Designated initializer.
	
	- parameter settingsURL: The local URL to the JSON settings file
	- parameter dataServer:  A handle to the FHIR server that should receive study data
	- parameter persister:   The instance to use to persist app data
	*/
	public init(userType: User.Type, taskType: UserTask.Type, settingsURL: URL, dataServer: Server?, persister: ProfilePersister?) throws {
		self.userType = userType
		self.taskType = taskType
		self.dataServer = dataServer
		self.persister = persister
		
		// load settings
		let data = try Data(contentsOf: settingsURL)
		let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
		settings = try ProfileManagerSettings(with: json)
		
		// load user and tasks
		if let usr = try persister?.loadEnrolledUser(type: userType) {
			user = usr
			if let tasks = try persister?.loadAllTasks(for: usr) {
				user!.tasks = tasks
			}
		}
		else if ORKPasscodeViewController.isPasscodeStoredInKeychain() {
			ORKPasscodeViewController.removePasscodeFromKeychain()      // just to be safe in case the user deleted the app while enrolled
		}
	}
	
	
	// MARK: - Enrollment & Withdrawal
	
	/**
	Assign the `user` property.
	
	- warning: Know what you do when assigning this manually!
	- parameter user: The `User` instance to use for the receiver
	*/
	open func take(user: User) {
		self.user = user
		self.user?.isSampleUser = (user.userId == kProfileManagerSampleUserId)
	}
	
	/**
	Enroll the given user profile:
	
	1. persist user data
	2. create the schedule
	3. prepare user tasks
	
	- parameter user: The User to enroll
	*/
	open func enroll(user: User) throws {
		take(user: user)
		user.didEnroll(on: Date())
		
		try persister?.persist(user: user)
		try setupSchedule()
		taskPreparer?.prepareDueTasks() { [weak self] in
			self?._taskPreparer = nil
		}
		NotificationCenter.default.post(name: type(of: self).didChangeProfileNotification, object: self)
	}
	
	/**
	Create a user from confirmed token data. Will also assign `userId` to a random UUID.
	
	- parameter link: The data in the JWT, presumably one that the user scanned
	- returns: Initialized User
	*/
	open func userFromLink(_ link: ProfileLink) -> User {
		var user = userType.init()
		user.userId = UUID().uuidString
		if let name = link.claimset["sub"] as? String, name.count > 0 {
			user.name = name
		}
		if let bday = link.claimset["birthdate"] as? String, bday.count > 0 {
			user.birthDate = FHIRDate(string: bday)?.nsDate
		}
		return user
	}
	
	/**
	Establish the link between the user and the JWT.
	
	- parameter user:     The User to which to link
	- parameter token:    The token data with which the user wants to be linked
	- parameter callback: The callback to call when enrolling has finished
	*/
	open func establishLink(between user: User, and link: ProfileLink, callback: @escaping ((Error?) -> Void)) {
		do {
			guard let dataURL = dataServer?.baseURL else {
				throw C3Error.serverNotConfigured
			}
			let req = try link.request(linking: user, dataEndpoint: dataURL)
			let srv = OAuth2Requestable(verbose: false)
			srv.perform(request: req) { res in
				if res.response.statusCode >= 400 {
					// 401: no JWT
					// 403: invalid JWT
					// 406: incorrect Authorization header or request body
					// 409: already linked
					callback(res.error ?? FHIRError.requestError(res.response.statusCode, res.response.statusString))
				}
				else {
					user.didLink(on: Date(), against: req.url!)
					callback(nil)
				}
				self.tokenServer = nil
			}
			tokenServer = srv
		}
		catch let error {
			callback(error)
			return
		}
	}
	
	/**
	Withdraw our user.
	
	This method trashes data stored about the user, the schedule, info about completed data, removes the PIN and cancels all notifications.
	*/
	open func withdraw() throws {
		if let user = user {
			try persister?.userDidWithdraw(user: user)
		}
		user = nil
		_taskPreparer = nil
		// TODO: notify IDM if `linked_at` is present?
		
		ORKPasscodeViewController.removePasscodeFromKeychain()
		NotificationManager.shared.cancelExistingNotifications(ofTypes: [], evenRescheduled: true)
		NotificationCenter.default.post(name: type(of: self).didChangeProfileNotification, object: self)
	}
	
	
	// MARK: - Tasks
	
	/**
	Reads the app's profile configuration, creates `UserTask` for every scheduled task and sets up app notifications.
	*/
	open func setupSchedule() throws {
		guard let user = user else {
			throw C3Error.noUserEnrolled
		}
		guard let schedulable = settings?.tasks else {
			NSLog("There are no settings or no tasks in the settings, not setting up the user's schedule")
			return
		}
		
		// setup complete schedule
		let now = Date()
		var scheduled = try schedulable.flatMap() { try $0.scheduledTasks(starting: now, type: taskType) }
		scheduled.sort {
			guard let ldue = $0.dueDate else {
				return false
			}
			guard let rdue = $1.dueDate else {
				return true
			}
			return ldue < rdue
		}
		try scheduled.forEach() { try user.add(task: $0) }
		
		// persist
		try persister?.persist(schedule: scheduled)
	}
	
	/**
	Prepares tasks, like attempting to download questionnaires.
	*/
	public func prepareDueTasks() {
		taskPreparer?.prepareDueTasks() { [weak self] in
			self?._taskPreparer = nil
		}
	}
	
	
	/**
	Create a notification suitable for the given task, influenced by the suggested date given.
	
	- returns: A tuple with the actual notification [0] and the notification type [1]
	*/
	open func notification(for task: UserTask, suggestedDate: DateComponents?) -> (UILocalNotification, NotificationManagerNotificationType)? {
		if task.completed {
			return nil
		}
		switch task.type {
		case .survey:
			if let dd = task.dueDate {
				var comps = Calendar.current.dateComponents([.year, .month, .day], from: dd)
				comps.hour = suggestedDate?.hour ?? 10
				comps.minute = suggestedDate?.minute ?? 0
				let date = Calendar.current.date(from: comps)
				
				let notification = UILocalNotification()
				notification.alertBody = "We'd like you to complete another survey".c3_localized
				notification.fireDate = date
				notification.timeZone = TimeZone.current
				notification.repeatInterval = NSCalendar.Unit.day
				notification.userInfo = [
					kUserTaskNotificationTaskIdKey: task.id
				]
				
				return (notification, NotificationManagerNotificationType.delayable)
			}
			return nil
		default:
			return nil
		}
	}
	
	public func userDidComplete(task: UserTask, on date: Date, context: Any?) throws {
		task.completed(on: date, with: context)
		try persister?.persist(task: task)
		
		// handle the task
		if let handler = taskHandler {
			handler.handle(task: task)
		}
		
		// send notification
		var userInfo = [String: Any]()
		if let user = user {
			userInfo[kUserTaskNotificationUserKey] = user
		}
		NotificationCenter.default.post(name: UserDidCompleteTaskNotification, object: task, userInfo: userInfo)
	}
	
	
	// MARK: - Service Permissions
	
	open var systemServicesNeeded: [SystemService] {
		return [
			.localNotifications(notificationCategories),
			.coreMotion,
			.healthKit(healthKitTypes),
		]
	}
	
	open var notificationCategories: Set<UIUserNotificationCategory> {
		let notificationTypes = [NotificationManagerNotificationType.none, .once, .delayable]
		return Set(notificationTypes.map() { $0.category() }.filter() { nil != $0 }.map() { $0!.userNotificationCategory })
	}
	
	open var healthKitTypes: HealthKitTypes {
		let hkCRead = Set<HKCharacteristicType>([
			HKCharacteristicType.characteristicType(forIdentifier: .biologicalSex)!,
			HKCharacteristicType.characteristicType(forIdentifier: .dateOfBirth)!,
			])
		let hkQRead = Set<HKQuantityType>([
			HKQuantityType.quantityType(forIdentifier: .height)!,
			HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
			HKQuantityType.quantityType(forIdentifier: .stepCount)!,
			HKQuantityType.quantityType(forIdentifier: .flightsClimbed)!,
			HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
			])
		return HealthKitTypes(readCharacteristics: hkCRead, readQuantities: hkQRead, writeQuantities: Set())
	}
	
	
	// MARK: - FHIR
	
	/** Returns a `Patient` resource from the given user with only user-id and birth-year (capped at 90). */
	open func anonPatientResource(for user: User) -> Patient {
		let patient = Patient()
		if let userId = user.userId {
			patient.id = userId.fhir_string
		}
		if var bday = user.birthDate?.fhir_asDate() {
			bday.day = nil
			bday.month = nil
			bday.year = max(bday.year, Calendar.current.component(.year, from: Date()) - 90)
			patient.birthDate = bday
		}
		return patient
	}
	
	/** Returns a `Patient` resource only containing one `identifier`, with `identifier.value` being the user-id and `identifier.system`
	the URL of the data server. */
	public func linkablePatientResource(for user: User) throws -> Patient {
		guard let userId = user.userId else {
			throw C3Error.userHasNoUserId
		}
		let patient = Patient()
		let ident = Identifier()
		ident.value = userId.fhir_string
		ident.system = dataServer?.baseURL.fhir_url
		patient.identifier = [ident]
		return patient
	}
	
	
	// MARK: - Trying the App
	
	open func sampleUser() -> User {
		let (token, secret) = type(of: self).sampleToken()
		let link = try! ProfileLink(token: token, using: secret)
		var user = userFromLink(link)
		user.userId = kProfileManagerSampleUserId
		return user
	}
	
	open class func sampleToken() -> (String, String) {
		let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJodHRwczovL2lkbS5jMy1wcm8uaW8vIiwiYXVkIjoiaHR0cHM6Ly9pZG0uYzMtcHJvLmlvLyIsImp0aSI6IjgyRjI3OTc5QTkzNiIsImV4cCI6IjE2NzM0OTcyODgiLCJzdWIiOiJQZXRlciBNw7xsbGVyIiwiYmlydGhkYXRlIjoiMTk3Ni0wNC0yOCJ9.ZwhX0_dVNsekm7N-tf4-m1y4P37GR7z4qOGtuWD_oNY"	// valid until Jan 2023
		let secret = "super-duper-secret"
		
		return (token, secret)
	}
}

