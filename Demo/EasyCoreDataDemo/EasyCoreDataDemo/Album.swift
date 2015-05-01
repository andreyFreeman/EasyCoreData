//
//  Album.swift
//  EasyCoreDataDemo
//
//  Created by Andrey Kladov on 01/05/15.
//  Copyright (c) 2015 Andrey Kladov. All rights reserved.
//

import Foundation
import CoreData

class Album: StoreMediaItem {

    @NSManaged var collectionId: Int32
    @NSManaged var collectionViewUrl: String!
    @NSManaged var trackCount: Int16
    @NSManaged var tracks: NSSet!

}
