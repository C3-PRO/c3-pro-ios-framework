//
//  C3Error.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 20/10/15.
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


/// The FHIR version used by this instance of the framework.
public let C3PROFHIRVersion = "3.0.0"


/**
Errors thrown around when working with C3-PRO.
*/
public enum C3Error: Error, CustomStringConvertible {
	
	/// The mentioned feature is not implemented.
	case notImplemented(String)
	
	/// An error holding on to multiple other errors.
	case multipleErrors(Array<Error>)
	
	
	// MARK: App
	
	/// The app's /Library directory is not present.
	case appLibraryDirectoryNotPresent
	
	/// Failed to refreish the App Store receipt.
	case appReceiptRefreshFailed
	
	/// The respective file was not found in the app bundle.
	case bundleFileNotFound(String)
	
	/// A JSON file does not have the expected structure.
	case invalidJSON(String)
	
	/// The layout of the storyboard is not as expected.
	case invalidStoryboard(String)
	
	
	// MARK: FHIR
	
	/// A FHIR extension is invalid in the respective context.
	case extensionInvalidInContext
	
	/// A FHIR extension is incomplete.
	case extensionIncomplete(String)
	
	
	// MARK: Consent
	
	/// The consent is lacking a patient reference.
	case consentNoPatientReference(Error)
	
	/// The necessary contract is not present.
	case consentContractNotPresent
	
	/// The Contract resource does not have any `term`s that can be used for consenting.
	case consentContractHasNoTerms
	
	/// No ContractTerm.type.coding was found.
	case consentSectionHasNoType
	
	/// The given consent section type is not known to ResearchKit.
	case consentSectionTypeUnknownToResearchKit(String)
	
	
	// MARK: User & Consent
	
	/// The schedule's file-format, or a date format string, is invalid.
	case invalidScheduleFormat(String)
	
	/// No user has been enrolled at this time.
	case noUserEnrolled
	
	/// This is a user without user id.
	case userHasNoUserId
	
	
	// MARK: Server
	
	/// No server is configured.
	case serverNotConfigured
	
	/// Data queue flushing was halted.
	case dataQueueFlushHalted
	
	
	// MARK: Encryption & JWT
	
	/// The given error occurred during encryption.
	case encryptionFailedWithStatus(OSStatus)
	
	/// The X509 certificate is not present at the given location.
	case encryptionX509CertificateNotFound(String)
	
	/// The X509 certificate could not be read from the given location.
	case encryptionX509CertificateNotRead(String)
	
	/// The X509 certificate could not be loaded for the given reason.
	case encryptionX509CertificateNotLoaded(String)
	
	/// Some JWT data was refuted.
	case jwtDataRefuted
	
	/// The JWT payload is missing its audience.
	case jwtMissingAudience
	
	/// The JWT `aud` param is not a valid URL.
	case jwtInvalidAudience(String)
	
	
	// MARK: Services
	
	/// Geolocation services are disabled or restricted.
	case locationServicesDisabled
	
	/// Access to the microphone is disabled.
	case microphoneAccessDenied
	
	
	// MARK: Questionnaire
	
	/// The questionnaire is not present.
	case questionnaireNotPresent
	
	/// The questionnaire does not have a top level item.
	case questionnaireInvalidNoTopLevelItem
	
	/// The given questionnaire question type cannot be represented in ResearchKit.
	case questionnaireQuestionTypeUnknownToResearchKit(QuestionnaireItem)
	
	/// The given question should provide choices but there are none.
	case questionnaireNoChoicesInChoiceQuestion(QuestionnaireItem)
	
	/// The 'item.enableWhen' property is incomplete.
	case questionnaireEnableWhenIncomplete(String)
	
	/// The questionnaire finished with an error (i.e. was not completed).
	case questionnaireFinishedWithError
	
	/// Unknown error handling questionnaire.
	case questionnaireUnknownError
	
	
	// MARK: HealthKit
	
	/// Access to HealthKit was not granted.
	case healthKitNotAvailable
	
	/// There is no HealthKit sample of the given type.
	case noSuchHKSampleType(String)
	
	/// The respective HealthKit quantity cannot be converted to the desired unit.
	case quantityNotCompatibleWithUnit
	
	/// The interval to query data is too small.
	case intervalTooSmall
	
	
	// MARK: - Custom String Convertible
	
