//
//  ProfileManagerSettings.swift
//  C-Tracker-SCCS
//
//  Created by Pascal Pfiffner on 29.11.16.
//  Copyright © 2016 SCCS. All rights reserved.
//


/**
Settings for ProfileManager. Also see `UserTaskSetting`, which takes care of settings applied in "notifications".

    {
      "activitySampleDays": 30,
      "tasks": [
        { ... }
      ]
    }
*/
public struct ProfileManagerSettings {
	
	/// for how many days back, starting today, the activity report should sample activity.
	public var activitySampleNumDays = 0
	
	var tasks: [UserTaskSetting]?
	
	init(with json: [String: Any]) throws {
		if let days = json["activitySampleDays"] as? Int {
			activitySampleNumDays = days
		}
		if let tsks = json["tasks"] as? [[String: String]] {
			tasks = try tsks.map() { try UserTaskSetting(from: $0) }
		}
	}
}

