//
//  StoreMediaItem.swift
//  EasyCoreDataDemo
//
//  Created by Andrey Kladov on 01/05/15.
//  Copyright (c) 2015 Andrey Kladov. All rights reserved.
//

import Foundation
import CoreData

class StoreMediaItem: NSManagedObject {

    @NSManaged var artist: String!
    @NSManaged var artistId: Int32
    @NSManaged var artistViewUrl: String!
    @NSManaged var artworkUrl60: String!
    @NSManaged var artworkUrl100: String!
    @NSManaged var genre: String!
    @NSManaged var releaseDate: NSDate!
    @NSManaged var sortingOrder: Int16
    @NSManaged var title: String!

}
