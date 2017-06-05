//
//  UserActivityTaskHandler.swift
//  C-Tracker-SCCS
//
//  Created by Pascal Pfiffner on 15.03.17.
//  Copyright © 2017 SCCS. All rights reserved.
//

import Foundation
import SMART


/**
This handler submits the following resources to the profile manager's data server if a survey task is completed, after referencing an
"anonymous" Patient to the resource's subjects (see `ProfileManager.anonPatientResource`):

1. a QuestionnaireResponse resources that come out of a survey task
2. pulls latest bio data from the manager's user and creates Observation resources
3. samples activity of the latest `ProfileManager.settings.activitySampleNumDays` days and creates a QuestionnaireResponse with that data,
   if more than 0 days are specified
*/
open class UserActivityTaskHandler: ProfileTaskHandler {
	
	/// The manager this handler belongs to.
	public unowned let manager: ProfileManager
	
	/// Where on the local filesystem the Core Motion reporter is storing data; only need to set if it's relevant to the manager, i.e. if
	/// it is supposed to automatically sample and submit activity data with questionnaires.
	public var motionReporterStore: URL?
	
	/// The custom core motion interpreter, if the default one is not desired.
	public var coreMotionInterpreter: CoreMotionActivityInterpreter?
	
	
	public required init(manager: ProfileManager) {
		self.manager = manager
	}
	
	open func handle(task: UserTask) {
		guard let user = manager.user else {
			c3_warn("The profile manager does not have a user, cannot handle task")
			return
		}
		if user.isSampleUser {
			c3_logIfDebug("This is a sample user, not submitting any task data")
			return
		}
		
		// survey completed: submit, submit current user data, sample activity data and submit as well
		if .survey == task.type {
			submitResult(of: task, for: user)
			submitLatestSubjectData(for: user)
			sampleAndSubmitLatestActivityData(for: user)
		}
	}
	
	
	// MARK: - Submit Task Data
	
	func submitResult(of task: UserTask, for user: User) {
		c3_logIfDebug("Task completed, submitting")
		guard let server = manager.dataServer else {
			c3_warn("Task completed but no dataServer set on profileManager")
			return
		}
		guard let resource = task.resultResource as? QuestionnaireResponse else {
			c3_warn("Task completed but no questionnaire response resource received, have this: \(task.resultResource?.description ?? "nil")")
			return
		}
		
		do {
			resource.subject = try manager.anonPatientResource(for: user).asRelativeReference()
		}
		catch {
			c3_warn("Failed to reference resource subject: \(error)")
		}
		resource.create(server) { error in
			if let error = error {
				c3_warn("Failed to submit questionnaire response resource: \(error)")
			}
		}
		#if DEBUG
		debugPrint(resource)
		#endif
	}
	
	
	// MARK: - Health Data
	
	func submitLatestSubjectData(for user: User) {
		guard let server = manager.dataServer else {
			c3_logIfDebug("No data server is set, cannot submit latest subject observations")
			return
		}
		let (_, observationsTuple) = user.c3_asPatientAndObservations()
		guard let observations = observationsTuple, observations.count > 0 else {
			c3_logIfDebug("No observations from user \(user), nothing to submit")
			return
		}
		for observation in observations {
			observation.create(server) { error in
				if let error = error {
					c3_logIfDebug("Failed to send subject observation: \(error)")
				}
			}
			
			#if DEBUG
			debugPrint(observation)
			#endif
		}
	}
	
	
	// MARK: - Activity Data
	
	var activityCollector: ActivityCollector?
	
	func sampleAndSubmitLatestActivityData(for user: User) {
		guard let path = motionReporterStore?.path else {
			return
		}
		guard nil == activityCollector else {
			c3_logIfDebug("Already collecting activity, skipping")
			return
		}
		
		let days = manager.settings?.activitySampleNumDays ?? 0
		guard days > 0 else {
			return
		}
		guard let server = manager.dataServer else {
			c3_logIfDebug("The profile manager does not have a data server")
			return
		}
		
		var reference: Reference?
		do {
			reference = try manager.anonPatientResource(for: user).asRelativeReference()
		}
		catch {
			c3_warn("Failed to reference resource subject: \(error)")
		}
		activityCollector = ActivityCollector(coreMotionDBPath: path, coreMotionInterpreter: coreMotionInterpreter)
		activityCollector?.resourceForAllActivity(ofLastDays: days) { response, error in
			if let resource = response {
				resource.subject = reference
				resource.create(server) { error in
					if let error = error {
						c3_logIfDebug("Failed to submit activity data resource: \(error)")
					}
				}
				
				#if DEBUG
				debugPrint(resource)
				#endif
			}
			else if let error = error {
				c3_logIfDebug("Error receiving activity data: \(error)")
			}
			else {
				c3_logIfDebug("Did not receive any activity data")
			}
		}
	}
}

