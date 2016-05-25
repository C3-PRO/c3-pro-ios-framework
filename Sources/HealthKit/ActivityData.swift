//
//  ActivityData.swift
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


public class ActivityData: CustomStringConvertible {
	
	public let period: Period
	
	public var humanPeriod: String?
	
	public var numberOfDays: Int?
	
	public var quantitySamples: [HKQuantitySample]?
	
	public var activityDurations: [MotionActivityDuration]? {
		didSet {
			// sort
			if let durations = activityDurations {
				self.activityDurations = durations.sort {
					$0.preferredPosition < $1.preferredPosition
				}
			}
			nonUnknownActivityDurations = activityDurations?.filter() { $0.type != .Unknown }
		}
	}
	
	public internal(set) var nonUnknownActivityDurations: [MotionActivityDuration]?
	
	
	public init(period: Period) {
		self.period = period
	}
	
	
	// MARK: - FHIR Representations
	
	public func samplesAsResponse() -> [QuestionnaireResponseGroupQuestion] {
		guard let samples = quantitySamples else {
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
		guard let durations = activityDurations else {
			return []
		}
		var questions = [QuestionnaireResponseGroupQuestion]()
		
		for duration in durations {
			let answer = QuestionnaireResponseGroupQuestionAnswer(json: nil)
			answer.valueQuantity = duration.duration
			let question = QuestionnaireResponseGroupQuestion(json: nil)
			question.linkId = "motion-coprocessor.\(duration.identifier)"
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
		return "<\(String(self.dynamicType)): \(unsafeAddressOf(self))> from \(period.start?.description ?? "unknown start") to \(period.end?.description ?? "unknown end")"
	}
}

