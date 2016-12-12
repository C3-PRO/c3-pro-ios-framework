//
//  ConsentTask.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 8/14/15.
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

import ResearchKit
import SMART


/**
An ORKTask-implementing class that can be fed to an ORKTaskViewController to guide a user through consenting.

Data to be shown is read from the `Contract` resource, which will be converted into an `ORKConsentDocument`.
*/
public class ConsentTask: ORKOrderedTask {
    
	public let contract: Contract
	
	public let consentDocument: ORKConsentDocument
	
	/// The identifier of the review step.
	public static let reviewStepName = "reviewStep"
	
	/// The identifier for the participant's signature in results of the review step.
	public static let participantSignatureName = "participant"
	
	/// The sharing step.
	public var sharingStep: ORKStep? {
		return step(withIdentifier: type(of: self).sharingStepName)
	}
	
	/// The identifier of the sharing step.
	public static let sharingStepName = "sharing"
	
	/// The identifier of the passcode/PIN step.
	public static let pinStepName = "passcode"
	
	public var teamName: String? {
		return contract.authority?.first?.resolved(Organization.self)?.name?.string
	}
	
	/**
	Designated initializer. Throws exceptions when step creation from the given contract fails.
	
	The fact that we need to initialize all stored properties before throwing is bonkers, fix it Swift!!
	
	- parameter identifier: The identifier for the task
	- parameter contract: The Contract resource to use to create steps from
	- parameter options: Options for the consenting task
	*/
	public init(identifier: String, contract: Contract, options: ConsentTaskOptions) throws {
		self.contract = contract
		do {
			let prepped = try type(of: self).stepsAndConsent(from: contract, options: options)
			consentDocument = prepped.consent
			super.init(identifier: identifier, steps: prepped.steps)
		}
		catch let error {
			consentDocument = ORKConsentDocument()
			super.init(identifier: identifier, steps: nil)
			throw error
		}
	}
	
	public required init(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	
	// MARK: - Task Preparation and Evaluation
	
	/**
	Prepare the task with the given options, from the given contract.
	
	- parameter from:    The contract to use to create a) a consent document and b) all the steps to perform
	- parameter options: The options to consider when creating the task
	- returns:           A named tuple returning the ORKConsentDocument and an array of ORKSteps
	*/
	class func stepsAndConsent(from contract: Contract, options: ConsentTaskOptions) throws -> (consent: ORKConsentDocument, steps: [ORKStep]) {
		let consent = try contract.c3_asConsentDocument()
		let bundle = Bundle.main
		
		// full consent review document (override, if nil will automatically combine all consent sections)
		if let reviewDoc = options.reviewConsentDocument {
			if let url = bundle.url(forResource: reviewDoc, withExtension: "html") ?? bundle.url(forResource: reviewDoc, withExtension: "html", subdirectory: "HTMLContent") {
				do {
					consent.htmlReviewContent = try String(contentsOf: url, encoding: String.Encoding.utf8)
				}
				catch let error {
					c3_warn("Failed to read contents of file named «\(reviewDoc).html»: \(error)")
				}
			}
			else {
				c3_warn("The bundle does not contain a file named «\(reviewDoc).html», ignoring")
			}
		}
		
		// visual step for all consent sections
		var steps = [ORKStep]()
		let visual = ORKVisualConsentStep(identifier: "visual", document: consent)
		steps.append(visual)
		
		// sharing step
		if options.askForSharing {
			let more = options.shareMoreInfoDocument
			if let url = bundle.url(forResource: more, withExtension: "html") ?? bundle.url(forResource: more, withExtension: "html", subdirectory: "HTMLContent") {
				do {
					let learnMore = try String(contentsOf: url, encoding: String.Encoding.utf8)
					let teamName = contract.authority?.first?.resolved(Organization.self)?.name
					let team = (nil != teamName) ? "The \(teamName!)" : options.shareTeamName
					let sharing = ORKConsentSharingStep(identifier: sharingStepName,
						investigatorShortDescription: team,
						investigatorLongDescription: team,
						localizedLearnMoreHTMLContent: learnMore)
					steps.append(sharing)
				}
				catch let error {
					c3_warn("Failed to read learn more content from «\(url)»: \(error)")
				}
			}
			else {
				fatalError("You MUST adjust `options.shareMoreInfoDocument` to the name of an HTML document (without extension) that is included in the app bundle. It's set to «\(more)» but this file could not be found in the bundle.\nAlternatively you can set `options.askForSharing` to false to not show the sharing step.")
			}
		}
		
		// TODO: quiz?
		
		// consent review step
		let signature = ORKConsentSignature(forPersonWithTitle: "Participant".c3_localized, dateFormatString: nil, identifier: participantSignatureName)
		consent.addSignature(signature)
		let review = ORKConsentReviewStep(identifier: reviewStepName, signature: signature, in: consent)
		review.reasonForConsent = options.reasonForConsent
		steps.append(review)
		
		// set passcode step
        if options.askToCreatePasscode {
            let instruction = ORKInstructionStep(identifier: "passcodeInstruction")
            instruction.title = "Passcode".c3_localized
            instruction.text = "You will now be asked to create a passcode.\n\nThis protects your data from unauthorized access should you hand your phone to a friend.".c3_localized
            steps.append(instruction)
            steps.append(ORKPasscodeStep(identifier: pinStepName))
        }
		
		// request permissions step
		if let services = options.wantedServicePermissions, !services.isEmpty {
			let instruction = ORKInstructionStep(identifier: "permissionsInstruction")
			instruction.title = "Permissions".c3_localized
			instruction.text = "You will now be asked to grant the app access to certain system features. This allows us to show reminders and read health data from HealthKit, amongst others.".c3_localized
			steps.append(instruction)
			steps.append(SystemPermissionStep(identifier: "permissions", permissions: services))
		}
		
		return (consent: consent, steps: steps)
	}
	
	/**
	Retrieves the signature result (identifier `participantSignatureName`) of the consent signature step (identifier `reviewStepName`).
	
	- parameter from: The result of the consent task
	- returns:        The consent signature result, if the step has been completed yet
	*/
	public func signatureResult(from taskResult: ORKTaskResult) -> ORKConsentSignatureResult? {
		return taskResult.stepResult(forStepIdentifier: type(of: self).reviewStepName)?
			.result(forIdentifier: type(of: self).participantSignatureName) as? ORKConsentSignatureResult
	}
	
	/**
	Extracts the consent signature from the signature result, if it's there. If this method returns a signature, the patient has agreed to
	the consent and signed on screen.
	
	- parameter in: The consent signature result to inspect
	- returns:      The consent signature, if it's there
	*/
	public func signature(in result: ORKConsentSignatureResult) -> ORKConsentSignature? {
		if let signature = result.signature, nil != signature.signatureImage {
			return signature
		}
		return nil
	}
	
	/**
	Retrieve the consent signature found in the task result, if it's there, indicating the user consented.
	
	- parameter from: The result of the consent task to inspect
	- returns:        The consent signature, if the user consented and signed
	*/
	public func signature(from taskResult: ORKTaskResult) -> ORKConsentSignature? {
		guard let result = signatureResult(from: taskResult) else {
			return nil
		}
		return signature(in: result)
	}
	
	
	// MARK: - Task Navigation
	
	override public func step(after step: ORKStep?, with result: ORKTaskResult) -> ORKStep? {
		guard let step = step else {
			return steps.first
		}
		
		// declined consent, stop here
		if type(of: self).reviewStepName == step.identifier && nil == signature(from: result) {
			return nil
		}
		return super.step(after: step, with: result)
	}
}

