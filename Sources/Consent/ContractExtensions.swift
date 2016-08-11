//
//  ContractExtensions.swift
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

import SMART
import ResearchKit


public let kContractTermConsentSectionExtension = "http://fhir-registry.smarthealthit.org/StructureDefinition/ORKConsentSection"

public let kContractTermConsentSectionType = "http://researchkit.org/docs/Constants/ORKConsentSectionType"


/** Extending `Contract` for usage with ResearchKit. */
public extension Contract {
	
	/**
	Converts the receiver into a ResearchKit consent document.
	
	- returns: An `ORKConsentDocument` created from the receiver
	*/
	public func c3_asConsentDocument() throws -> ORKConsentDocument {
		let sections = try c3_termsAsConsentSections()
		let document = ORKConsentDocument()
		document.title = "Consent".c3_localized
		document.signaturePageTitle = "Consent".c3_localized
		document.signaturePageContent = "By agreeing you confirm that you read the consent and that you wish to take part in this research study.".c3_localized
		document.sections = sections
		
		return document
	}
	
	/**
	Creates ResearchKit consent sections from the receiver's `term`s.
	
	- returns: An array of `ORKConsentSection`
	*/
	public func c3_termsAsConsentSections() throws -> [ORKConsentSection] {
		guard let terms = term else {
			throw C3Error.consentContractHasNoTerms
		}
		var sections = [ORKConsentSection]()
		for term in terms {
			do {
				let section = try term.c3_asConsentSection()
				sections.append(section)
			}
			catch let error {
				c3_warn("Contract `term` section \(term) cannot be used for consenting: \(error)")
			}
		}
		if sections.isEmpty {
			throw C3Error.consentContractHasNoTerms
		}
		return sections
	}
}


/** Extending `ContractTerm` for usage with ResearchKit. */
public extension ContractTerm {
	
	/**
	Creates a ResearchKit consent section from the receiver.
	
	- returns: An ORKConsentSection representing the receiver
	*/
	public func c3_asConsentSection() throws -> ORKConsentSection {
		let type = try c3_consentSectionType()
		let section = ORKConsentSection(type: type)
		section.summary = text
		
		// We need extensions for some other properties
		if let subs = extensions(forURI: kContractTermConsentSectionExtension)?.first?.extension_fhir {
			for sub in subs {
				if let url = sub.url?.absoluteString {
					switch url {
					case "title":
						section.title = sub.valueString
					case "htmlContent":
						section.htmlContent = sub.valueString
					case "htmlContentFile":
						let bundle = Bundle.main
						if let name = sub.valueString, let url = bundle.url(forResource: name, withExtension: "html") ?? bundle.url(forResource: name, withExtension: "html", subdirectory: "HTMLContent") {
							do {
								section.htmlContent = try String(contentsOf: url, encoding: String.Encoding.utf8)
							}
							catch let error {
								c3_warn("Failed to read from bundled file «\(url)»: \(error)")
							}
						}
						else {
							c3_warn("HTML consent section with name «\(sub.valueString)» is not in main bundle nor in its «HTMLContent» subdirectory")
						}
					case "image":
						if let name = sub.valueString, let image = UIImage(named: name) {
							section.customImage = image
						}
						else {
							c3_warn("Custom consent image named «\(sub.valueString)» is not in main bundle")
						}
					case "animation":
						let multi = (UIScreen.main.scale >= 3.0) ? "@3x" : "@2x"
						if let name = sub.valueString, let url = Bundle.main.url(forResource: name + multi, withExtension: "m4v") {
							section.customAnimationURL = url
						}
						else {
							c3_warn("Custom animation named «\(sub.valueString)» is not in main bundle")
						}
					default:
						break
					}
				}
			}
		}
		section.omitFromDocument = (section.content?.isEmpty ?? true) && (section.htmlContent?.isEmpty ?? true)
		
		return section
	}
	
	/**
	Determines the ResearchKit consent section type the receiver wants for representation.
	
	- returns: A matching ORKConsentSectionType
	*/
	public func c3_consentSectionType() throws -> ORKConsentSectionType {
		if let codings = type?.coding {
			for code in codings {
				if let url = code.system?.absoluteString, url != kContractTermConsentSectionType {
					c3_logIfDebug("Ignoring consent section system “\(url)” (expecting “\(kContractTermConsentSectionType)”)")
					continue
				}
				if nil == code.code {
					continue
				}
				switch code.code! {
				case "Overview":
					return ORKConsentSectionType.overview
				case "Privacy":
					return ORKConsentSectionType.privacy
				case "DataGathering":
					return ORKConsentSectionType.dataGathering
				case "DataUse":
					return ORKConsentSectionType.dataUse
				case "TimeCommitment":
					return ORKConsentSectionType.timeCommitment
				case "StudySurvey":
					return ORKConsentSectionType.studySurvey
				case "StudyTasks":
					return ORKConsentSectionType.studyTasks
				case "Withdrawing":
					return ORKConsentSectionType.withdrawing
				case "Custom":
					return ORKConsentSectionType.custom
				case "OnlyInDocument":
					return ORKConsentSectionType.onlyInDocument
				default:
					throw C3Error.consentSectionTypeUnknownToResearchKit(code.code!)
				}
			}
		}
		throw C3Error.consentSectionHasNoType
	}
}

