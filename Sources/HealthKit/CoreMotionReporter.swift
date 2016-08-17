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

See [HealthKit/README.md](https://github.com/C3-PRO/c3-pro-ios-framework/tree/master/Sources/HealthKit#core-motion-data-persistence) for detailed instructions.
*/
public class CoreMotionReporter: ActivityReporter {
	
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
	
	TODO: reactivate once SQLiteSwift works with Swift 3
	* /
	func connection() throws -> Connection {
		#if false
		let fm = NSFileManager()
		if let attrs = try? fm.attributesOfItemAtPath(databaseLocation) as NSDictionary {
			let size = attrs.fileSize()
			c3_logIfDebug("REPORTER database is \(size / 1024) KB")
		}
		#endif
		return try Connection(databaseLocation)
	}	//	*/
	
	
	// MARK: - Archiving
	
	private var lastArchival: Date?
	
	
	/**
	Archive all available activities (that happened since the last sampling) to our SQLite database.
	
	The data store is lossless, meaning that all aspects of the activities are preserved. The db format has been kept as compact as
	possible, using NSDate's `timeIntervalSinceReferenceDate` to store the date which also serves as primary key. In my setup, iPhone 6S
	plus Apple Watch, this amounts to 420 KB of data for a week.
	
	- parameter processor: A `CoreMotionActivityInterpreter` instance to handle CMMotionActivity processing (not interpretation!) before the
	                       callback returns; uses an `CoreMotionStandardActivityInterpreter` instance if none is provided
	- parameter callback:  The callback to call when done, with an error if something happened, nil otherwise. Called on the main queue
	*/
	public func archiveActivities(processor: CoreMotionActivityInterpreter? = nil, callback: ((numNewActivities: Int, error: Error?) -> Void)) {
		if let lastArchival = lastArchival, lastArchival.timeIntervalSinceNow > -30 {
			callback(numNewActivities: 0, error: nil)
			return
		}
		
		do {
			callback(numNewActivities: 0, error: C3Error.notImplemented("Activity archiving is not yet available with Swift 3"))
			/*
			TODO: reactivate once SQLiteSwift works with Swift 3
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
			let now = Date()
			var latest: Date?
			let query = activities.select(start).order(start.desc).limit(1)
			for row in try db.prepare(query) {
				latest = NSDate(timeIntervalSinceReferenceDate: row[start])
			}
			
			if let latest = latest, (now.timeIntervalSinceReferenceDate - latest.timeIntervalSinceReferenceDate) < 2*60 {
				c3_logIfDebug("Latest activity was sampled \(latest), not archiving again")
				c3_performOnMainQueue() {
					callback(numNewActivities: 0, error: nil)
				}
				return
			}
			
			// collect activities and store to database
			let processor = processor ?? CoreMotionStandardActivityInterpreter()
			collectCoreMotionActivities(startingOn: latest, processor: processor) { samples, collError in
				if let error = collError {
					callback(numNewActivities: 0, error: error)
					return
				}
				if 0 == samples.count {
					callback(numNewActivities: 0, error: nil)
					return
				}
				
				// insert into database
				DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background).async {
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
						self.lastArchival = Date()
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
			}	//	*/
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
	
	There is a bit of processing happening, rather than raw instances being returned, in the receiver's `preprocess(activities:)`
	implementation.
	
	- parameter startingOn: The NSDate at which to start sampling, up until now
	- parameter processor:  A `CoreMotionActivityInterpreter` instance to handle CMMotionActivity preprocessing (not interpretation!) before
	                        the callback returns
	- parameter callback:   The callback to call when sampling completes. Will execute on the main queue
	*/
	func collectCoreMotionActivities(startingOn start: Date?, processor: CoreMotionActivityInterpreter, callback: ((data: [CoreMotionActivity], error: Error?) -> Void)) {
		let collectorQueue = OperationQueue()
		var begin = start ?? Date()
		if nil == start {
			begin = begin.addingTimeInterval(-15*24*3600)    // there's at most 7 days of activity available. Be conservative and use 15 days.
		}
		motionManager.queryActivityStarting(from: begin, to: Date(), to: collectorQueue) { activities, error in
			if let activities = activities {
				let processor = processor ?? CoreMotionStandardActivityInterpreter()
				let samples = processor.preprocess(activities: activities)
				c3_performOnMainQueue() {
					callback(data: samples, error: nil)
				}
			}
			else if let error = error, CMErrorDomain != error._domain && 104 != error._code {   // CMErrorDomain error 104 means "no data available"
				c3_logIfDebug("No activity data received with error: \(error ?? "no error" as! Error)")
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
	
	public func reportForActivityPeriod(startingAt start: Date, until: Date, callback: ((period: ActivityReportPeriod?, error: Error?) -> Void)) {
		reportForActivityPeriod(startingAt: start, until: until, interpreter: nil, callback: callback)
	}
	
	/**
	Retrieves activities performed between two given dates and runs an interpreter over the results which may process the activities in a
	certain way.
	
	- parameter startingAt:  The start date
	- parameter until:       The end date; uses "now" if nil
	- parameter interpreter: The interpreter to use; uses a fresh instance of `CoreMotionStandardActivityInterpreter` if nil
	- parameter callback:    The callback to call when all activities are retrieved and the interpreter has run
	*/
	public func reportForActivityPeriod(startingAt start: Date, until: Date? = nil, interpreter: CoreMotionActivityInterpreter? = nil, callback: ((report: ActivityReportPeriod?, error: Error?) -> Void)) {
		archiveActivities() { newActivities, error in
			if let error = error {
				c3_logIfDebug("Ignoring error when archiving most recent activities before retrieving: \(error)")
			}
			let endDate = until ?? Date()
			
			// dispatch to background queue and call back on the main queue
			DispatchQueue.global(qos: DispatchQoS.QoSClass.utility).async() {
				do {
					let interpreter = interpreter ?? CoreMotionStandardActivityInterpreter()
					let activities = try self.retrieveActivities(startingAt: start, until: endDate, interpreter: interpreter)
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
	- parameter interpreter: The interpreter to use; uses a fresh instance of `CoreMotionStandardActivityInterpreter` if nil
	*/
	func retrieveActivities(startingAt start: Date, until: Date, interpreter: CoreMotionActivityInterpreter) throws -> [InterpretedCoreMotionActivity] {
		/*
		TODO: reactivate
		let db = try self.connection()
		let activitiesTable = Table("activities")
		let startCol = Expression<Double>("start")
		let activityCol = Expression<Int>("activity")
		let confidenceCol = Expression<Int>("confidence")
		
		let startTime = start.timeIntervalSinceReferenceDate
		let endTime = until.timeIntervalSinceReferenceDate
		
		// query database
		let filtered = activitiesTable.filter(startCol >= startTime).filter(startCol <= endTime)	//	*/
		var collected = [InterpretedCoreMotionActivity]()
		/*for row in try db.prepare(filtered) {
			let activity = InterpretedCoreMotionActivity(start: row[startCol], activity: row[activityCol], confidence: row[confidenceCol], end: 0.0)
			if let prev = collected.last {
				prev.endDate = activity.startDate
			}
			collected.append(activity)
		}	//	*/
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
		let calendar = NSCalendar.current
		var earliest: Date?
		var latest: Date?
		
		// aggregate seconds
		var periods = [CoreMotionActivityInterpretation: Int]()
		for activity in activities {
			earliest = (nil == earliest || activity.startDate.compare(earliest!) == .orderedAscending) ? activity.startDate as Date : earliest
			latest = (nil == latest || activity.endDate.compare(latest!) == .orderedDescending) ? activity.endDate as Date : latest
			
			let baseSecs = periods[activity.interpretation] ?? 0
			let newSecs = calendar.dateComponents([.second], from: activity.startDate, to: activity.endDate).second ?? 0
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
		period.start = earliest?.fhir_asDateTime()
		period.end = latest?.fhir_asDateTime()
		let data = ActivityReportPeriod(period: period)
		data.coreMotionActivities = durations
		
		return data
	}
}

