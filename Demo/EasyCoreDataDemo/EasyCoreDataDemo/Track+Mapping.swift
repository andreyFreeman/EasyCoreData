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
		title = valueFromJSONDict(dict, "trackName", "")
		trackId = valueFromJSONDict(dict, "trackId", NSNumber(int: 0)).intValue
		trackViewUrl = valueFromJSONDict(dict, "trackViewUrl", "")
		previewUrl = valueFromJSONDict(dict, "previewUrl", "")
		trackTimeMillis = valueFromJSONDict(dict, "trackTimeMillis", NSNumber(int: 0)).intValue
	}
}