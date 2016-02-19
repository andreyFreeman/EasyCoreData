//
//  ManagedObjectContext.swift
//  EasyCoreData
//
//  Created by Andrey Kladov on 02/04/15.
//  Copyright (c) 2015 Andrey Kladov. All rights reserved.
//

import Foundation
import CoreData

public extension NSManagedObjectContext {
    
    private struct StaticStorage {
        static weak var customMainThreadManagedObjectContext: NSManagedObjectContext!
    }
    
    /**
     
     if you are going to use your own NSManagedObjectContext, but still want to use NSManagedObjectContext and NSManagedObject extensions, you can setup it here
     **Warning! Weak reference will be stored. Stored NSManagedObjectContext will be overwritten by 'EasyCoreData.setup()' call**

     - parameter context: context you would like to use as a main thread context with this EasyCoreData extensions. *
     
     */
    public class func setupMainThreadManagedObjectContext(context: NSManagedObjectContext!) {
        StaticStorage.customMainThreadManagedObjectContext = context
    }
    
}

public extension NSManagedObjectContext {
    /**
     
     Main NSManagedObjectContext will be returned. See EasyCoreData.sharedInstance.mainThreadManagedObjectContext for more information.
     If method setupMainThreadManagedObjectContext was used, custom NSManagedObjectContext will be returned
     
     */
    class var mainThreadContext: NSManagedObjectContext! {
        return StaticStorage.customMainThreadManagedObjectContext ?? EasyCoreData.sharedInstance.mainThreadManagedObjectContext
    }
    
    /**
     
     tempolorary child NSManagedObjectContext for mainThreadContext will be returned
     
     */
    class var temporaryMainThreadContext: NSManagedObjectContext! { return mainThreadContext.createChildContext() }
}

public extension NSManagedObjectContext {
    /**
     
     Creates a new instance of NSManagedObject subclass with given type
     
     - returns: created object of given type T or nil
     
     */
    func createEntity<T: NSManagedObject>() -> T! {
        return T(entity: T.entityDescription(inContext: self), insertIntoManagedObjectContext: self)
    }
}

public extension NSManagedObjectContext {
    
    /**
     
     Must be used for creation, updating or deletion of instances of NSManagedObject subclasses in the background. All changed will be saved to all parent contexts as well
     
     - parameter saveFunction: The function will be called to perform changes. All changes must be done in the localContext which is passed to this function as a parameter
     
     - parameter completion: The function will be called on the Main thread once save operation finished. Can update UI here
     
     */
    
    func saveDataInBackground(saveFunction: (localContext: NSManagedObjectContext) -> Void, completion: (() -> Void)?) {
        let context = createChildContext(.PrivateQueueConcurrencyType)
        context.performBlock {
            saveFunction(localContext: context)
            switch context.hasChanges {
            case true: context.saveWithCompletion(completion)
            default: dispatch_async(dispatch_get_main_queue()) { _ in completion?() }
            }
        }
    }
    
    /**
     
     Must be used for creation, updating or deletion of instances of NSManagedObject subclasses in the background. All changes will be saved to all parent contexts as well
     
     - parameter saveFunction: The function will be called to perform changes. All changes must be done in the localContext which is passed to this function as a parameter
     
     - parameter completion: The function will be called on the Main thread once save operation finished. Can update UI here
     
     */
    class func saveDataInBackground(saveFunction: (localContext: NSManagedObjectContext) -> Void, completion: (() -> Void)?) {
        mainThreadContext.saveDataInBackground(saveFunction, completion: completion)
    }
    
    /**
     
     Save current NSManagedObject state and merge changes into parent NSManagedObjectContent if exists
     
     - parameter completion: The function will be called once save operation finished
     
     */
    func saveWithCompletion(completion:(() -> Void)?) {
        performBlock {
            do {
                try self.save()
                switch self.parentContext {
                case .Some(let context): context.saveWithCompletion(completion)
                default: dispatch_async(dispatch_get_main_queue()) { _ in completion?(); return }
                }
            } catch let error as NSError {
                logTextIfDebug("\(error)")
                completion?()
            } catch {
                fatalError()
            }
        }
    }
    
