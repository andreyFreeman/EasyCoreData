//
//  APIController+Extensions.swift
//  EasyCoreDataDemo
//
//  Created by Andrey Kladov on 01/05/15.
//  Copyright (c) 2015 Andrey Kladov. All rights reserved.
//

import Foundation
import CoreData
import EasyCoreData

private extension APIController {
	var defaultAPIError: NSError {
		return NSError(domain: "APIController", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error occured"])
	}
}

extension APIController {
	func searchAlbumByTrackName(track: String, returnObjectOnCompletion fetch: Bool = true, completion:(([Album]?, NSError?) -> Void)?) {
		runAPICall("search", params: ["term": track, "attribute": "songTerm", "entity": "album"]) { object, error in
			switch (error, object?["results"] as? [JSONObject]) {
			case (.Some, _): completion?(nil, error)
			case (.None, .Some(let objects)):
				NSManagedObjectContext.saveDataInBackground({ localContext in
					Album.deleteAll(inContext: localContext)
					for (index, dict) in enumerate(objects) {
						let album = localContext.createEntity(Album)
						album.mapFromJSONDict(dict, context: localContext)
						album.sortingOrder = Int16(index)
					}
					}) {
						completion?(fetch ? NSManagedObjectContext.mainThreadContext.fetchObjects(Album.self, sortDescriptors: [NSSortDescriptor(key: "sortingOrder", ascending: true)]) : nil, nil)
				}
			default: completion?(nil, self.defaultAPIError)
			}
		}
	}
}

extension APIController {
	func loadSongsForAlbum(album: Album, completion: (([Track]?, NSError?) -> Void)?) {
		runAPICall("lookup", params: ["id": "\(album.collectionId)", "entity": "song"]) { response, error in
			switch (error, response?["results"] as? [JSONObject]) {
			case (.Some, _): completion?(nil, error)
			case (.None, .Some(let objects)):
				NSManagedObjectContext.saveDataInBackground({ localContext in
					if let localAlbum = localContext.entityFromOtherContext(album) {
						Track.deleteAll(predicate: NSPredicate(format: "album == %@", localAlbum), inContext: localContext)
						for (index, dict) in enumerate(objects.filter({ $0["wrapperType"] as? String == .Some("track") })) {
							let track = localContext.createEntity(Track)
							track.mapFromJSONDict(dict, context: localContext)
							track.sortingOrder = Int16(index)
							track.album = localAlbum
						}
					}
					}) {
						completion?(NSManagedObjectContext.mainThreadContext.fetchObjects(Track.self, sortDescriptors: [NSSortDescriptor(key: "sortingOrder", ascending: true)]), nil)
				}
			default: completion?(nil, self.defaultAPIError)
			}
		}
	}
}
