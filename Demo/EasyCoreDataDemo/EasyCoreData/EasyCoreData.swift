//
//  EasyCoreData.swift
//  EasyCoreData
//
//  Created by Andrey Kladov on 21/03/15.
//  Copyright (c) 2015 Andrey Kladov. All rights reserved.
//

import UIKit
import CoreData

public class EasyCoreData {
    /**
     The URL that locates the sqlite store file. By default it's in the Documents directory, file: 'modelURL'.sqlite
     */
    public lazy var sqliteStoreURL: NSURL = self.createDefaultStoreURL()
    
    /**
     The name of the xcdatamodel file. The default value is the main bundle name
     */
    public lazy var modelName: String = self.createDefaultModelName()
    
    /**
     The URL for the model mom/momd file. By default is modelBundle.URLForResource(modelName...
     */
    public lazy var modelURL: NSURL = self.createDefaultModelURL()
    
    /**
     The NSBundle where model mom/momd file is located. By default is NSBundle.mainBundle()
     */
    public var modelBundle = NSBundle.mainBundle()
    
    /**
     Params dictionary will be passed into the addPersistentStoreWithType method
     */
    public var persistentStoreCoordinatorOptions: [NSObject: AnyObject] = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true, NSSQLitePragmasOption: ["journal_mode": "delete"]]
    
    private lazy var _persistentStoreCoordinator: NSPersistentStoreCoordinator! = self.createPersistentStoreCoordinator()
    private lazy var _managedObjectModel: NSManagedObjectModel! = self.createManagedObjectModel()
    private lazy var _rootManagedObjectContext: NSManagedObjectContext! = self.createRootManagedObjectContext()
    private lazy var _mainThreadManagedObjectContext: NSManagedObjectContext! = self.createMainThreadManagedObjectContext()
    
    public private(set) var coreDataStackLoaded = false
}

public extension EasyCoreData {
    /**
     The Singleton realization. Shared EasyCoreData instance will be returned. Use this class property is strongly recommended
     */
    public static let sharedInstance = EasyCoreData()
    
    class func saveRootContext() {
        let context = sharedInstance._rootManagedObjectContext
        if context.hasChanges {
            do {
                try context.save()
            }
            catch let error {
                print("\(self): failed to save root NSManagedObjectContext \(error as NSError)")
            }
        }
    }
}

public extension EasyCoreData {
    /**
     The instance of NSPresistentStoreCoordinator for default store
     */
    
    public var persistentStoreCoordinator: NSPersistentStoreCoordinator! { return _persistentStoreCoordinator }
    
    /**
     The instance of NSManagedObjectModel
     */
    public var managedObjectModel: NSManagedObjectModel! { return _managedObjectModel }
    
    /**
     Root NSManagedObjectContext instance with concurrency type PrivateQueueConcurrencyType. Using to save data base changes to disk
     */
    public var rootManagedObjectContext: NSManagedObjectContext! { return _rootManagedObjectContext }
    
    /**
     Main NSManagedObjectContext instance with concurrency type MainQueueConcurrencyType. Should be used as main context in the app to normal data access
     */
    public var mainThreadManagedObjectContext: NSManagedObjectContext! { return _mainThreadManagedObjectContext }
}

public extension EasyCoreData {
    /**
     Should be called once main parameters values: sqliteStoreURL, modelName, modelURL or modelBundle are changed. The instances of NSPersistentStoreCoordinator, NSManagedObjectModel and NSManagedObjectContext will be recreated
     */
    func reset() { setup() }
    /**
     Forces the creation of NSPersistentStoreCoordinator, NSManagedObjectModel and NSManagedObjectContext instances. Can be called before start using EasyCoreData, otherwise lazy load will be performed with the first storage operation
     */
    func setup() {
        _managedObjectModel = createManagedObjectModel()
        _persistentStoreCoordinator = createPersistentStoreCoordinator()
        _rootManagedObjectContext = createRootManagedObjectContext()
        _mainThreadManagedObjectContext = createMainThreadManagedObjectContext()
    }
}

private extension EasyCoreData {
    var applicationDocumentsDirectory: NSURL {
        return NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
    }
}

private extension EasyCoreData {
    func createManagedObjectModel() -> NSManagedObjectModel! { return NSManagedObjectModel(contentsOfURL: modelURL) }
    func createPersistentStoreCoordinator() -> NSPersistentStoreCoordinator! {
        switch managedObjectModel {
        case .Some(let model):
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
            do {
                try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL:sqliteStoreURL , options: persistentStoreCoordinatorOptions)
            } catch let err as NSError {
                logTextIfDebug("Error add default persistent store. Reason: \(err.localizedDescription)")
            }
            return coordinator
        default: return nil
        }
    }
    func createRootManagedObjectContext() -> NSManagedObjectContext! {
        switch persistentStoreCoordinator {
        case .Some(let coordinator):
            let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
            context.performBlockAndWait { () in context.persistentStoreCoordinator = coordinator }
            return context
        default:
            logTextIfDebug("Could not create root NSManagegObjectContext. Persistent store coordinator must not be nil")
            return nil
        }
    }
    func createMainThreadManagedObjectContext() -> NSManagedObjectContext! {
        let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        context.parentContext = rootManagedObjectContext
        coreDataStackLoaded = true
        return context
    }
}

private extension EasyCoreData {
    func createDefaultModelName() -> String {
        switch NSBundle.mainBundle().infoDictionary?["\(kCFBundleNameKey)"] as? String {
        case .Some(let name): return name
        default: return "Model"
        }
    }
    func createDefaultStoreURL() -> NSURL {
        return applicationDocumentsDirectory.URLByAppendingPathComponent(modelName+".sqlite")
    }
    func createDefaultModelURL() -> NSURL {
        switch (modelBundle.URLForResource(modelName, withExtension: "mom"), modelBundle.URLForResource(modelName, withExtension: "momd")) {
        case (.Some(let url), _): return url
        case (_, .Some(let url)): return url
        default: logTextIfDebug("Could not load default model URL. There is no \(modelName).mom/\(modelName).momd files in bundle: \(modelBundle)")
        return NSURL()
        }
    }
}

internal func logTextIfDebug(text: String!) {
    debugPrint("\(text)")
}