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
public class ConsentTask: NSObject, ORKTask
{
	public let identifier: String
	
	public let contract: Contract
	
	public internal(set) var consentDocument: ORKConsentDocument?
	
	public internal(set) var steps: [ORKStep]?
	
	public internal(set) var sharingStep: ORKStep?
	
	public var teamName: String? {
		return contract.authority?.first?.resolved(Organization)?.name
	}
	
	public init(identifier: String, contract: Contract) {
		self.identifier = identifier
		self.contract = contract
		super.init()
	}
	
	func prepareWithOptions(options: ConsentTaskOptions) {
		consentDocument = consentDocument ?? contract.chip_asConsentDocument()
		if let doc = consentDocument {
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
						
						let team = (nil != teamName) ? "the \(teamName!)" : options.shareTeamName
						let sharing = ORKConsentSharingStep(identifier: "sharing",
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
					fatalError("You MUST adjust `sharingOptions.shareMoreInfoDocument` to the name of an HTML document (without extension) that is included in the app bundle. It's set to «\(more)» but this file could not be found in the bundle.")
				}
			}
			
			// TODO: quiz?
			
			// consent review step
			let signature = ORKConsentSignature(forPersonWithTitle: "Participant".localized, dateFormatString: nil, identifier: "participant")
			doc.addSignature(signature)
			let review = ORKConsentReviewStep(identifier: "reviewStep", signature: signature, inDocument: doc)		// "reviewStep" for compatibility with AppCore
			review.reasonForConsent = options.reasonForConsent
			steps.append(review)
			
			self.steps = steps
		}
		else {
			chip_warn("Failed to create a consent document from Contract")
		}
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

