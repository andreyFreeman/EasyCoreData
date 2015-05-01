//
//  APIController.swift
//  EasyCoreDataDemo
//
//  Created by Andrey Kladov on 30/04/15.
//  Copyright (c) 2015 Andrey Kladov. All rights reserved.
//

import UIKit
import CoreData
import EasyCoreData

typealias JSONObject = [String: AnyObject]

class APIController {
	var baseURL = ""
}

extension APIController {
	private struct Consts {
		static let parsingQueue = dispatch_queue_create("com.EasyCoreDataDemo.queues.parsing", nil)
	}
	func runAPICall(call: String, params: [String: String], completion: (JSONObject?, NSError?) -> Void) {
		var paramsString = ""
		for (key, value) in params {
			if let paramValue = value.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding) {
				if count(paramsString) > 0 { paramsString+="&" }
				paramsString+="\(key)=\(paramValue)"
			}
		}
		if let url = NSURL(string: call+"?"+paramsString, relativeToURL: NSURL(string: baseURL)) {
			NSURLConnection.sendAsynchronousRequest(NSURLRequest(URL: url), queue: NSOperationQueue.mainQueue()) { response, data, error in
				if let err = error {
					completion(nil, err)
				} else {
					dispatch_async(Consts.parsingQueue) { () -> Void in
						var parseError: NSErrorPointer = nil
						let object = NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers, error: parseError) as? JSONObject
						dispatch_async(dispatch_get_main_queue()) { () -> Void in
							completion(object, nil)
						}
					}
				}
			}
		} else {
			completion(nil, nil)
		}
	}
}

extension APIController {
	class var sharedController: APIController {
		struct Singleton {
			static let sharedIntance = APIController()
		}
		return Singleton.sharedIntance
	}
}
