//
//  UserTaskPreparer.swift
//  c3-pro
//
//  Created by Pascal Pfiffner on 8/12/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


/**
Instances of this class can be used to perform preparations for tasks, such as downloading and caching questionnaires.

While you can have multiple instances of this class, only one at a time may be actively preparing all tasks (this is taken care of
internally).
*/
open class UserTaskPreparer {
	
	static var preparingDueTasks = false
	
	let user: User
	
	let server: FHIRServer?
	
	public init(user: User, server: FHIRServer? = nil) {
		self.user = user
		self.server = server
	}
	
	
	// MARK: - Task Checking
	
	open func prepareDueTasks(_ callback: ((Void) -> Void)? = nil) {
		if type(of: self).preparingDueTasks {
			c3_logIfDebug("Already preparing tasks, skipping this run")
			return
		}
		
		// prepare all due tasks
		c3_logIfDebug("Preparing tasks")
		let group = DispatchGroup()
		type(of: self).preparingDueTasks = true
		for task in user.tasks {
			if task.due {
				group.enter()
				prepare(task: task) {
					group.leave()
				}
			}
		}
		
		// all preparations done
		group.notify(queue: DispatchQueue.main) {
			c3_logIfDebug("Done preparing tasks")
			type(of: self).preparingDueTasks = false
			callback?()
		}
	}
	
	/**
	Performs preparation actions for the given task, such as downloading and caching a questionnaire.
	
	- paramater task:     The task to prepare for
	- parameter callback: Block to execute when preparation has finished
	*/
	open func prepare(task: UserTask, callback: @escaping ((Void) -> Void)) {
		c3_logIfDebug("Preparing task \(task.id)")
		switch task.type {
		case .survey:
			prepareSurveyTask(task, callback: callback)
		default:
			break
		}
	}
	
	/**
	For survey-type tasks, creates a URL in cache directory and, if the questionnaire hasn't been cached yet, caches the questionnaire
	resource after reading it from the receiver's server.
	
	- parameter task:     The task that wants a survey completed
	- parameter callback: Block to execute when preparation has finished
	*/
	open func prepareSurveyTask(_ task: UserTask, callback: @escaping ((Void) -> Void)) {
		guard .survey == task.type else {
			c3_logIfDebug("Not attempting to cache non-survey task \(task)")
			return
		}
		
		if let url = cacheURL(for: task) {
			let fm = FileManager()
			
			// check if a newly updated app may provide a newer questionnaire than was cached
			if bundleResourceIsNewerThanResource(at: url, for: task) {
				do {
					try fm.removeItem(atPath: url.path)
				} catch _ {  }
			}
			
			// not cached yet, cache
			if !fm.fileExists(atPath: url.path) {
				c3_logIfDebug("Haven't cached Questionnaire yet, trying to read from server. Will cache to \(url)")
				prepareResource(for: task) { resource, error in
					if let error = error {
						c3_logIfDebug("Failed to prepare survey task: \(error)")
					}
					callback()
				}
				return
			}
			c3_logIfDebug("Questionnaire already cached at \(url)")
		}
		callback()
	}
	
	/**
	Prepare a FHIR resource for the given task.
	
	This implementation only knows how to handle `.survey` type tasks by downloading the respective `Questionnaire` resource from the
	server.
	*/
	open func prepareResource(for task: UserTask, callback: @escaping ((Resource?, Error?) -> Void)) {
		switch task.type {
		case .survey:
			guard let server = server else {
				c3_logIfDebug("No server is configured, looking for Questionnaire in app bundle")
				do {
					let res = try Bundle.main.fhir_bundledResource(task.taskId, type: Questionnaire.self)
					callback(res, nil)
				}
				catch let error {
					callback(nil, error)
				}
				return
			}
			
			c3_logIfDebug("Retrieving Questionnaire from \(server)")
			Questionnaire.read(task.id, server: server) { resource, error in
				DispatchQueue.main.async {
					var err: Error?
					var res = resource
					if let error = error {
						c3_logIfDebug("Failed to read Questionnaire from server, falling back to app bundle. Error was: \(error)")
						do {
							res = try Bundle.main.fhir_bundledResource(task.id, type: Questionnaire.self)
						}
						catch let bundleError {
							err = bundleError
						}
					}
					if nil == res || !(res! is Questionnaire) {
						res = nil
					}
					callback(res, err)
				}
			}
		default:
			c3_logIfDebug("Don't know how to prepare a resource for task \(task)")
			callback(nil, nil)
		}
	}
	
	
	// MARK: - Caching & Bundling
	
	func cacheURL(for task: UserTask) -> URL? {
		if let first = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first {
			let file = (.survey == task.type) ? "SurveyTask-\(task.id).json" : "Task-\(task.id).json"
			return URL(fileURLWithPath: first).appendingPathComponent(file)
		}
		return nil
	}
	
	/**
	You can use this method to determine whether a resource, bundled with the app, is newer than a given resource cached at the given
	filesystem URL.
	*/
	public func bundleResourceIsNewerThanResource(at url: URL, for task: UserTask) -> Bool {
		if let bundled = Bundle.main.path(forResource: task.id, ofType: "json") {
			let fm = FileManager()
			if let dateBundled = (try? fm.attributesOfItem(atPath: bundled))?[FileAttributeKey.creationDate] as? Date,
				let dateCached = (try? fm.attributesOfItem(atPath: url.path))?[FileAttributeKey.creationDate] as? Date {
				
				return dateBundled > dateCached
			}
		}
		return false
	}
}

