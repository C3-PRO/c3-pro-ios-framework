//
//  ConsentController.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 5/20/15.
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
Callback used when signing the consent. Provides `contract`, `patient` and an optional `error`.
*/
public typealias ConsentSigningCallback = ((contract: Contract, patient: Patient, error: Error?) -> Void)

/// Name of notification sent when the user completes and agrees to consent.
public let C3UserDidConsentNotification = "C3UserDidConsentNotification"

/// Name of notification sent when the user cancels or declines to consent.
public let C3UserDidDeclineConsentNotification = "C3UserDidDeclineConsentNotification"

/// User info dictionary key containing the consenting result in a `C3UserDidConsentNotification` notification.
public let C3ConsentResultKey = "consent-result"


/**
Struct to hold various options for consenting.

There are default values to all properties, so you only need to override what you want to change.
*/
public struct ConsentTaskOptions {
	
	/// Whether or not the participant should be asked if she wants to share her data worldwide or only with the study researchers.
	public var askForSharing = true
	
	var shareTeamName = "the research team".c3_localized
	
	/// Name of a bundled HTML file (without extension) that contains more information about data sharing.
	public var shareMoreInfoDocument = "Consent_sharing"
	
	/// Optional: name of a bundled HTML file (without extension) that contains the full consent document for review.
	public var reviewConsentDocument: String? = nil
	
	/// Shown when the user taps agree and she needs to confirm that she is in agreement.
	public var reasonForConsent = "By agreeing you confirm that you read the consent and that you wish to take part in this research study.".c3_localized

	/// Whether the user should be prompted to create a passcode/PIN after consenting.
	public var askToCreatePasscode = true

	/// Which system permissions the user should be asked to grant during consenting.
	public var wantedServicePermissions: [SystemService]? = nil


	public init() {  }
}


/**
The consent controller helps using a FHIR `Contract` resource to capture consent.

The controller can read a bundled `Contract` resource and return view controllers that can be used for eligibility checking
(use `eligibilityStatusViewController(config:onStartConsent:)`) and/or consenting (use `consentViewController(onUserDidConsent:onUserDidDecline:)`).
*/
public class ConsentController {
	
	/// The contract to be signed; if nil when signing, a new instance will be created.
	public final var contract: Contract?
	
	/// Options to consider for the consenting task.
	public var options = ConsentTaskOptions()
	
	var deidentifier: DeIdentifier?
	
	var consentDelegate: ConsentTaskViewControllerDelegate?
	
	/// The callback to call when the user consents.
	var onUserDidConsent: ((controller: ORKTaskViewController, result: ConsentResult) -> Void)?
	
	/// The callback to call when the user declines (or aborts) consenting.
	var onUserDidDeclineConsent: ((controller: ORKTaskViewController) -> Void)?
	
	/// Whether a PIN was present before; if not and consenting is cancelled, the PIN is cleared.
	internal private(set) var pinPresentBefore = false
	
	/// The logger to use, if any.
	public var logger: OAuth2Logger?
	
	
	/**
	Designated initializer.
	
	You can optionally supply the name of a bundled JSON file (without extension) that represents a serialized FHIR Contract resource. This
	uses the Bundle containing the C3PRO modules, so if you're calling the method from a different bundle (e.g. when unit testing), don't
	provide a filename and assign `contract` manually by using `fhir_bundledResource(name:subdirectory:type:)`.
	
	- parameter bundledContract: The filename (without ".json" of the Contract resource to read)
	- parameter subdirectory:    The subdirectory, if any, the Contract resource is located in
	*/
	public init(bundledContract: String? = nil, subdirectory: String? = nil) throws {
		if let name = bundledContract {
			let bundle = Bundle(for: self.dynamicType)
			contract = try bundle.fhir_bundledResource(name, subdirectory: subdirectory, type: Contract.self)
		}
	}
	
	
	// MARK: - Eligibility
	
