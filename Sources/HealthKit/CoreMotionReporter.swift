//
//  CoreMotionReporter.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 24/05/16.
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
import CoreMotion
import SMART


/**
Dumps latest activity data from CoreMotion to a SQLite database and returns previously archived activity data.
*/
public class CoreMotionReporter: ActivityReporter, CoreMotionActivityInterpreter {
	
	/// The filesystem path to the database.
	public let databaseLocation: String
	
	lazy var motionManager = CMMotionActivityManager()
	
	
	/**
	Designated initializer.
	
	- parameter path: The filesystem path to the SQLite database
	*/
	public init(path: String) {
		databaseLocation = path
	}
	
	
	// MARK: - SQLite
	
	/**
	Returns the SQLite connection object to use.
	*/
	func connection() throws -> Connection {
		let fm = NSFileManager()
		if let attrs = try? fm.attributesOfItemAtPath(databaseLocation) as NSDictionary {
			let size = attrs.fileSize()
			c3_logIfDebug("REPORTER database is \(size / 1024) KB")
		}
		return try Connection(databaseLocation)
	}
	
	
	// MARK: - Archiving
	
	
	/**
	Archive all available activities (that happened since the last sampling) to our SQLite database.
	
	The data store is lossless, meaning that all aspects of the activities are preserved. The db format has been kept as compact as
	possible, using NSDate's `timeIntervalSinceReferenceDate` to store the date which also serves as primary key. In my setup, iPhone 6S
	plus Apple Watch, this amounts to 420 KB of data for a week.
	
	- parameter processor: A `CoreMotionActivityInterpreter` instance to handle CMMotionActivity processing (not interpretation!) before the
	                       callback returns; uses self if none is provided
	- parameter callback:  The callback to call when done, with an error if something happened, nil otherwise. Called on the main queue
	*/
	public func archiveActivities(processor: CoreMotionActivityInterpreter? = nil, callback: ((numNewActivities: Int, error: ErrorType?) -> Void)) {
		do {
			let db = try connection()
			let activities = Table("activities")
			let start = Expression<Double>("start")          // Start in seconds since NSDate reference date (1/1/2001)
			let activity = Expression<Int>("activity")       // bitmask over MotionActivityType
			let confidence = Expression<Int>("confidence")   // 0 = low, 1 = medium, 2 = high
			
			// create table if needed
			try db.run(activities.create(ifNotExists: true) { t in
				t.column(start, unique: true)
				t.column(activity)
				t.column(confidence)
			})
			
			// grab latest startDate
			let now = NSDate()
			var latest: NSDate?
			let query = activities.select(start).order(start.desc).limit(1)
			for row in try db.prepare(query) {
				latest = NSDate(timeIntervalSinceReferenceDate: row[start])
			}
			
			if let latest = latest where (now.timeIntervalSinceReferenceDate - latest.timeIntervalSinceReferenceDate) < 2*60 {
				c3_logIfDebug("Latest activity was sampled \(latest), not archiving again")
				c3_performOnMainQueue() {
					callback(numNewActivities: 0, error: nil)
				}
				return
			}
			
			// collect activities and store to database
			collectCoreMotionActivities(startingOn: latest, processor: processor ?? self) { samples, collError in
				if let error = collError {
					callback(numNewActivities: 0, error: error)
					return
				}
				if 0 == samples.count {
					callback(numNewActivities: 0, error: nil)
					return
				}
				
				// insert into database
				dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
					do {
						try db.transaction() {
							print("\(NSDate()) ARCHIVER inserting \(samples.count) samples")
							for sample in samples {
								try db.run(activities.insert(or: .Ignore,    // UNIQUE constraint on `start` may fail, which we want to ignore
									start <- round(sample.startDate.timeIntervalSinceReferenceDate * 10) / 10,
									activity <- sample.type.rawValue,
									confidence <- sample.confidence.rawValue))
							}
							print("\(NSDate()) ARCHIVER done inserting")
						}
						c3_performOnMainQueue() {
							callback(numNewActivities: samples.count, error: nil)
						}
					}
					catch let error {
						c3_performOnMainQueue() {
							callback(numNewActivities: 0, error: error)
						}
					}
				}
			}
		}
		catch let error {
			c3_performOnMainQueue() {
				callback(numNewActivities: 0, error: error)
			}
		}
	}
	
	/**
	Sample CMMotionActivityManager for activities from the given start date up until now. If no start date is given, starts sampling 15 days
	back, which is useless since there's at max 7 days of activity data available (as of iOS 9). But who knows, maybe it gets bumped up one
	day.
	
	There is a bit of processing happening, rather than raw instances being returned, in the receiver's
	`preprocess(activities:)` implementation.
	
	- parameter startingOn: The NSDate at which to start sampling, up until now
	- parameter processor:  A `CoreMotionActivityInterpreter` instance to handle CMMotionActivity processing (not interpretation!) before the
	                        callback returns
	- parameter callback:   The callback to call when sampling completes. Will execute on the main queue
	*/
	func collectCoreMotionActivities(startingOn start: NSDate?, processor: CoreMotionActivityInterpreter, callback: ((data: [CoreMotionActivity], error: ErrorType?) -> Void)) {
		let collectorQueue = NSOperationQueue()
		var begin = start ?? NSDate()
		if nil == start {
			begin = begin.dateByAddingTimeInterval(-15*24*3600)    // there's at most 7 days of activity available. Be conservative and use 15 days.
		}
		motionManager.queryActivityStartingFromDate(begin, toDate: NSDate(), toQueue: collectorQueue) { activities, error in
			if let activities = activities {
				let samples = self.preprocess(activities: activities)
				c3_performOnMainQueue() {
					callback(data: samples, error: nil)
				}
			}
			else if let error = error where CMErrorDomain != error.domain && 104 != error.code {   // CMErrorDomain error 104 means "no data available"
				c3_logIfDebug("No activity data received with error: \(error ?? "no error")")
				c3_performOnMainQueue() {
					callback(data: [], error: error)
				}
			}
			else {
				c3_logIfDebug("No activity data received")
				c3_performOnMainQueue() {
					callback(data: [], error: nil)
				}
			}
		}
	}
	
	
	// MARK: - Retrieval
	
	public func reportForActivityPeriod(startingAt start: NSDate, until: NSDate, callback: ((period: ActivityReportPeriod?, error: ErrorType?) -> Void)) {
		reportForActivityPeriod(startingAt: start, until: until, interpreter: nil, callback: callback)
	}
	
	/**
	Retrieves activities performed between two given dates and runs an interpreter over the results which may process the activities in a
	certain way.
	
	- parameter startingAt:  The start date
	- parameter until:       The end date; uses "now" if nil
	- parameter interpreter: The interpreter to use; uses self if nil
	- parameter callback:    The callback to call when all activities are retrieved and the interpreter has run
	*/
	public func reportForActivityPeriod(startingAt start: NSDate, until: NSDate? = nil, interpreter: CoreMotionActivityInterpreter? = nil, callback: ((report: ActivityReportPeriod?, error: ErrorType?) -> Void)) {
		archiveActivities() { newActivities, error in
			if let error = error {
				c3_logIfDebug("Ignoring error when archiving most recent activities before retrieving: \(error)")
			}
			let endDate = until ?? NSDate()
			
			// dispatch to background queue and call back on the main queue
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
				do {
					let activities = try self.retrieveActivities(startingAt: start, until: endDate, interpreter: interpreter ?? self)
					let report = self.report(forActivities: activities)
					c3_performOnMainQueue() {
						callback(report: report, error: nil)
					}
				}
				catch let error {
					c3_performOnMainQueue() {
						callback(report: nil, error: error)
					}
				}
			}
		}
	}
	
	/**
	Internal method that connects to the SQLite database, retrieves activities between the two dates, instantiates
	`InterpretedCoreMotionActivity` for all of them and lets the interpreter do its work.
	
	- parameter startingAt:  The start date
	- parameter until:       The end date; uses "now" if nil
	- parameter interpreter: The interpreter to use; uses self if nil
	*/
	func retrieveActivities(startingAt start: NSDate, until: NSDate, interpreter: CoreMotionActivityInterpreter) throws -> [InterpretedCoreMotionActivity] {
		let db = try self.connection()
		let activitiesTable = Table("activities")
		let startCol = Expression<Double>("start")
		let activityCol = Expression<Int>("activity")
		let confidenceCol = Expression<Int>("confidence")
		
		let startTime = start.timeIntervalSinceReferenceDate
		let endTime = until.timeIntervalSinceReferenceDate
		
		// query database
		let filtered = activitiesTable.filter(startCol >= startTime).filter(startCol <= endTime)
		var collected = [InterpretedCoreMotionActivity]()
		for row in try db.prepare(filtered) {
			let activity = InterpretedCoreMotionActivity(start: row[startCol], activity: row[activityCol], confidence: row[confidenceCol], end: 0.0)
			if let prev = collected.last {
				prev.endDate = activity.startDate
			}
			collected.append(activity)
		}
		if let last = collected.last {
			last.endDate = until
		}
		
		// run interpreter and return
		return interpreter.interpret(activities: collected)
	}
	
	
	// MARK: - Reporting
	
	/**
	Takes an array of activities and sums up all activities per type to generate an activity report for the period spanned by the
	activities.
	
	- parameter forActivities: The activites to aggregate into a report
	- returns:                 An ActivityReportPeriod instance for the period defined by all individual activities
	*/
	func report(forActivities activities: [InterpretedCoreMotionActivity]) -> ActivityReportPeriod {
		let calendar = NSCalendar.currentCalendar()
		var earliest = NSDate.distantFuture()
		var latest = NSDate.distantPast()
		
		// aggregate seconds
		var periods = [CoreMotionActivityInterpretation: Int]()
		for activity in activities {
			earliest = (activity.startDate.compare(earliest) == .OrderedAscending) ? activity.startDate : earliest
			latest = (activity.endDate.compare(latest) == .OrderedAscending) ? latest : activity.endDate
			
			let baseSecs = periods[activity.interpretation] ?? 0
			let newSecs = calendar.components(.Second, fromDate: activity.startDate, toDate: activity.endDate, options: []).second
			periods[activity.interpretation] = baseSecs + newSecs
		}
		
		// instantiate durations
		var durations = [CoreMotionActivitySum]()
		for (type, secs) in periods {
			let minutes = Duration(json: ["value": secs / 60, "unit": "minute"])
			let duration = CoreMotionActivitySum(type: type, duration: minutes)
			durations.append(duration)
		}
		
		let period = Period(json: nil)
		period.start = earliest.fhir_asDateTime()
		period.end = latest.fhir_asDateTime()
		let data = ActivityReportPeriod(period: period)
		data.coreMotionActivities = durations
		
		return data
	}
	
	
	// MARK: - CoreMotionActivityInterpreter
	
	/**
	Preprocesses raw motion activities before they are dumped to SQLite. See the Motion Tracking talk from WWDC14 for a detailed look at
	how this stuff works: https://developer.apple.com/videos/play/wwdc2014/612/
	
	1. all unknown activities are discarded
	2. adjacent activities with same type(s), ignoring their confidence, are joined together and the highest confidence is retained; this
	   means that activities that had unknown activities interspersed are joined together and also span the time of the unknown period
	3. adjacent "automotive" activities are joined even if they have additional types (typically "stationary"); highest confidence is
	   retained and their types are union-ed
	
	- parameter activities: The activities to preprocess
	- returns: Preprocessed and packaged motion activities
	*/
	public func preprocess(activities activities: [CMMotionActivity]) -> [CoreMotionActivity] {
		var samples = [CoreMotionActivity]()
		for cmactivity in activities {
			let activity = CoreMotionActivity(activity: cmactivity)
			if let processed = preprocessedMotionActivity(activity, followingAfter: samples.last) {
				samples.append(processed)
			}
		}
		return samples
	}
	
	/**
	Internal method to apply preprocessing both before archiving as well as for interpretation during retrieval.
	
	See `preprocess(activities:)` for the rules being applied.
	
	- parameter activity:       The activity to evaluate
	- parameter followingAfter: The activity preceding `activity`, if any - may be modified
	- returns:                  An interpreted activity to be collected by the caller; if nil is returned the activity has been filtered
	*/
	func preprocessedMotionActivity<T: CoreMotionActivity>(activity: T, followingAfter prev: T?) -> T? {
		
		// 1: skip unknown activities (skip if "unknown" = true (known unknown) as well as those without any true state (unknown unknown))
		if !activity.type.isSubsetOf(.Unknown) {
			
			// 2: join same activities
			if let prev = prev where prev.type.isSubsetOf(activity.type) && activity.type.isSubsetOf(prev.type) {
				prev.confidence = max(prev.confidence, activity.confidence)
			}
			
			// 3: join automotive activities
			else if let prev = prev where prev.type.contains(.Automotive) && activity.type.contains(.Automotive) {
				prev.type = prev.type.union(activity.type)
				prev.confidence = max(prev.confidence, activity.confidence)
			}
			else {
				return activity
			}
		}
		return nil
	}
	
	/**
	Our implementation of the core motion activity interpreter. It runs these interpretation rules:
	
	- automotive < 5 minutes: stationary
	- cycling < 2 minutes: running if prev/next is running, walking if prev/next is walking, stationary otherwise
	- walking < 1 minute, stationary prev and next, low confidence: stationary
	- stationary > 3 hours: sleeping
	- IDEA: stationary < 1 minute, running or walking before and after: standing
	
	- parameter activities: The activities to interpret
	- returns:              An array of interpreted activities
	*/
	public func interpret(activities activities: [InterpretedCoreMotionActivity]) -> [InterpretedCoreMotionActivity] {
		var prev: InterpretedCoreMotionActivity?
		for i in 0..<activities.count {
			let activity = activities[i]
			let duration = activity.endDate.timeIntervalSinceDate(activity.startDate)
			
			// automotive < 5 minutes: stationary
			if activity.type.contains(.Automotive) && duration < 300.0 {
				activity.type.remove(.Automotive)
				activity.type.unionInPlace(.Stationary)
				activity.interpretation = .Automotive
			}
				
			// cycling < 2 minutes: running if prev/next is running, walking if prev/next is walking, stationary otherwise
			else if activity.type.contains(.Cycling) && duration < 120.0 {
				activity.type.remove(.Cycling)
				if let prev = prev where prev.type.contains(.Running) {
					activity.type.unionInPlace(.Running)
					activity.interpretation = .Running
				}
				else if activities.count > i+1 && activities[i+1].type.contains(.Running) {
					activity.type.unionInPlace(.Running)
					activity.interpretation = .Running
				}
				else if let prev = prev where prev.type.contains(.Walking) {
					activity.type.unionInPlace(.Walking)
					activity.interpretation = .Walking
				}
				else if activities.count > i+1 && activities[i+1].type.contains(.Walking) {
					activity.type.unionInPlace(.Walking)
					activity.interpretation = .Walking
				}
				else {
					activity.type.unionInPlace(.Stationary)
					activity.interpretation = .Stationary
				}
			}
			
			/*/ stationary < 1 minute, running or walking before and after: standing
			else if activity.type.contains(.Stationary) && duration < 60.0 {
				if let prev = prev where prev.isWalkingRunningCycling {
				}
				else if self.activities.count > i+1 && self.activities[i+1].isWalkingRunningCycling {
				}
			}	//	*/
			
			// no rule, interpret by picking `type`
			else {
				if activity.type.contains(.Cycling) {
					activity.interpretation = .Cycling
				}
				else if activity.type.contains(.Running) {
					activity.interpretation = .Running
				}
				else if activity.type.contains(.Walking) {
					activity.interpretation = .Walking
				}
				else if activity.type.contains(.Automotive) {
					activity.interpretation = .Automotive
				}
				else if activity.type.contains(.Stationary) {
					activity.interpretation = .Stationary
				}
				else {
					activity.interpretation = .Unknown
				}
			}
			
			prev = activity
		}
		
		// concatenate same (using the same preprocessing algo as when archiving since activities may have changed) and find sleep
		var interpreted = [InterpretedCoreMotionActivity]()
		for activity in activities {
			if let inter = preprocessedMotionActivity(activity, followingAfter: interpreted.last) {
				interpreted.append(inter)
				
				// is this sleep? Yes if stationary > 3 hours
				if .Stationary == inter.interpretation {
					if NSCalendar.currentCalendar().components(.Hour, fromDate: inter.startDate, toDate: inter.endDate, options: []).hour >= 3 {
						inter.interpretation = .Sleeping
					}
				}
			}
		}
		return interpreted
	}
}

