//
//  QuestionnaireTests.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 5/13/16.
//  Copyright © 2016 Boston Children's Hospital. All rights reserved.
//

import XCTest
@testable import C3PRO
import SMART
import ResearchKit


class QuestionnaireChoiceTests: XCTestCase {
	
	func testContainedValueSet() {
		do {
			let bundle = Bundle(for: type(of: self))
			let questionnaire = try bundle.fhir_bundledResource("Questionnaire_ValueSet-contained", type: Questionnaire.self)
			let controller = QuestionnaireController(questionnaire: questionnaire)
			
			let exp = self.expectation(description: "Questionnaire preparation")
			controller.prepareQuestionnaire() { task, error in
				XCTAssertNil(error)
				XCTAssertNotNil(task, "Must succeed in building a task")
				XCTAssertEqual("ValueSet-contained", task?.identifier)
				
				// step 1 is the ValueSet-referencing step
				let step1 = task?.step!(withIdentifier: "choice-valueSet") as? ConditionalQuestionStep
				XCTAssertNotNil(step1, "Should have found step 1 and made it a conditional question step")
				XCTAssertEqual(step1?.title, "Limited simple choice?")
				XCTAssertTrue(step1?.answerFormat is ORKTextChoiceAnswerFormat)
				let choices = (step1?.answerFormat as? ORKTextChoiceAnswerFormat)?.textChoices
				XCTAssertNotNil(choices)
				XCTAssertEqual(3, choices?.count)
				let choice1 = choices?[0]
				XCTAssertEqual(choice1?.text, "Yes, limited a lot!")
				XCTAssertEqual(choice1?.value.description, "http://sf-36.org/fhir/StructureDefinition/answers-3-levels 1")
				let choice2 = choices?[1]
				XCTAssertEqual(choice2?.text, "Yes, limited a little!")
				XCTAssertEqual(choice2?.value.description, "http://sf-36.org/fhir/StructureDefinition/answers-3-levels 2")
				let choice3 = choices?[2]
				XCTAssertEqual(choice3?.text, "No, not limited at all!")
				XCTAssertEqual(choice3?.value.description, "http://sf-36.org/fhir/StructureDefinition/answers-3-levels 3")
				
				let step2 = task?.step!(withIdentifier: "choice-boolean") as? ConditionalQuestionStep
				XCTAssertNotNil(step2, "Should have found step 2 and made it a conditional question step")
				XCTAssertEqual(step2?.text, "And this is additional, very useful, instructional text.")
				XCTAssertTrue(step2?.answerFormat is ORKBooleanAnswerFormat)
				
				let step3 = task?.step!(withIdentifier: "display-step") as? ConditionalInstructionStep
				XCTAssertNotNil(step3, "Should have found step 3 and made it an instruction step")
				XCTAssertEqual(step3?.text, "Pressing “Done” will complete this survey!")
				
				exp.fulfill()
			}
			self.waitForExpectations(timeout: 4, handler: nil)
		}
		catch let error {
			XCTAssertTrue(false, "Failed: \(error)")
		}
	}
	
	func testRelativeValueSet() {
		let local = BundledFileServer()
		let exp = self.expectation(description: "Questionnaire preparation")
		
		// read questionnaire
		Questionnaire.read("ValueSet-relative", server: local) { resource, error in
			XCTAssertNil(error, "Not expecting an error but got \(error)")
			guard let questionnaire = resource as? Questionnaire else {
				XCTAssertTrue(false, "Not a questionnaire: \(resource)")
				exp.fulfill()
				return
			}
			
			// prepare questionnaire
			let controller = QuestionnaireController(questionnaire: questionnaire)
			controller.prepareQuestionnaire() { task, error in
				XCTAssertNil(error)
				XCTAssertNotNil(task, "Must succeed in building a task")
				XCTAssertEqual("ValueSet-relative", task?.identifier)
				
				// step 1 is the ValueSet-referencing step
				let step1 = task?.step!(withIdentifier: "choice-valueSet") as? ConditionalQuestionStep
				XCTAssertNotNil(step1, "Should have found step 1 and made it a conditional question step")
				XCTAssertEqual(step1?.title, "A Limited Choice?")
				XCTAssertTrue(step1?.answerFormat is ORKTextChoiceAnswerFormat)
				let choices = (step1?.answerFormat as? ORKTextChoiceAnswerFormat)?.textChoices
				XCTAssertNotNil(choices)
				XCTAssertEqual(3, choices?.count)
				let choice1 = choices?[0]
				XCTAssertEqual(choice1?.text, "Yes, limited a lot")
				XCTAssertEqual(choice1?.value.description, "http://sf-36.org/fhir/StructureDefinition/answers-3-levels 1")
				let choice2 = choices?[1]
				XCTAssertEqual(choice2?.text, "Yes, limited a little")
				XCTAssertEqual(choice2?.value.description, "http://sf-36.org/fhir/StructureDefinition/answers-3-levels 2")
				let choice3 = choices?[2]
				XCTAssertEqual(choice3?.text, "No, not limited at all")
				XCTAssertEqual(choice3?.value.description, "http://sf-36.org/fhir/StructureDefinition/answers-3-levels 3")
				
				let step2 = task?.step!(withIdentifier: "choice-boolean") as? ConditionalQuestionStep
				XCTAssertNotNil(step2, "Should have found step 2 and made it a conditional question step")
				XCTAssertEqual(step2?.text, "And it has this additional instructional text.")
				XCTAssertTrue(step2?.answerFormat is ORKBooleanAnswerFormat)
				
				let step3 = task?.step!(withIdentifier: "display-step") as? ConditionalInstructionStep
				XCTAssertNotNil(step3, "Should have found step 3 and made it an instruction step")
				XCTAssertEqual(step3?.text, "Pressing “Done” will complete this survey.")
				
				exp.fulfill()
			}
		}
		self.waitForExpectations(timeout: 4, handler: nil)
	}
	
