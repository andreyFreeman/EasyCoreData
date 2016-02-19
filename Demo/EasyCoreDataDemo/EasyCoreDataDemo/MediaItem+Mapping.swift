//
//  MediaItem+Mapping.swift
//  EasyCoreDataDemo
//
//  Created by Andrey Kladov on 01/05/15.
//  Copyright (c) 2015 Andrey Kladov. All rights reserved.
//

import CoreData

extension StoreMediaItem: MappableObject {
	func mapFromJSONDict(dict: JSONObject?, context: NSManagedObjectContext) {
		artistId = valueFromJSONDict(dict, key: "artistId",  defaultValue: NSNumber(int: 0)).intValue
		artist = valueFromJSONDict(dict, key: "artistName", defaultValue: "")
		title = ""
		artistViewUrl = valueFromJSONDict(dict, key: "artistViewUrl", defaultValue: "")
		artworkUrl60 = valueFromJSONDict(dict, key: "artworkUrl60", defaultValue: "")
		artworkUrl100 = valueFromJSONDict(dict, key: "artworkUrl100", defaultValue: "")
		genre = valueFromJSONDict(dict, key: "primaryGenreName", defaultValue: "")
		let formatter = NSDateFormatter()
		formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
		releaseDate = {
			if let dateString = dict?["releaseDate"] as? String {
				return formatter.dateFromString(dateString)
			}
			return nil
			}()
	}
}