	/// A string representation of the error.
	public var description: String {
		switch self {
		case .notImplemented(let message):
			return "Not yet implemented: \(message)"
		case .multipleErrors(let errs):
			if 1 == errs.count {
				return "\(errs[0])"
			}
			let summaries = errs.map() { "\($0)" }.reduce("") { $0 + (!$0.isEmpty ? "\n" : "") + $1 }
			return "Multiple errors occurred:\n\(summaries)"
		
		case .appLibraryDirectoryNotPresent:
			return "The app library directory could not be found; this is likely fatal"
		case .appReceiptRefreshFailed:
			return "App receipt refresh failed. Are you running on device?"
		case .bundleFileNotFound(let name):
			return name
		case .invalidJSON(let reason):
			return "Invalid JSON: \(reason)"
		case .invalidStoryboard(let reason):
			return "Invalid Storyboard: \(reason)"
		
		case .extensionInvalidInContext:
			return "This extension is not valid in this context"
		case .extensionIncomplete(let reason):
			return "Extension is incomplete: \(reason)"
		
		case .consentNoPatientReference(let underlying):
			return "Failed to generate a relative reference for the patient: \(underlying)"
		case .consentContractNotPresent:
			return "No Contract resource, cannot continue"
		case .consentContractHasNoTerms:
			return "The Contract resource does not have any terms that can be used for consenting"
		case .consentSectionHasNoType:
			return "Looking for consent type in ContractTerm.type.coding but none was found"
		case .consentSectionTypeUnknownToResearchKit(let type):
			return "Unknown consent section type “\(type)”"
		
		case .invalidScheduleFormat(let str):
			return "Schedule format is invalid".c3_localized + ":\n\n" + str
		case .noUserEnrolled:
			return "Not enrolled in the study yet".c3_localized
		case .userHasNoUserId:
			return "The user does not have a userId".c3_localized
		
		case .serverNotConfigured:
			return "No server has been configured"
		case .dataQueueFlushHalted:
			return "Flush halted"
		
		case .encryptionFailedWithStatus(let status):
			return "Failed to encrypt data with key: OSStatus \(status)"
		case .encryptionX509CertificateNotFound(let file):
			return "Bundled X509 certificate «\(file).crt» not found"
		case .encryptionX509CertificateNotRead(let file):
			return "Failed to read bundled X509 certificate «\(file).crt»"
		case .encryptionX509CertificateNotLoaded(let message):
			return message
		case .jwtDataRefuted:
			return "You refuted some of the information contained in the code".c3_localized
		case .jwtMissingAudience:
			return "The JWT is missing its audience (`aud` parameter)".c3_localized
		case .jwtInvalidAudience(let str):
			return "The JWT `aud` param's value is “{{aud}}”, which is not a valid URL".c3_localized.replacingOccurrences(of: "{{aud}}", with: str)
		
		case .locationServicesDisabled:
			return "Location services are disabled or have been restricted"
		case .microphoneAccessDenied:
			return "Access to the microphone has been denied for this app"
		
		case .questionnaireNotPresent:
			return "I do not have a questionnaire just yet"
		case .questionnaireInvalidNoTopLevelItem:
			return "Invalid questionnaire, does not contain a top level item"
		case .questionnaireQuestionTypeUnknownToResearchKit(let question):
			return "Failed to map question type “\(question.type?.rawValue ?? "<nil>")” to ResearchKit answer format [linkId: \(question.linkId ?? "<nil>")]"
		case .questionnaireNoChoicesInChoiceQuestion(let question):
			return "There are no choices in question “\(question.text ?? "")” [linkId: \(question.linkId ?? "<nil>")]"
		case .questionnaireEnableWhenIncomplete(let reason):
			return "item.enableWhen is incomplete: \(reason)"
		case .questionnaireFinishedWithError:
			return "Unknown error finishing questionnaire"
		case .questionnaireUnknownError:
			return "Unknown error handling questionnaire"
		
		case .healthKitNotAvailable:
			return "HealthKit is not available on your device"
		case .noSuchHKSampleType(let typeIdentifier):
			return "There is no HKSampleType “\(typeIdentifier)”"
		case .quantityNotCompatibleWithUnit:
			return "The unit is not compatible with this quantity"
		case .intervalTooSmall:
			return "The interval is too small"
		}
	}
}


/**
Ensures that the given block is executed on the main queue.

- parameter block: The block to execute on the main queue.
*/
public func c3_performOnMainQueue(_ block: @escaping (() -> Void)) {
	if Thread.current.isMainThread {
		block()
	}
	else {
		DispatchQueue.main.async {
			block()
		}
	}
}


/**
Prints the given message to stdout if `DEBUG` is defined and true. Prepends filename, line number and method/function name.
*/
public func c3_logIfDebug(_ message: @autoclosure () -> String, function: String = #function, file: NSString = #file, line: Int = #line) {
	#if DEBUG
		print("[\(file.lastPathComponent):\(line)] \(function)  \(message())")
	#endif
}


/**
Prints the given message to stdout. Prepends filename, line number, method/function name and "WARNING:".
*/
public func c3_warn(_ message: @autoclosure () -> String, function: String = #function, file: NSString = #file, line: Int = #line) {
	print("[\(file.lastPathComponent):\(line)] \(function)  WARNING: \(message())")
}

