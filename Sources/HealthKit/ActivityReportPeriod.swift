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


public class ActivityReportPeriod: CustomStringConvertible, CustomDebugStringConvertible {
	
	/// The reporting period.
	public let period: Period
	
	/// A human-friendly description of the period.
	public var humanPeriod: String?
	
	/// How many days the period contains.
	public var numberOfDays: Int?
	
	/// Samples describing activities for the reporting period as reported by HealthKit.
	public var healthKitSamples: [HKQuantitySample]?
	
	/// Activities in the reporting period as determined by CoreMotion.
	public var coreMotionActivities: [CoreMotionActivitySum]?
	
	
	public init(period: Period) {
		self.period = period
	}
	
	
	// MARK: - FHIR Representations
	
	public func samplesAsResponse() -> [QuestionnaireResponseGroupQuestion] {
		guard let samples = healthKitSamples else {
			return []
		}
		var questions = [QuestionnaireResponseGroupQuestion]()
		
		for sample in samples {
			let answer = QuestionnaireResponseGroupQuestionAnswer(json: nil)
			answer.valueQuantity = try? sample.c3_asFHIRQuantity()
			let question = QuestionnaireResponseGroupQuestion(json: nil)
			question.linkId = "healthkit.\(sample.quantityType.identifier)"
			question.answer = [answer]
			questions.append(question)
		}
		return questions
	}
	
	public func durationsAsResponse() -> [QuestionnaireResponseGroupQuestion] {
		guard let durations = coreMotionActivities else {
			return []
		}
		var questions = [QuestionnaireResponseGroupQuestion]()
		
		for duration in durations {
			let answer = QuestionnaireResponseGroupQuestionAnswer(json: nil)
			answer.valueQuantity = duration.duration
			let question = QuestionnaireResponseGroupQuestion(json: nil)
			question.linkId = "motion-coprocessor.\(duration.type.rawValue)"
			question.answer = [answer]
			questions.append(question)
		}
		return questions
	}
	
	public func asQuestionnaireResponse(linkId: String) throws -> QuestionnaireResponse {
		let answer = QuestionnaireResponse(status: "completed")
		answer.questionnaire = Reference(json: ["reference": linkId])
		
		let main = QuestionnaireResponseGroup(json: nil)
		main.linkId = linkId
		main.question = samplesAsResponse() + durationsAsResponse()
		answer.group = main
		
		let encounter = Encounter(status: "finished")
		encounter.id = "period"
		encounter.period = period
		answer.encounter = try answer.containResource(encounter)
		
		return answer
	}
	
	
	// MARK: - Custom String Convertible
	
	public var description: String {
		return "<\(String(self.dynamicType)) \(unsafeAddressOf(self))> from \(period.start?.description ?? "unknown start") to \(period.end?.description ?? "unknown end")"
	}
	
	public var debugDescription: String {
		return "<\(String(self.dynamicType)) \(unsafeAddressOf(self))> from \(period.start?.description ?? "unknown start") to \(period.end?.description ?? "unknown end")\n- samples: \(healthKitSamples ?? [])\n- motion: \(coreMotionActivities ?? [])"
	}
}