	func testResponseDeduplication() {
		do {
			let bundle = Bundle(for: type(of: self))
			let response = try bundle.fhir_bundledResource("QuestionnaireResponse_main.duplicates", type: QuestionnaireResponse.self)
			XCTAssertEqual(10, response.item?.count ?? 0)
			XCTAssertEqual("meds", response.item?[0].linkId)
			XCTAssertEqual("meds", response.item?[1].linkId)
			XCTAssertEqual("SF36", response.item?[2].linkId)
			XCTAssertEqual("meds", response.item?[3].linkId)
			XCTAssertEqual("meds", response.item?[4].linkId)
			XCTAssertEqual("SF36", response.item?[5].linkId)
			XCTAssertEqual("SF36", response.item?[6].linkId)
			XCTAssertEqual("workLimitationsPast7Days", response.item?[7].linkId)
			XCTAssertEqual("workLimitationsPast7Days", response.item?[8].linkId)
			XCTAssertEqual("deviceCarryFrequency", response.item?[9].linkId)
			
			XCTAssertEqual("roleLimitations", response.item?[2].item?[0].linkId)
			XCTAssertEqual("accomplished-less", response.item?[5].item?[0].item?[0].linkId)
			XCTAssertEqual("limited-other", response.item?[6].item?[0].item?[0].linkId)
			
			// deduplicate
			response.deduplicateItemsByLinkId()
			XCTAssertEqual(4, response.item?.count ?? 0)
			XCTAssertEqual("meds", response.item?[0].linkId)
			XCTAssertEqual("SF36", response.item?[1].linkId)
			XCTAssertEqual("workLimitationsPast7Days", response.item?[2].linkId)
			XCTAssertEqual("deviceCarryFrequency", response.item?[3].linkId)
			
			XCTAssertEqual("roleLimitations", response.item?[1].item?[0].linkId)
			XCTAssertEqual("accomplished-less", response.item?[1].item?[0].item?[1].linkId)
			XCTAssertEqual("limited-other", response.item?[1].item?[0].item?[2].linkId)
		}
		catch {
			XCTAssertTrue(false, "Failed: \(error)")
		}
	}
}


/**
Server implementation that attempts to load resources from the bundle by constructing the filename "{ resource type }/{ resource id }.json"
and requesting this resource from the bundle. This class should probably only be used for debugging and unit testing.
*/
class BundledFileServer: Server {
	
	init() {
		super.init(baseURL: URL(string: "http://localhost")!)
	}
	
	required init(baseURL base: URL, auth: OAuth2JSON?) {
		super.init(baseURL: base, auth: auth)
	}
	
	override func perform(request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionTask? {
		let parts = request.url?.path.components(separatedBy: "/").filter() { $0.characters.count > 0 }
		guard let localName = parts?.joined(separator: "_") else {
			completionHandler(nil, nil, FHIRError.requestNotSent("Unable to infer local filename from request URL path \(request.url?.description ?? "nil")"))
			return nil
		}
		guard let localURL = Bundle(for: type(of: self)).url(forResource: localName, withExtension: "json") else {
			completionHandler(nil, nil, FHIRError.requestNotSent("No bundled resource with name «\(localName).json» found"))
			return nil
		}
		do {
			let data = try Data(contentsOf: localURL)
			completionHandler(data, URLResponse(), nil)
		}
		catch let error {
			completionHandler(nil, nil, FHIRError.requestNotSent("Error: \(error)"))
		}
		return nil
	}
}

