//
//  Mapping.swift
//  GiftdPartner
//
//  Created by Andrey Kladov on 23/04/15.
//  Copyright (c) 2015 Andrey Kladov. All rights reserved.
//

import CoreData
import Foundation

extension NSManagedObject {
	func mapFromJSONDict(dict: JSONObject?, context: NSManagedObjectContext = NSManagedObjectContext.mainThreadContext) {
	
	}
}

func valueFromJSONDict<T>(dict: JSONObject?, key: String, defaultValue: T!) -> T! {
	if let value = dict?[key] as? T {
		return value
	}
	return defaultValue
}