	/**
	Instantiates a controller prompting the user to press “Start Eligibility”. Pressing that button pushes an EligibilityCheckViewController
	onto the navigation stack, which carries the actual eligibility criteria.
	
	- parameter config: An optional `StudyIntroConfiguration` instance that carries custom eligible/ineligible texts
	- parameter onStartConsent: The block to execute when all eligibility criteria are met and the participant wants to start consent. Leave
	                            nil to automatically present (and dismiss) the consent task view controller that will be returned by
	                            `consentViewController()`.
	*/
	public func eligibilityStatusViewController(_ config: StudyIntroConfiguration? = nil, onStartConsent: ((viewController: EligibilityCheckViewController) -> Void)? = nil) -> EligibilityStatusViewController {
		let check = EligibilityStatusViewController()
		check.title = "Eligibility".c3_localized
		check.titleText = "Let's see if you may take part in this study".c3_localized
		check.subText = "Tap the button below to begin the eligibility process".c3_localized
		check.actionButtonTitle = "Start Eligibility".c3_localized
		
		// the actual eligibility check view controller; configure to present on check's navigation controller if no block is provided
		let elig = EligibilityCheckViewController(style: .grouped)
		if let onStartConsent = onStartConsent {
			elig.onStartConsent = onStartConsent
		}
		else {
			elig.onStartConsent = { viewController in
				if let navi = viewController.navigationController {
					do {
						let consent = try self.consentViewController(
							onUserDidConsent: { controller, result in
								navi.dismiss(animated: true, completion: nil)
							},
							onUserDidDecline: { controller in
								navi.popToRootViewController(animated: false)
								navi.dismiss(animated: true, completion: nil)
							}
						)
						navi.present(consent, animated: true, completion: nil)
					}
					catch let error {
						c3_warn("failed to create consent view controller: \(error)")
					}
				}
				else {
					c3_warn("must embed eligibility status view controller in a navigation controller")
				}
			}
		}
		
		// apply configurations
		if let config = config {
			check.titleText = config.eligibleLetsCheckMessage ?? check.titleText
			elig.eligibleTitle = config.eligibleTitle ?? elig.eligibleTitle
			elig.eligibleMessage = config.eligibleMessage ?? elig.eligibleMessage
			elig.ineligibleMessage = config.ineligibleMessage ?? elig.ineligibleMessage
		}
		
		// eligibility requirements
		check.waitingForAction = true
		eligibilityRequirements { requirements in
			DispatchQueue.main.async {
				elig.requirements = requirements
				check.waitingForAction = false
			}
		}
		
		check.onActionButtonTap = { controller in
			if let navi = controller.navigationController {
				navi.pushViewController(elig, animated: true)
			}
			else {
				c3_warn("must embed eligibility status view controller in a navigation controller")
			}
		}
		return check
	}
	
	/**
	Resolves the contract's first subject to a Group. This Group is expected to have characteristics that represent eligibility criteria.
	
	- parameter callback: The callback that is called when the group is resolved (or resolution fails); may be on any thread but may be
	                      called immediately in case of embedded resources.
	*/
	public func eligibilityRequirements(callback: ((requirements: [EligibilityRequirement]?) -> Void)) {
		if let group = contract?.subject?.first {
			group.resolve(Group.self) { group in
				if let characteristics = group?.characteristic {
					var criteria = [EligibilityRequirement]()
					for characteristic in characteristics {
						if let req = characteristic.c3_asEligibilityRequirement() {
							criteria.append(req)
						}
						else {
							c3_warn("this characteristic failed to return an eligibility requirement: \(characteristic.asJSON())")
						}
					}
					callback(requirements: criteria)
				}
				else {
					c3_warn("failed to resolve the contract's subject group or there are no characteristics, hence no eligibility criteria")
					callback(requirements: nil)
				}
			}
		}
		else {
			logger?.debug("C3-PRO", msg: "the contract does not have a subject, hence no eligibility criteria")
			callback(requirements: nil)
		}
	}
	
	
	// MARK: - Consenting
	
	/**
	Creates the consent task from the receiver's contract.
	
	- throws: `C3Error.ConsentContractNotPresent` when the contract is not present
	- returns: A `ConsentTask` that can be presented using ResearchKit
	*/
	public func createConsentTask() throws -> ConsentTask {
		guard let contract = contract else {
			throw C3Error.consentContractNotPresent
		}
		return try ConsentTask(identifier: UUID().uuidString, contract: contract, options: options)
	}
	
