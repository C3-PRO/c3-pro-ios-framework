//
//  QuestionnaireGroupPromise.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 4/20/15.
//  Copyright © 2015 Boston Children's Hospital. All rights reserved.
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
import ResearchKit


/**
A promise that can fulfill a questionnaire question into an ORKQuestionStep.
*/
class QuestionnaireGroupPromise: QuestionnairePromiseProto {
	
	/// The promises' group.
	let group: QuestionnaireGroup
	
	/// The group's steps, internally assigned after the promise has been successfully fulfilled.
	internal(set) var steps: [ORKStep]?
	
	
	/**
	Designated initializer.
	
	- parameter group: The group to be represented by the receiver
	*/
	init(group: QuestionnaireGroup) {
		self.group = group
	}
	
	
	// MARK: - Fulfilling
	
	/**
	Fulfill the promise.
	
	Once the promise and its step promises have been successfully fulfilled, the `group` property will be assigned.
	
	TODO: Implement `repeats` for repeating groups.
	TODO: Respect "http://hl7.org/fhir/StructureDefinition/questionnaire-sdc-specialGroup" extensions
	
	- parameter parentRequirements: Requirements from the parent that must be inherited
	- parameter callback: The callback to be called when done; note that even when you get an error, some steps might have successfully been
	                      allocated still, so don't throw everything away just because you receive errors. Likely called on a background
	                      queue.
	*/
	func fulfill(requiring parentRequirements: [ResultRequirement]?, callback: @escaping (([Error]?) -> Void)) {
		var errors = [Error]()
		var promises = [QuestionnairePromiseProto]()
		
		// create an introductory instruction step if we have a title or text
		var intro: ConditionalInstructionStep?
		let (title, text) = group.c3_bestTitleAndText()
		if (nil != title && !title!.isEmpty) || (nil != text && !text!.isEmpty) {
			intro = ConditionalInstructionStep(identifier: group.linkId ?? NSUUID().uuidString, title: title, text: text)
		}
		
		// "enableWhen" requirements
		var requirements = parentRequirements ?? [ResultRequirement]()
		do {
			if let myreqs = try group.c3_enableQuestionnaireElementWhen() {
				requirements.append(contentsOf: myreqs)
			}
		}
		catch let error {
			errors.append(error)
		}
		
		// fulfill our subgroups or (!!) questions
		if let subgroups = group.group {
			for subgroup in subgroups {
				promises.append(QuestionnaireGroupPromise(group: subgroup))
			}
		}
		else if let questions = group.question {
			for question in questions {
				promises.append(QuestionnaireQuestionPromise(question: question))
			}
		}
		
		// fulfill our promises
		if promises.count > 0 {
			let queueGroup = DispatchGroup()
			for promise in promises {
				queueGroup.enter()
				promise.fulfill(requiring: requirements) { berrors in
					if let err = berrors {
						errors.append(contentsOf: err)
					}
					queueGroup.leave()
				}
			}
			
			// on group notify, call the callback on the main queue
			queueGroup.notify(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated)) {
				var steps = promises.filter() { return (nil != $0.steps) }.flatMap() { return $0.steps! }
				if let intr = intro {
					steps.insert(intr, at: 0)
				}
				
				self.steps = steps
				callback(errors.count > 0 ? errors : nil)
			}
		}
		
		// no groups nor questions; maybe still some text
		else {
			if let intro = intro {
				intro.add(requirements: requirements)
				steps = [intro]
			}
			callback(errors.count > 0 ? errors : nil)
		}
	}
	
	
	// MARK: - Printable
	
	/// String representation of the receiver.
	var description: String {
		return String(format: "<QuestionnaireGroupPromise %p>", self as! CVarArg)
	}
}


// MARK: -


extension QuestionnaireGroup {
	
	/**
	Attempts to create a nice title and text from the various fields of the group.
	
	- returns: A tuple of strings for title and text
	*/
	func c3_bestTitleAndText() -> (String?, String?) {
		var ttl = title
		var txt = text
		
		if nil == ttl || nil == txt {
			let cDisplay = concept?.filter() { return nil != $0.display }.map() { return $0.display! }
			let cCodes = concept?.filter() { return nil != $0.code }.map() { return $0.code! }
			
			if nil == ttl {
				ttl = cDisplay?.first ?? cCodes?.first
			}
			else {
				txt = cDisplay?.first ?? cCodes?.first
			}
		}
		
		return (ttl?.c3_stripMultipleSpaces(), txt?.c3_stripMultipleSpaces())
	}
}

