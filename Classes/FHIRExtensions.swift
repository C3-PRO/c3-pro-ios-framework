//
//  FHIRExtensions.swift
//  ResearchCHIP
//
//  Created by Pascal Pfiffner on 7/29/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import SMART


extension FHIRElement
{
	/** Returns an array of `Extension` elements for the given extension URL, if any. */
	final func chip_extensionsFor(uri: String) -> [Extension]? {
		return extension_fhir?.filter() { return $0.url?.absoluteString == uri }
	}
	
	/** Returns the extension defining the inclusive lower bound, if any. Use with "valueInteger", "valueDecimal" or other supported type. */
	final func chip_minValue() -> Extension? {
		return chip_extensionsFor("http://hl7.org/fhir/StructureDefinition/minValue")?.first
	}
	
	/** Returns the extension defining the inclusive upper bound, if any. Use with "valueInteger", "valueDecimal" or other supported type. */
	final func chip_maxValue() -> Extension? {
		return chip_extensionsFor("http://hl7.org/fhir/StructureDefinition/maxValue")?.first
	}
}