    /**
     
     Must be used for creation, updating or deletion of NSManagedObject subclasses instances on the Main thread
     
     - parameter saveFunction: The function will be called to perform changes
     
     */
    class func saveDataWithBlock(saveFunction: () -> Void) {
        mainThreadContext.performBlockAndWait {
            saveFunction()
            do { try self.mainThreadContext.save(); do {
                try self.mainThreadContext.parentContext?.save()
            } catch let error as NSError {
                logTextIfDebug("\(error)")
                }
            } catch let error as NSError {
                logTextIfDebug("\(error)")
            } catch {
                fatalError()
            }
        }
    }
}

public extension NSManagedObjectContext {
    /**
     
     Creates a new instance of NSManagedObjectContext which is child for the current one
     
     - parameter concurrencyType: concurrency type of the new NSManagedObjectContext. The default value is MainQueueConcurrencyType
     
     - returns: a new instance is NSManagedObjectContext
     
     */
    func createChildContext(concurrencyType: NSManagedObjectContextConcurrencyType = .MainQueueConcurrencyType) -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: concurrencyType)
        context.parentContext = self
        return context
    }
}

public extension NSManagedObjectContext {
    /**
     
     Fetches the instances of NSManagedObject subclasses from CoreData storage
     
     - parameter entity: type of NSManagedObject subclass
     - parameter predicate: default value is nil
     - parameter sortDescriptors: default value is nil
     - returns: array of objects given type T or empty array
     
     */
    func fetchObjects<T: NSManagedObject>(entity: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, fetchLimit: Int? = nil, fetchBatchSize: Int? = nil) -> [T] {
        let request = NSFetchRequest(entityName: entity.entityName)
        request.sortDescriptors = sortDescriptors
        request.predicate = predicate
        if let limit = fetchLimit { request.fetchLimit = limit }
        if let batchSize = fetchBatchSize { request.fetchBatchSize = batchSize }
        do {
            guard let items = try executeFetchRequest(request) as? [T] else { return [T]() }
            return items
        } catch let error as NSError {
            logTextIfDebug("executeFetchRequest error: \(error)")
        }
        return [T]()
    }
    
    /**
     
     Fetches the instance of NSManagedObject subclass from CoreData storage
     
     - parameter entity: type of NSManagedObject subclass
     - parameter predicate: default values is nil
     - parameter sortDescriptors: The default value is nil
     - returns: optional object or nil of given type T
     
     */
    func fetchFirstOne<T: NSManagedObject>(entity: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) -> T? {
        return fetchObjects(entity, predicate: predicate, sortDescriptors: sortDescriptors, fetchLimit: 1).first
    }
}

public extension NSManagedObjectContext {
    /**
     
     Fetches NSManagedObject instance from other context in current
     
     - parameter entity: The instance of NSManagedObject for lookup in context
     - returns: The instance is NSManagedObject in the current context
     
     */
    func entityFromOtherContext<T: NSManagedObject>(entity: T) -> T? {
        return objectWithID(entity.objectID) as? T
    }
}

@available(iOS 8.0, *)
public extension NSManagedObjectContext {
    /**
     
     Fetches the instances of NSManagedObject subclasses from CoreData storage asynchronously
     
     - parameter entity: type of the objects needs to be fetched
     - parameter predicate: default values is nil
     - parameter sortDescriptors: The default value is nil
     - returns: array of objects given type T or empty array
     
     */
    func fetchObjectsAsynchronously<T: NSManagedObject>(entity: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, completion: (([T]) -> Void)?) {
        let request = NSFetchRequest(entityName: entity.entityName)
        request.sortDescriptors = sortDescriptors
        request.predicate = predicate
        let asyncRequest = NSAsynchronousFetchRequest(fetchRequest: request) { result in
            var results = [T]()
            if let res = result.finalResult as? [T] { results = res }
            completion?(results)
        }
        performBlock {
            do {
                try self.executeRequest(asyncRequest)
            } catch let error as NSError {
                logTextIfDebug("fetchObjectsAsynchronously error: \(error)")
            } catch {
                fatalError()
            }
        }
    }
}