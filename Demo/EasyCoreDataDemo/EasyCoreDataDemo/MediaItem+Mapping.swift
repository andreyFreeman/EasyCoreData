//
//  MediaItem+Mapping.swift
//  EasyCoreDataDemo
//
//  Created by Andrey Kladov on 01/05/15.
//  Copyright (c) 2015 Andrey Kladov. All rights reserved.
//

import CoreData

extension StoreMediaItem {
	override func mapFromJSONDict(dict: JSONObject?, context: NSManagedObjectContext) {
		artistId = valueFromJSONDict(dict, "artistId",  NSNumber(int: 0)).intValue
		artist = valueFromJSONDict(dict, "artistName", "")
		title = ""
		artistViewUrl = valueFromJSONDict(dict, "artistViewUrl", "")
		artworkUrl60 = valueFromJSONDict(dict, "artworkUrl60", "")
		artworkUrl100 = valueFromJSONDict(dict, "artworkUrl100", "")
		genre = valueFromJSONDict(dict, "primaryGenreName", "")
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
