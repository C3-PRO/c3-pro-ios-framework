//
//  User.swift
//  C-Tracker-SCCS
//
//  Created by Pascal Pfiffner on 11/28/16.
//  Copyright © 2016 SCCS. All rights reserved.
//

import Foundation
import HealthKit


public protocol User {
	
	var userId: String? { get set }
	
	var name: String? { get set }
	
	var birthDate: Date? { get set }
	
	var biologicalSex: HKBiologicalSex { get set }
	
	var bloodType: HKBloodType { get set }
	
	var ethnicity: String? { get set }
	
	var bodyheight: HKQuantity? { get set }
	
	var bodyweight: HKQuantity? { get set }
	
	var profileImage: Data? { get }
	
	/// Whether this user represents a test/sample user; use it to determine whether data should be sent to your server or not.
	var isSampleUser: Bool { get set }
	
	init()
	
	
	// MARK: - Enrollment
	
	var enrollmentDate: Date? { get set }
	
	func didEnroll(on date: Date)
	
	var linkedDate: Date? { get set }
	
	var linkedAgainst: URL? { get set }
	
	func didLink(on date: Date, against url: URL)
	
	
	// MARK: - Tasks
	
	var tasks: [UserTask] { get set }
	
	var tasksOutstanding: [UserTask] { get }
	
	var tasksPast: [UserTask] { get }
	
	func add(task: UserTask) throws
	
	
	// MARK: - Human Readable
	
	var humanSummary: String { get }
	
	var humanBirthday: String? { get }
	
	var humanSex: String { get }
	
	var humanHeight: String? { get }
	
	var humanWeight: String? { get }
}

// MARK: -


extension User {
	
	static func ==(a: User, b: User) -> Bool {
		return a.userId == b.userId
	}
}

