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
public class CoreMotionReporter {
	
	/// The filesystem path to the database.
	public let databaseLocation: String
	
	var _connection: Connection?
	
	lazy var motionManager = CMMotionActivityManager()
	
	
	/**
	Designated initializer.
	
	- parameter path: The filesystem path to the SQLite database
	*/
	public init(path: String) {
		databaseLocation = path
	}
	
	
	// MARK: - Archiving
	
	/**
	Returns the SQLite connection object to use.
	*/
	func connection() throws -> Connection {
		if let db = _connection {
			return db
		}
		let fm = NSFileManager()
		do {
			let attrs = try fm.attributesOfItemAtPath(databaseLocation) as NSDictionary
			let size = attrs.fileSize()
			c3_logIfDebug("ARCHIVER database is already \(size / 1024) KB large")
//			try? fm.removeItemAtPath(databaseLocation)
		}
		catch {  }
		_connection = try Connection(databaseLocation)
		return _connection!
	}
	
	
	/**
	Archive all available activities (that happened since the last sampling) to our SQLite database.
	
	The data store is lossless, meaning that all aspects of the activities are preserved. The db format has been kept as compact as
	possible, using NSDate's `timeIntervalSinceReferenceDate` to store the date which also serves as primary key. In my setup, iPhone 6S
	plus Apple Watch, this amounts to 420 KB of data for a week.
	
	- parameter callback: The callback to call when done, with an error if something happened, nil otherwise. Called on the main queue
	*/
	public func archiveActivities(callback: ((numNewActivities: Int, error: ErrorType?) -> Void)) {
		do {
			let db = try connection()
			let activities = Table("activities")
			let start = Expression<Double>("start")            // Start in seconds since NSDate reference date (1/1/2001)
			let activity = Expression<Int64>("activity")       // bitmask over MotionActivityType
			let confidence = Expression<Int64>("confidence")   // 0 = low, 1 = medium, 2 = high
			
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
			
			if let latest = latest where (now.timeIntervalSinceReferenceDate - latest.timeIntervalSinceReferenceDate) < 30*60 {
				c3_logIfDebug("Latest activity was sampled \(latest), not archiving again")
				c3_performOnMainQueue() {
					callback(numNewActivities: 0, error: nil)
				}
				return
			}
			
			// collect activities and store to database
			collectActivitiesStartingOn(latest) { samples, collError in
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
								try db.run(activities.insert(
									start <- sample.startDate.timeIntervalSinceReferenceDate,
									activity <- Int64(sample.type.rawValue),
									confidence <- Int64(sample.confidence)))
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
	back, which is useless since there's at max 7 days of activity data available (as of iOS 9). But who knows, maybe it gets bumped one
	day.
	
	- parameter start:    The NSDate at which to start sampling, up until now
	- parameter callback: The callback to call when sampling completes. Will execute on the main queue
	*/
	func collectActivitiesStartingOn(start: NSDate?, callback: ((data: [CoreMotionActivity], error: ErrorType?) -> Void)) {
		let collectorQueue = NSOperationQueue()
		var begin = start ?? NSDate()
		if nil == start {
			begin = begin.dateByAddingTimeInterval(-15*24*3600)    // there's at most 7 days of activity available. Be conservative and use 15 days.
		}
		motionManager.queryActivityStartingFromDate(begin, toDate: NSDate(), toQueue: collectorQueue) { activities, error in
			if let activities = activities {
				var samples = [CoreMotionActivity]()
				for activity in activities {
					samples.append(CoreMotionActivity(activity: activity))
				}
				c3_performOnMainQueue() {
					callback(data: samples, error: nil)
				}
			}
			else if let error = error where CMErrorDomain != error.domain && 104 != error.code {   // CMErrorDomain error 104 means "no data available"
				print("No activity data received with error: \(error ?? "no error")")
				c3_performOnMainQueue() {
					callback(data: [], error: error)
				}
			}
			else {
				print("No activity data received")
				c3_performOnMainQueue() {
					callback(data: [], error: nil)
				}
			}
		}
	}
}

