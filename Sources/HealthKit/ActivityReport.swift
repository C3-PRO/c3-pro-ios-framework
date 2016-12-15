//
//  ActivityReport.swift
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

import SMART


open class ActivityReport: CustomStringConvertible {
	
	open var count: Int {
		return periods.count
	}
	
	open var first: ActivityReportPeriod? {
		return periods.first
	}
	
	open var last: ActivityReportPeriod? {
		return periods.last
	}
	
	open internal(set) var periods: [ActivityReportPeriod] {		// TODO: hide and make sequence type
		didSet {
			periods.sort() {
				guard let st0 = $0.0.period.start else { return true }
				guard let st1 = $0.1.period.start else { return false }
				return st0 < st1 }
			period = Period()
			period.start = periods.first?.period.start
			period.end = periods.last?.period.end
		}
	}
	
	open internal(set) var period: Period
	
	
	public init(periods: [ActivityReportPeriod]) {
		self.periods = periods.sorted() {
			guard let st0 = $0.0.period.start else { return true }
			guard let st1 = $0.1.period.start else { return false }
			return st0 < st1 }
		period = Period()
		period.start = periods.first?.period.start
		period.end = periods.last?.period.end
	}
	
	open subscript(key: Int) -> ActivityReportPeriod? {
		if key < periods.count {
			return periods[key]
		}
		return nil
	}
	
	
	// MARK: - Custom String Convertible
	
	open var description: String {
		return "<\(type(of: self))> from \(period.start?.description ?? "unknown start") to \(period.end?.description ?? "unknown end")"
	}
}

