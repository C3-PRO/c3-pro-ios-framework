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
	
	open func samplesAsResponse() -> [QuestionnaireResponseGroupQuestion] {
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
	
	open func durationsAsResponse() -> [QuestionnaireResponseGroupQuestion] {
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
	
	open func asQuestionnaireResponse(linkId: String) throws -> QuestionnaireResponse {
		let response = QuestionnaireResponse(status: "completed")
		response.questionnaire = Reference(json: ["reference": linkId])
		
		let group = QuestionnaireResponseGroup(json: nil)
		group.linkId = linkId
		group.question = samplesAsResponse() + durationsAsResponse()
		response.group = group
		
		let encounter = Encounter(status: "finished")
		encounter.id = "period"
		encounter.period = period
		response.encounter = try response.contain(resource: encounter)
		
		return response
	}
	
	
	// MARK: - Custom String Convertible
	
	open var description: String {
		return String(format: "<\(self) %p> from \(period.start?.description ?? "unknown start") to \(period.end?.description ?? "unknown end")", self as! CVarArg)
	}
	
	open var debugDescription: String {
		return String(format: "<\(self) %p> from \(period.start?.description ?? "unknown start") to \(period.end?.description ?? "unknown end")\n- samples: \(healthKitSamples ?? [])\n- motion: \(coreMotionActivities ?? [])", self as! CVarArg)
	}
}

