//
//  AppDelegate.swift
//  EasyCoreDataDemo
//
//  Created by Andrey Kladov on 28/04/15.
//  Copyright (c) 2015 Andrey Kladov. All rights reserved.
//

import UIKit
import EasyCoreData
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		APIController.sharedController.baseURL = "https://itunes.apple.com"
        EasyCoreData.sharedInstance.persistentStoreCoordinatorOptions = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSSQLitePragmasOption: ["journal_mode": "delete"]
        ]
		return true
	}

	func applicationWillResignActive(application: UIApplication) {
		
	}

	func applicationDidEnterBackground(application: UIApplication) {
		
	}

	func applicationWillEnterForeground(application: UIApplication) {
		
	}

	func applicationDidBecomeActive(application: UIApplication) {
		
	}

	func applicationWillTerminate(application: UIApplication) {
		
	}


}

