//
//  ContractExtensions.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 8/14/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import SMART
import ResearchKit


public let kContractTermConsentSectionExtension = "http://fhir-registry.smarthealthit.org/StructureDefinition/ORKConsentSection"

public let kContractTermConsentSectionType = "http://researchkit.org/docs/Constants/ORKConsentSectionType"

public extension Contract {
	
	public func chip_asConsentDocument() throws -> ORKConsentDocument {
		let sections = try chip_termsAsConsentSections()
		let document = ORKConsentDocument()
		document.title = "Consent".localized
		document.signaturePageTitle = "Consent".localized
		document.signaturePageContent = "By agreeing you confirm that you read the consent and that you wish to take part in this research study.".localized
		document.sections = sections
		
		return document
	}
	
	public func chip_termsAsConsentSections() throws -> [ORKConsentSection] {
		if let terms = term {
			var sections = [ORKConsentSection]()
			for term in terms {
				do {
					let section = try term.chip_asConsentSection()
					sections.append(section)
				}
				catch let error {
					chip_warn("Contract `term` section \(term) cannot be used for consenting: \(error)")
				}
			}
			if sections.isEmpty {
				throw C3Error.ConsentContractHasNoTerms
			}
			return sections
		}
		throw C3Error.ConsentContractHasNoTerms
	}
}


public extension ContractTerm {
	
	public func chip_asConsentSection() throws -> ORKConsentSection {
		let type = try chip_consentSectionType()
		let section = ORKConsentSection(type: type)
		section.summary = text
		
		// We need extensions for some other properties
		if let subs = extensionsFor(kContractTermConsentSectionExtension)?.first?.extension_fhir {
			for sub in subs {
				if let url = sub.url?.absoluteString {
					switch url {
					case "title":
						section.title = sub.valueString
					case "htmlContent":
						section.htmlContent = sub.valueString
					case "htmlContentFile":
						let bundle = NSBundle.mainBundle()
						if let name = sub.valueString, let url = bundle.URLForResource(name, withExtension: "html") ?? bundle.URLForResource(name, withExtension: "html", subdirectory: "HTMLContent") {
							do {
								section.htmlContent = try NSString(contentsOfURL: url, encoding: NSUTF8StringEncoding) as String
							}
							catch let error {
								chip_warn("Failed to read from bundled file «\(url)»: \(error)")
							}
						}
						else {
							chip_warn("HTML consent section with name «\(sub.valueString)» is not in main bundle nor in its «HTMLContent» subdirectory")
						}
					case "image":
						if let name = sub.valueString, let image = UIImage(named: name) {
							section.customImage = image
						}
						else {
							chip_warn("Custom consent image named «\(sub.valueString)» is not in main bundle")
						}
					case "animation":
						let multi = (UIScreen.mainScreen().scale >= 3.0) ? "@3x" : "@2x"
						if let name = sub.valueString, let url = NSBundle.mainBundle().URLForResource(name + multi, withExtension: "m4v") {
							section.customAnimationURL = url
						}
						else {
							chip_warn("Custom animation named «\(sub.valueString)» is not in main bundle")
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
	
	public func chip_consentSectionType() throws -> ORKConsentSectionType {
		if let codings = type?.coding {
			for code in codings {
				if let url = code.system?.absoluteString where url != kContractTermConsentSectionType {
					chip_logIfDebug("Ignoring consent section system “\(url)” (expecting “\(kContractTermConsentSectionType)”)")
					continue
				}
				if nil == code.code {
					continue
				}
				switch code.code! {
				case "Overview":
					return ORKConsentSectionType.Overview
				case "Privacy":
					return ORKConsentSectionType.Privacy
				case "DataGathering":
					return ORKConsentSectionType.DataGathering
				case "DataUse":
					return ORKConsentSectionType.DataUse
				case "TimeCommitment":
					return ORKConsentSectionType.TimeCommitment
				case "StudySurvey":
					return ORKConsentSectionType.StudySurvey
				case "StudyTasks":
					return ORKConsentSectionType.StudyTasks
				case "Withdrawing":
					return ORKConsentSectionType.Withdrawing
				case "Custom":
					return ORKConsentSectionType.Custom
				case "OnlyInDocument":
					return ORKConsentSectionType.OnlyInDocument
				default:
					throw C3Error.ConsentSectionTypeUnknownToResearchKit(code.code!)
				}
			}
		}
		throw C3Error.ConsentSectionHasNoType
	}
}

