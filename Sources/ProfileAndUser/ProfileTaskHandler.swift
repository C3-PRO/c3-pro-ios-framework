//
//  ProfileTaskHandler.swift
//  C-Tracker-SCCS
//
//  Created by Pascal Pfiffner on 15.03.17.
//  Copyright © 2017 SCCS. All rights reserved.
//

import Foundation


/**
Instances of this class can be used to perform specific actions when a user completes a task.
*/
public protocol ProfileTaskHandler {
	
	/// The manager this handler belongs to. You probably want to make this `unowned` to avoid circular references.
	var manager: ProfileManager { get }
	
	/** Common initializer. */
	init(manager: ProfileManager)
	
	/**
	Handle the task given. This method does not take a callback, you'll need to handle submission errors etc. on your own.
	
	- parameter task: The UserTask to handle, usually a task that has just been completed
	*/
	func handle(task: UserTask)
}

