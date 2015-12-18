//
//  ConsentTask.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 8/14/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import ResearchKit
import SMART


/**
	An ORKTask-implementing class that can be fed to an ORKTaskViewController to guide a user through consenting.

	Data to be shown is read from the `Contract` resource, which will be converted into an `ORKConsentDocument`.
 */
public class ConsentTask: NSObject, ORKTask {
    
	public let identifier: String
	
	public let contract: Contract
	
	public internal(set) var consentDocument: ORKConsentDocument?
	
	public internal(set) var steps: [ORKStep]?
	
	/// The identifier of the review step.
	public internal(set) var reviewStepName = "reviewStep"
	
	/// The identifier for the participant's signature in results of the review step.
	public internal(set) var participantSignatureName = "participant"
	
	/// The sharing step.
	public internal(set) var sharingStep: ORKStep?
	
	/// The identifier of the sharing step.
	public internal(set) var sharingStepName = "sharing"
	
	/// The identifier of the passcode/PIN step.
	public internal(set) var pinStepName = "passcode"
	
	public var teamName: String? {
		return contract.authority?.first?.resolved(Organization)?.name
	}
	
	public init(identifier: String, contract: Contract) {
		self.identifier = identifier
		self.contract = contract
		super.init()
	}
	
	func prepareWithOptions(options: ConsentTaskOptions) throws {
		if nil == consentDocument {
			consentDocument = try contract.chip_asConsentDocument()
		}
		let doc = consentDocument!
		let bundle = NSBundle.mainBundle()
		
		// full consent review document (override, if nil will automatically combine all consent sections)
		if let reviewDoc = options.reviewConsentDocument {
			if let url = bundle.URLForResource(reviewDoc, withExtension: "html") ?? bundle.URLForResource(reviewDoc, withExtension: "html", subdirectory: "HTMLContent") {
				do {
					doc.htmlReviewContent = try NSString(contentsOfURL: url, encoding: NSUTF8StringEncoding) as String
				}
				catch let error {
					chip_warn("Failed to read contents of file named «\(reviewDoc).html»: \(error)")
				}
			}
			else {
				chip_warn("The bundle does not contain a file named «\(reviewDoc).html», ignoring")
			}
		}
		
		// visual step for all consent sections
		var steps = [ORKStep]()
		let visual = ORKVisualConsentStep(identifier: "visual", document: doc)
		steps.append(visual)
		
		// sharing step
		if options.askForSharing {
			let more = options.shareMoreInfoDocument
			if let url = bundle.URLForResource(more, withExtension: "html") ?? bundle.URLForResource(more, withExtension: "html", subdirectory: "HTMLContent") {
				do {
					let learnMore = try NSString(contentsOfURL: url, encoding: NSUTF8StringEncoding) as String
					
					let team = (nil != teamName) ? "The \(teamName!)" : options.shareTeamName
					let sharing = ORKConsentSharingStep(identifier: sharingStepName,
						investigatorShortDescription: team,
						investigatorLongDescription: team,
						localizedLearnMoreHTMLContent: learnMore)
					steps.append(sharing)
					sharingStep = sharing
				}
				catch let error {
					chip_warn("Failed to read learn more content from «\(url)»: \(error)")
				}
			}
			else {
				fatalError("You MUST adjust `options.shareMoreInfoDocument` to the name of an HTML document (without extension) that is included in the app bundle. It's set to «\(more)» but this file could not be found in the bundle.\nAlternatively you can set `options.askForSharing` to false to not show the sharing step.")
			}
		}
		
		// TODO: quiz?
		
		// consent review step
		let signature = ORKConsentSignature(forPersonWithTitle: "Participant".localized, dateFormatString: nil, identifier: participantSignatureName)
		doc.addSignature(signature)
		let review = ORKConsentReviewStep(identifier: reviewStepName, signature: signature, inDocument: doc)
		review.reasonForConsent = options.reasonForConsent
		steps.append(review)
		
		// set passcode step
        if options.askToCreatePasscode {
            let instruction = ORKInstructionStep(identifier: "passcodeInstruction")
            instruction.title = NSLocalizedString("Passcode", comment: "")
            instruction.text = NSLocalizedString("You will now be asked to create a passcode.\n\nThis protects your data from unauthorized access should you hand your phone to a friend.", comment: "Text shown before prompting to create a passcode")
            steps.append(instruction)
            steps.append(ORKPasscodeStep(identifier: pinStepName))
        }
        
		self.steps = steps
	}
	
	
	// MARK: - ORKTask Protocol
	
	public func stepAfterStep(step: ORKStep?, withResult result: ORKTaskResult) -> ORKStep? {
		if let step = step, let steps = steps {
			var next = false
			for hasStep in steps {
				if next {
					return hasStep
				}
				if hasStep == step {
					next = true
				}
			}
			return nil
		}
		return steps?.first
	}
	
	public func stepBeforeStep(step: ORKStep?, withResult result: ORKTaskResult) -> ORKStep? {
		if let step = step, let steps = steps {
			var prev = false
			for hasStep in steps.reverse() {
				if prev {
					return hasStep
				}
				if hasStep == step {
					prev = true
				}
			}
			return nil
		}
		return steps?.last
	}
}

