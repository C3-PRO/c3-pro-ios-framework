//
//  C3Error.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 20/10/15.
//  Copyright © 2015 Boston Children's Hospital. All rights reserved.
//


/**
Errors thrown around when working with C3-PRO.
*/
public enum C3Error: ErrorType, CustomStringConvertible {
	case BundleFileNotFound(String)
	case InvalidJSON(String)
	case InvalidStoryboard(String)
	
	/// A string representation of the error.
	public var description: String {
		switch self {
		case .BundleFileNotFound(let name):
			return name
		case .InvalidJSON(let reason):
			return "Invalid JSON: \(reason)"
		case .InvalidStoryboard(let reason):
			return "Invalid Storyboard: \(reason)"
		}
	}
}
