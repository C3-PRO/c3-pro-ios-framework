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
public class ActivityCollector {
	
	var hkReporter: HealthKitReporter?
	
	var cmReporter: CoreMotionReporter?
	
	let cmPath: String
	
	let cmInterpreter: CoreMotionActivityInterpreter?
	
	public init(coreMotionDBPath: String, coreMotionInterpreter: CoreMotionActivityInterpreter?) {
		cmPath = coreMotionDBPath
		cmInterpreter = coreMotionInterpreter
	}
	
	
	// MARK: - Activity Resource Reporting
	
	public func resourceForAllActivity(ofLastDays days: Int = 7, callback: ((resource: QuestionnaireResponse?, error: ErrorType?) -> Void)) {
		let end = NSDate()
		let comps = NSDateComponents()
		comps.day = -1 * days
		let start = NSCalendar.currentCalendar().dateByAddingComponents(comps, toDate: end, options: [])!
		resourceForAllActivity(startingAt: start, end: end, callback: callback)
	}
	
	public func resourceForAllActivity(startingAt start: NSDate, end: NSDate, callback: ((resource: QuestionnaireResponse?, error: ErrorType?) -> Void)) {
		reportForActivityPeriod(startingAt: start, until: end) { report, error in
			do {
				let answer = try report.asQuestionnaireResponse("org.chip.c3-pro.activity")
				callback(resource: answer, error: error)
			}
			catch let error {
				c3_logIfDebug("Failed to create response resource: \(error)")
				callback(resource: nil, error: error)
			}
		}
	}
	
	
	// MARK: - Reporting
	
	public func reportForActivityPeriod(startingAt start: NSDate, until: NSDate, callback: ((report: ActivityReportPeriod, error: ErrorType?) -> Void)) {
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
			let report = ActivityReportPeriod(period: period)
			report.coreMotionActivities = cmReport?.coreMotionActivities
			report.healthKitSamples = hkReport?.healthKitSamples
			
			callback(report: report, error: (errors.count > 0) ? C3Error.MultipleErrors(errors) : nil)
		}
	}
}

