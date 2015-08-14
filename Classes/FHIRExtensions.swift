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
	/** Returns the extension defining the inclusive lower bound, if any. Use with "valueInteger", "valueDecimal" or other supported type. */
	final func chip_minValue() -> [Extension]? {
		return extensionsFor("http://hl7.org/fhir/StructureDefinition/minValue")
	}
	
	/** Returns the extension defining the inclusive upper bound, if any. Use with "valueInteger", "valueDecimal" or other supported type. */
	final func chip_maxValue() -> [Extension]? {
		return extensionsFor("http://hl7.org/fhir/StructureDefinition/maxValue")
	}
}

