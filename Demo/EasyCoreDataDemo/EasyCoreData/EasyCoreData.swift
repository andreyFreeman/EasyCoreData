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
     Params dictionary will be passed into the addPersistentStoreWithType method and used to perform the migration
     use NSMigratePersistentStoresAutomaticallyOption = true option in case you need to perform light or heavy-weight migration
     use NSInferMappingModelAutomaticallyOption = true option to force to perform light-weight migration
     default value is [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true, NSSQLitePragmasOption: ["journal_mode": "delete"]]
     */
    public var persistentStoreCoordinatorOptions: [NSObject: AnyObject] = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true, NSSQLitePragmasOption: ["journal_mode": "delete"]]
    
    /**
     Setup models names in ascending order of it versions to perform iterative migration. 
     By default will attempt to retrieve it from self.modelBundle and sort by filename
     */
    public lazy var orderedModelsFileNames: [String] = {
        guard let modelFolder = self.modelBundle.URLForResource(self.modelName, withExtension: "momd", subdirectory: nil)?.lastPathComponent else { return [] }
        var filenames = self.modelBundle.pathsForResourcesOfType("mom", inDirectory: modelFolder).sort().reduce([String]()) {
            guard let filename = NSURL(fileURLWithPath: $1).URLByDeletingPathExtension?.lastPathComponent else { return $0 }
            return $0+[filename]
        }
        
        let baseModelName = modelFolder.stringByReplacingOccurrencesOfString(".momd", withString: "")
        if let index = filenames.indexOf(baseModelName) where index > 0 {
            filenames.removeAtIndex(index)
            filenames.insert(baseModelName, atIndex: 0)
        }
        return filenames
    }()
    
    /**
     Will be executed right afted heavy-weight migration if any performed. 
     Temp main queue NSManagedObject will be created and passed to this closure
     */
    public var postMigrationSetup: (NSManagedObjectContext -> Void)?
    
    /**
     Model bundles will be used for merdgedModelFromBundles:forStoreMetadata: and NSMappingModel's fromBundles:forSourceModel:destinationModel: calls
     */
    public lazy var modelBundles: [NSBundle] = {
        return [self.modelBundle]
    }()
    
    private var mustRunPostMigration = false
    
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
            addPersistentStoreToPersistentStoreCoordinator(coordinator)
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
    func addPersistentStoreToPersistentStoreCoordinator(coordinator: NSPersistentStoreCoordinator) {
        
        let addPersistentStore: () -> () = {
            do {
                try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: self.sqliteStoreURL , options: self.persistentStoreCoordinatorOptions)
            } catch let err as NSError {
                logTextIfDebug("Error add default persistent store. Reason: \(err.localizedDescription)")
            }
        }
        
        switch (persistentStoreCoordinatorOptions[NSMigratePersistentStoresAutomaticallyOption] as? Bool,
            persistentStoreCoordinatorOptions[NSInferMappingModelAutomaticallyOption] as? Bool) {
        case (.Some(true), .Some(true)): addPersistentStore()
        case (.Some(true), _):
            do {
                mustRunPostMigration = try Migration.migrateStoreAtPath(sqliteStoreURL.path!, modelBundles: modelBundles, toModel: managedObjectModel, storeConfiguration: nil, orderedModelNames: orderedModelsFileNames)
                addPersistentStore()
            }
            catch let error as NSError {
                fatalError(error.localizedDescription)
            }
        default: addPersistentStore()
        }
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

public extension EasyCoreData {
    
    /**
     Iterative heavy-weight data model migration
     */
    public class Migration {
        
