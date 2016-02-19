//
//  Track+Mapping.swift
//  EasyCoreDataDemo
//
//  Created by Andrey Kladov on 01/05/15.
//  Copyright (c) 2015 Andrey Kladov. All rights reserved.
//

import CoreData

extension Track {
	override func mapFromJSONDict(dict: JSONObject?, context: NSManagedObjectContext) {
		super.mapFromJSONDict(dict, context: context)
		title = valueFromJSONDict(dict, key: "trackName", defaultValue: "")
		trackId = valueFromJSONDict(dict, key: "trackId", defaultValue: NSNumber(int: 0)).intValue
        trackViewUrl = valueFromJSONDict(dict, key: "trackViewUrl", defaultValue: "")
        previewUrl = valueFromJSONDict(dict, key: "previewUrl", defaultValue: "")
        trackTimeMillis = valueFromJSONDict(dict, key: "trackTimeMillis", defaultValue: NSNumber(int: 0)).intValue
	}
}