	/**
	A consent view controller, preconfigured with the consenting task, that can be presented to have the user go through consent.
	
	You are given two blocks, one of them will be called when the user finishes or exits consenting, never both. They are deallocated after
	either has been called.
	
	- parameter onUserDidConsent: Block executed when the user completes and agrees to consent
	- parameter onUserDidDecline: Block executed when the user cancels or actively declines consent
	- throws: Re-throws from `createConsentTask()`
	*/
	public func consentViewController(onUserDidConsent onConsent: ((controller: ORKTaskViewController, result: ConsentResult) -> Void),
		onUserDidDecline: ((controller: ORKTaskViewController) -> Void)) throws -> ORKTaskViewController {
		
		if nil != onUserDidConsent {
			c3_warn("a `onUserDidConsent` block is already set on \(self), are you already presenting a consent view controller? This might have unintended consequences.")
		}
		onUserDidConsent = onConsent
		onUserDidDeclineConsent = onUserDidDecline
		consentDelegate = ConsentTaskViewControllerDelegate(controller: self)
		
		let task = try createConsentTask()
		let consentVC = ORKTaskViewController(task: task, taskRun: UUID())
		consentVC.delegate = consentDelegate!
		pinPresentBefore = ORKPasscodeViewController.isPasscodeStoredInKeychain()
		
		return consentVC
	}
	
	func userDidFinishConsent(_ taskViewController: ORKTaskViewController, reason: ORKTaskViewControllerFinishReason) {
		if let task = taskViewController.task as? ConsentTask {
            if .completed == reason {
				let taskResult = taskViewController.result
				
                // if we have a signature in the signature result, we're consented: create PDF and call the callbacks
				if let signatureResult = task.signatureResult(from: taskResult), let signature = task.signature(in: signatureResult) {
                    let result = ConsentResult(signature: signature)
					sign(consentDocument: task.consentDocument, with: signatureResult)                    
                    
                    // sharing choice
                    if let sharingResult = taskResult.stepResult(forStepIdentifier: task.dynamicType.sharingStepName),
                        let sharing = sharingResult.results?.first as? ORKChoiceQuestionResult,
                        let choice = sharing.choiceAnswers?.first as? Int {
                            result.shareWidely = (0 == choice)			// the first option, index 0, is "share worldwide"
                    }
                    else if options.askForSharing {
                        c3_warn("the sharing step has not returned the expected result, despite `options.askForSharing` being set to true")
                    }
                    
                    userDidConsent(taskViewController, result: result)
                }
                else {
                    userDidDeclineConsent(taskViewController)
                }
            }
			else if .discarded == reason {
				userDidDeclineConsent(taskViewController)
			}
			else {
				userDidDeclineConsent(taskViewController)
			}
		}
		else {
			c3_warn("user finished a consent that did not have a `ConsentTask` task; cannot handle, calling decline callback")
			userDidDeclineConsent(taskViewController)
		}
		
		onUserDidConsent = nil
		onUserDidDeclineConsent = nil
		consentDelegate = nil
	}
	
	/**
	Called when the user successfully completes the consent task and agrees to all the things.
	*/
	public func userDidConsent(_ taskViewController: ORKTaskViewController, result: ConsentResult) {
		if let exec = onUserDidConsent {
			exec(controller: taskViewController, result: result)
		}
		let userInfo = [C3ConsentResultKey: result]
		NotificationCenter.default.post(name: Notification.Name(rawValue: C3UserDidConsentNotification), object: self, userInfo: userInfo)
	}
	
	/**
	Called when the user aborts consenting or actively declines consent.
	*/
	public func userDidDeclineConsent(_ taskViewController: ORKTaskViewController) {
		if !pinPresentBefore {
			ORKPasscodeViewController.removePasscodeFromKeychain()
		}
		if let exec = onUserDidDeclineConsent {
			exec(controller: taskViewController)
		}
		NotificationCenter.default.post(name: Notification.Name(rawValue: C3UserDidDeclineConsentNotification), object: self)
	}
	
	
	// MARK: - Consent Signing
	