        /**
         Will locate current model, check if it's compatible with the scheme of existings store store, instantiate models provided in orderedModelsFileNames and perform step-by-step migration for each models pairs until the current one. Works in both directions
         - parameter storePath: file path to existing sqlite store
         - parameter storeType: type of store, default NSSQLiteStoreType
         - parameter modelBundles: array of NSBundle objects for lookup data model versions
         - parameter toModel: current model
         - parameter storeConfiguration: configuration of the store, default is nil
         - parameter orderedModelNames: model names to retrieve from bundles ordered by version
         - returns: Bool indicating was the actual migration performed it was skipped for some reasons
         */
        public class func migrateStoreAtPath(
            storePath: String,
            storeType: String = NSSQLiteStoreType,
            modelBundles bundles:[NSBundle]? = [NSBundle.mainBundle()],
            toModel finalModel: NSManagedObjectModel,
            storeConfiguration: String? = nil,
            orderedModelNames modelNames: [String]) throws -> Bool {
                
                func extractModelsWithNames(filenames:[String]) -> [NSManagedObjectModel]? {
                    
                    guard let bundles = bundles else { return nil }
                    
                    return filenames.reduce([NSManagedObjectModel]()) {
                        for bundle in bundles {
                            if let url = bundle.URLForResource($1, withExtension: "mom"),
                                let model = NSManagedObjectModel(contentsOfURL: url) {
                                    return $0+[model]
                            } else {
                                for path in bundle.pathsForResourcesOfType("momd", inDirectory: nil) {
                                    if let subfolder = NSURL(fileURLWithPath: path).lastPathComponent,
                                        let url = bundle.URLForResource($1, withExtension: "mom", subdirectory: subfolder),
                                        let model = NSManagedObjectModel(contentsOfURL: url) {
                                            return $0+[model]
                                    }
                                }
                            }
                        }
                        return $0
                    }
                }
                
                let produceErrorWithMessage: (String) -> NSError = { message in
                    NSError(domain: "com.EasyCoreData.Migration.errors.migrationError", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
                }
                
                let storeUrl = NSURL(fileURLWithPath: storePath)
                let fileManager = NSFileManager.defaultManager()
                
                guard fileManager.fileExistsAtPath(storePath) else {
                    return false
                }
                do {
                    let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStoreOfType(storeType, URL: storeUrl)
                    guard !finalModel.isConfiguration(storeConfiguration, compatibleWithStoreMetadata: metadata) else {
                        return false
                    }
                    guard let sourceModel = NSManagedObjectModel.mergedModelFromBundles(bundles, forStoreMetadata: metadata),
                        let models = extractModelsWithNames(modelNames) where models.count > 1 else {
                            throw produceErrorWithMessage("Could not retrieve all the required data models")
                    }
                    
                    guard let startIndex = models.indexOf(sourceModel), let endIndex = models.indexOf(finalModel) else {
                        throw produceErrorWithMessage("Could not find source and/or final data in the list of 'orderedDataModels': \(modelNames)")
                    }
                    
                    let modelsToMigrate: [NSManagedObjectModel] = {
                        switch (startIndex < endIndex, startIndex > endIndex) {
                        case (true, false): return Array(models[startIndex...endIndex])
                        case (false, true): return Array(models[endIndex...startIndex]).reverse()
                        default: return []
                        }
                    }()
                    
                    var didMigrate = false
                    for (index, modelFrom) in modelsToMigrate.enumerate() {
                        guard index < (modelsToMigrate.count - 1) else {
                            break
                        }
                        
                        let modelTo = modelsToMigrate[index + 1]
                        
                        var mapping = NSMappingModel(fromBundles: bundles, forSourceModel: modelFrom, destinationModel: modelTo)
                        if (mapping == nil) {
                            mapping = try NSMappingModel.inferredMappingModelForSourceModel(modelFrom, destinationModel: modelTo)
                        }
                        guard let mappingModel = mapping else {
                            throw produceErrorWithMessage("Could not find mapping model for source model: \(modelFrom) and destination model: \(modelTo)")
                        }
                        
                        let tempDestinationStoreUrl = storeUrl.URLByAppendingPathExtension("tmp")
                        
                        try NSMigrationManager(sourceModel: modelFrom, destinationModel: modelTo).migrateStoreFromURL(storeUrl, type: storeType, options: nil, withMappingModel: mappingModel, toDestinationURL: tempDestinationStoreUrl, destinationType: storeType, destinationOptions: nil)
                        
                        let backupUrl = storeUrl.URLByAppendingPathExtension("bak")
                        
                        try fileManager.moveItemAtURL(storeUrl, toURL: backupUrl)
                        do {
                            try fileManager.moveItemAtURL(tempDestinationStoreUrl, toURL: storeUrl)
                            didMigrate = true
                        }
                        catch {
                            try fileManager.moveItemAtURL(backupUrl, toURL: storeUrl)
                            throw produceErrorWithMessage("Could not replace the existing store with migrated one. Abort")
                        }
                        do {
                            try fileManager.removeItemAtURL(backupUrl)
                        }
                        catch {
                            print("Could not delete backup at path: \(backupUrl.path)")
                        }
                    }
                    return didMigrate
                }
                catch let error {
                    throw error
                }
        }
    }
}

internal func logTextIfDebug(text: String!) {
    debugPrint("\(text)")
}