//
//  ActivityReportPeriod.swift
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

import SMART
import HealthKit


/**
A class that represents a period of activity.

The period is defined via its `period` property, which has a human-readable name, knows how many days it spans and can hold on to HealthKit
and CoreMotion samples in `healthKitSamples` (as `HKQuantitySample`) and `coreMotionActivities` (as `CoreMotionActivitySum`), respectively.
*/
open class ActivityReportPeriod: CustomStringConvertible, CustomDebugStringConvertible {
	
	/// The reporting period.
	open let period: Period
	
	/// A human-friendly description of the period.
	open var humanPeriod: String?
	
	/// How many days the period contains.
	open var numberOfDays: Int?
	
	/// Samples describing activities for the reporting period as reported by HealthKit.
	open var healthKitSamples: [HKQuantitySample]?
	
	/// Activities in the reporting period as determined by CoreMotion.
	open var coreMotionActivities: [CoreMotionActivitySum]?
	
	
	public init(period: Period) {
		self.period = period
	}
	
	
	// MARK: - FHIR Representations
	
	open func samplesAsResponse() -> [QuestionnaireResponseItem] {
		guard let samples = healthKitSamples else {
			return []
		}
		var questions = [QuestionnaireResponseItem]()
		
		for sample in samples {
			let answer = QuestionnaireResponseItemAnswer()
			answer.valueQuantity = try? sample.c3_asFHIRQuantity()
			let question = QuestionnaireResponseItem()
			question.linkId = FHIRString("healthkit.\(sample.quantityType.identifier)")
			question.answer = [answer]
			questions.append(question)
		}
		return questions
	}
	
	open func durationsAsResponse() -> [QuestionnaireResponseItem] {
		guard let durations = coreMotionActivities else {
			return []
		}
		var questions = [QuestionnaireResponseItem]()
		
		for duration in durations {
			let answer = QuestionnaireResponseItemAnswer()
			answer.valueQuantity = duration.duration
			let question = QuestionnaireResponseItem()
			question.linkId = FHIRString("motion-coprocessor.\(duration.type.rawValue)")
			question.answer = [answer]
			questions.append(question)
		}
		return questions
	}
	
	open func asQuestionnaireResponse(linkId: String) throws -> QuestionnaireResponse {
		let response = QuestionnaireResponse(status: .completed)
		response.questionnaire = Reference()
		response.questionnaire!.reference = FHIRString(linkId)
		response.item = samplesAsResponse() + durationsAsResponse()
		
		let encounter = Encounter(status: .finished)
		encounter.id = "period"
		encounter.period = period
		response.context = try response.contain(resource: encounter)
		
		return response
	}
	
	
	// MARK: - Custom String Convertible
	
	open var description: String {
		let human = (nil == humanPeriod) ? "" : " “\(humanPeriod!.replacingOccurrences(of: "\n", with: " "))”"
		return "<\(type(of: self))>\(human) from \(period.start?.description ?? "unknown start") to \(period.end?.description ?? "unknown end")"
	}
	
	open var debugDescription: String {
		let human = (nil == humanPeriod) ? "" : " “\(humanPeriod!.replacingOccurrences(of: "\n", with: " "))”"
		return "<\(type(of: self))>\(human) from \(period.start?.description ?? "unknown start") to \(period.end?.description ?? "unknown end")\n- samples: \(healthKitSamples ?? [])\n- motion: \(coreMotionActivities ?? [])"
	}
}