	/**
	Instantiates a new "Contract" resource and fills the properties to represent a consent signed by a participant referencing the given
	patient.
	
	- parameter with:   The Patient resource to use to sign
	- parameter result: The date at which the contract was signed
	- throws:           `C3Error` when referencing the patient resource fails
	- returns:          A signed Contract resource, usually the receiver's `contract` ivar
	*/
	public func signContract(with patient: Patient, result: ConsentResult) throws -> Contract {
		if nil == patient.id {
			patient.id = UUID().uuidString
		}
		do {
			let reference = try patient.asRelativeReference()
			let myContract = contract ?? Contract(json: nil)
			let date = result.consentDate ?? Date()
			
			// applicable period
			let period = Period(json: nil)
			period.start = date.fhir_asDateTime()
			myContract.applies = period
			
			// the participant/patient is the signer/consenter
			let signer = ContractSigner(json: nil)
			signer.type = Coding(json: nil)
			signer.type!.display = "consenter"
			signer.type!.code = "CONSENTER"
			signer.type!.system = URL(string: "http://hl7.org/fhir/ValueSet/contract-signer-type")
			signer.party = reference
			
			// extension to capture sharing intent
			if let shareWidely = result.shareWidely {
				let share = Extension(url: URL(string: "http://fhir-registry.smarthealthit.org/StructureDefinition/consents-to-data-sharing")!)
				share.valueBoolean = shareWidely
				signer.extension_fhir = [share]
			}
			
			let signatureCode = Coding(json: nil)
			signatureCode.system = URL(string: "http://hl7.org/fhir/ValueSet/signature-type")
			signatureCode.code = "1.2.840.10065.1.12.1.7"
			signatureCode.display = "Consent Signature"
			
			let signature = Signature(json: nil)
			signature.type = [signatureCode]
			signature.when = date.fhir_asInstant()
			signature.whoReference = reference
			
			signer.signature = [signature]
			myContract.signer = [signer]
			
			return myContract
		}
		catch let error {
			throw C3Error.consentNoPatientReference(error)
		}
	}
	
	/**
	Reverse geocodes and de-identifies the patient, then uses the new Patient resource to sign the contract.
	
	- parameter with:     The Patient resource to use to sign
	- parameter result:   The result of the consenting task
	- parameter callback: The callback to call when done or when signing failed
	- throws:             `C3Error` when referencing the patient resource fails
	- returns:            A signed Contract resource, usually the receiver's `contract` ivar
	*/
	public func deIdentifyAndSignContract(with patient: Patient, result: ConsentResult, callback: ConsentSigningCallback) {
		deidentifier = DeIdentifier()
		deidentifier!.hipaaCompliantPatient(patient: patient) { patient in
			self.deidentifier = nil
			
			do {
				let contract = try self.signContract(with: patient, result: result)
				callback(contract: contract, patient: patient, error: nil)
			}
			catch let error {
				c3_warn("\(error)")
				callback(contract: Contract(json: nil), patient: patient, error: error)
			}
		}
	}
	
	
	// MARK: - Consent PDF
	
	/**
	Asynchronously generates a consent PDF at `self.dynamicType.signedConsentPDFURL()`, containing the given signature.
	
	- parameter consentDocument: The consent document to sign, usually the one used in our consent task
	- parameter with:            The signature to apply to the document
	*/
	func sign(consentDocument document: ORKConsentDocument, with signature: ORKConsentSignatureResult) {
		logger?.debug("C3-PRO", msg: "Writing consent PDF")
		signature.apply(to: document)
		document.makePDF() { data, error in
			if let data = data, let pdfURL = self.dynamicType.signedConsentPDFURL() {
				do {
					try data.write(to: pdfURL, options: .atomic)
					self.logger?.debug("C3-PRO", msg: "Consent PDF written to \(pdfURL)")
				}
				catch let error {
					c3_warn("failed to write consent PDF: \(error)")
				}
			}
			else {
				c3_warn("failed to write consent PDF: \(error?.localizedDescription ?? (nil == data ? "no data" : "no url"))")
			}
		}
	}
	
	/**
	URL to the user-signed contract PDF.
	
	- parameter mustExist: If `true` will return nil if no file exists at the expected file URL. If `false` will return the desired URL,
	                       which is pretty sure to return non-nil, so use that exclamation mark!
	*/
	public class func signedConsentPDFURL(mustExist: Bool = false) -> URL? {
		do {
			let base = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
			let url = base.appendingPathComponent("consent-signed.pdf")
			if !mustExist || FileManager().fileExists(atPath: url.path) {
				return url
			}
		}
		catch let err {
			c3_warn("\(err)")
		}
		return nil
	}
	
	/**
	The local URL to the bundled consent; looks for «consent.pdf» in the main bundle.
	*/
	public class func bundledConsentPDFURL() -> URL? {
		return Bundle.main.url(forResource: "consent", withExtension: "pdf")
	}
}


class ConsentTaskViewControllerDelegate: NSObject, ORKTaskViewControllerDelegate {
	
	let controller: ConsentController
	
	init(controller: ConsentController) {
		self.controller = controller
	}
	
	func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
		controller.userDidFinishConsent(taskViewController, reason: reason)
	}
}

