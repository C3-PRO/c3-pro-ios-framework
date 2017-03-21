//
//  ProfilePersister.swift
//  C-Tracker-SCCS
//
//  Created by Pascal Pfiffner on 10.02.17.
//  Copyright © 2017 SCCS. All rights reserved.
//


/**
Types adopting this protocol are used to persist profile data on the device.
*/
public protocol ProfilePersister {
	
	// MARK: - User
	
	/** Load the enrolled user's data, if any. */
	func loadEnrolledUser(type: User.Type) throws -> User?
	
	/** Persist user properties. */
	func persist(user: User) throws
	
	/** Handle user withdrawal. */
	func userDidWithdraw(user: User?) throws
	
	
	// MARK: - Tasks
	
	/** Load all tasks for the user. */
	func loadAllTasks(for user: User?) throws -> [UserTask]
	
	/**
	Persist information about a specific task. It can be assumed that all other tasks should be left untouched.
	
	- parameter task: The task that has updated information
	*/
	func persist(task: UserTask) throws
	
	/**
	Persist a user task schedule. It can be assumed that the array contains **all** of the user's tasks.
	
	- parameter schedule: An array of all the user's tasks
	*/
	func persist(schedule: [UserTask]) throws
}

