//
//  Track.swift
//  EasyCoreDataDemo
//
//  Created by Andrey Kladov on 01/05/15.
//  Copyright (c) 2015 Andrey Kladov. All rights reserved.
//

import Foundation
import CoreData

class Track: StoreMediaItem {

    @NSManaged var trackId: Int32
    @NSManaged var trackViewUrl: String!
    @NSManaged var previewUrl: String!
    @NSManaged var trackTimeMillis: Int32
    @NSManaged var album: Album!

}
