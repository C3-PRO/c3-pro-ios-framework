//
//  ActivityCollector.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 15/07/16.
//  Copyright © 2016 University Hospital Zurich. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import SMART


/**
Class that uses both `HealthKitReporter` and `CoreMotionReporter` to retrieve activity data from both stores.
*/
public class ActivityCollector: ActivityReporter {
	
	var hkReporter: HealthKitReporter?
	
	var cmReporter: CoreMotionReporter?
	
	/// Path to the CoreMotionReporter local data store; you usually place this in ~/Library.
	public let cmPath: String
	
	/// The CoreMotionActivityInterpreter to use to interpret core motion activity sampled by the receiver.
	public let cmInterpreter: CoreMotionActivityInterpreter?
	
	
	/**
	Designated initializer.
	
	- parameter coreMotionDBPath: The path to the local CoreMotion database, as used by `CoreMotionReporter`
	- parameter coreMotionInterpreter: The core motion activity interpreter to use; uses `CoreMotionReporter` itself if nil
	*/
	public init(coreMotionDBPath: String, coreMotionInterpreter: CoreMotionActivityInterpreter?) {
		cmPath = coreMotionDBPath
		cmInterpreter = coreMotionInterpreter
	}
	
	
	// MARK: - Activity Resource Reporting
	
	/**
	Creates a `QuestionnaireResponse` resource containing all activities of the past x days.
	
	- parameter ofLastDays: The number of days before today to start on
	- parameter callback:   The callback to call when all activities are retrieved
	*/
	public func resourceForAllActivity(ofLastDays days: Int = 7, callback: ((resource: QuestionnaireResponse?, error: ErrorType?) -> Void)) {
		let end = NSDate()
		let comps = NSDateComponents()
		comps.day = -1 * days
		let start = NSCalendar.currentCalendar().dateByAddingComponents(comps, toDate: end, options: [])!
		resourceForAllActivity(startingAt: start, until: end, callback: callback)
	}
	
	/**
	Creates a `QuestionnaireResponse` resource for all activity that was reported in the given period.
	
	- parameter startingAt: The start date
	- parameter until:      The end date
	- parameter callback:   The callback to call when all activities are retrieved
	*/
	public func resourceForAllActivity(startingAt start: NSDate, until: NSDate, callback: ((resource: QuestionnaireResponse?, error: ErrorType?) -> Void)) {
		reportForActivityPeriod(startingAt: start, until: until) { report, error in
			do {
				let answer = try report?.asQuestionnaireResponse("org.chip.c3-pro.activity")
				callback(resource: answer, error: error)
			}
			catch let error {
				c3_logIfDebug("Failed to create response resource: \(error)")
				callback(resource: nil, error: error)
			}
		}
	}
	
	
	// MARK: - Reporting
	
	/**
	Collect activities from HealthKit and CoreMotion over the given period.
	
	- parameter startingAt: The start date
	- parameter until:      The end date
	- parameter callback:   The callback to call when all activities are retrieved
	*/
	public func reportForActivityPeriod(startingAt start: NSDate, until: NSDate, callback: ((period: ActivityReportPeriod?, error: ErrorType?) -> Void)) {
		let queueGroup = dispatch_group_create()
		var errors = [ErrorType]()
		
		// motion co-processor data
		dispatch_group_enter(queueGroup)
		var cmReport: ActivityReportPeriod?
		let cm = cmReporter ?? CoreMotionReporter(path: cmPath)
		cmReporter = cm
		cm.reportForActivityPeriod(startingAt: start, until: until, interpreter: cmInterpreter) { report, error in	// TODO: handle interpreter with protocols
			cmReport = report
			if let error = error {
				errors.append(error)
			}
			dispatch_group_leave(queueGroup)
		}
		
		// HealthKit data
		dispatch_group_enter(queueGroup)
		var hkReport: ActivityReportPeriod?
		let hk = hkReporter ?? HealthKitReporter()
		hkReporter = hk
		hk.reportForActivityPeriod(startingAt: start, until: until) { report, error in
			hkReport = report
			if let error = error {
				errors.append(error)
			}
			dispatch_group_leave(queueGroup)
		}
		
		// some FHIR preparations while we wait
		let period = Period(json: nil)
		period.start = start.fhir_asDateTime()
		period.end = until.fhir_asDateTime()
		
		// put both reports into one
		dispatch_group_notify(queueGroup, dispatch_get_main_queue()) {
			let period = ActivityReportPeriod(period: period)
			period.coreMotionActivities = cmReport?.coreMotionActivities
			period.healthKitSamples = hkReport?.healthKitSamples
			
			callback(period: period, error: (errors.count > 0) ? C3Error.MultipleErrors(errors) : nil)
		}
	}
}
