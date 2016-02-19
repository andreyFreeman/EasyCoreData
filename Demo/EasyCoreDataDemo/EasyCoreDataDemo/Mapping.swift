//
//  Mapping.swift
//  GiftdPartner
//
//  Created by Andrey Kladov on 23/04/15.
//  Copyright (c) 2015 Andrey Kladov. All rights reserved.
//

import CoreData
import Foundation

protocol MappableObject {
    func mapFromJSONDict(dict: JSONObject?)
}

extension MappableObject where Self: NSManagedObject {
    
    func mapFromJSONDict(dict: JSONObject?) {
        mapFromJSONDict(dict, context: NSManagedObjectContext.mainThreadContext)
    }
    
    func mapFromJSONDict(dict: JSONObject?, context: NSManagedObjectContext) {
        print("\(self).mapFromJSONDict(\(dict), context:(\(context)) isEmpty. Must be overriden in subclasses")
    }
}

func valueFromJSONDict<T>(dict: JSONObject?, key: String, defaultValue: T!) -> T! {
    return dict?[key] as? T ?? defaultValue
}