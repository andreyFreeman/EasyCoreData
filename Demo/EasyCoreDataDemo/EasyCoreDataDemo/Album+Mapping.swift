//
//  Album+Mapping.swift
//  EasyCoreDataDemo
//
//  Created by Andrey Kladov on 01/05/15.
//  Copyright (c) 2015 Andrey Kladov. All rights reserved.
//

import CoreData

extension Album {
	override func mapFromJSONDict(dict: JSONObject?, context: NSManagedObjectContext) {
		super.mapFromJSONDict(dict, context: context)
		collectionId = valueFromJSONDict(dict, "collectionId", NSNumber(int: 0)).intValue
		trackCount = valueFromJSONDict(dict, "trackCount", NSNumber(int: 0)).shortValue
		title = valueFromJSONDict(dict, "collectionName", "")
		collectionViewUrl = valueFromJSONDict(dict, "collectionViewUrl", "")
	}
}
