//
//  ManagedObject.swift
//  EasyCoreData
//
//  Created by Andrey Kladov on 02/04/15.
//  Copyright (c) 2015 Andrey Kladov. All rights reserved.
//

import Foundation
import CoreData

public extension NSManagedObject {
    /**
     
     The name of the NSManagedObject subclass drop the module name
     
     */
    class var entityName: String! {
        return NSStringFromClass(self).componentsSeparatedByString(".").last
    }
    
    /**
     
     NSEntityDescription in the given context
     
     - parameter inContext: The default value is NSManagedObjectContext.mainThreadContext
     - returns: NSEntityDescription object or nil
     
     */
    class func entityDescription(inContext context: NSManagedObjectContext = NSManagedObjectContext.mainThreadContext) -> NSEntityDescription! {
        switch entityName {
        case .Some(let name): return NSEntityDescription.entityForName(name, inManagedObjectContext: context)
        default: return nil
        }
    }
}

public extension NSManagedObject {
    /**
     
     Creates new NSManagedObject instance in the given context
     
     - parameter inContext: The default value is NSManagedObjectContext.mainThreadContext
     - returns: New NSManagedObject instance or nil
     
     */
    class func createEntity(inContext context: NSManagedObjectContext = NSManagedObjectContext.mainThreadContext) -> NSManagedObject! {
        switch entityName {
        case .Some(let name): return NSEntityDescription.insertNewObjectForEntityForName(name, inManagedObjectContext: context)
        default: return nil
        }
    }
}

public extension NSManagedObject {
    /**
     
     Deletes NSManagedObject instance in the given context
     
     - parameter inContext: The default value is NSManagedObjectContext.mainThreadContext
     
     */
    func deleteEntity(inContext context: NSManagedObjectContext = NSManagedObjectContext.mainThreadContext) {
        context.deleteObject(self)
    }
    
    /**
     
     Deletes all NSManagedObject instances in the given context
     
     - parameter predicate: The default value is nil
     - parameter inContext: The default value is NSManagedObjectContext.mainThreadContext
     
     */
    class func deleteAll(predicate: NSPredicate? = nil, inContext context: NSManagedObjectContext = NSManagedObjectContext.mainThreadContext) {
        for obj in context.fetchObjects(self, predicate: predicate) {
            obj.deleteEntity(inContext: context)
        }
    }
}

public extension NSManagedObject {
    /**
     
     Fetches NSManagedObject instance in the given context
     
     - parameter context: The instance of NSManagedObjectContext
     - returns: The instance is NSManagedObject in the given context
     
     */
    func inContext(context: NSManagedObjectContext) -> NSManagedObject? {
        return context.entityFromOtherContext(self)
    }
}

public extension NSManagedObject {
    /**
     
     Fetches NSManagedObject instances in the given context matching the predicate and sorted
     
     - parameter predicate: The default value is nil
     - parameter sortDescriptors: The default value is nil
     - parameter inContext: The default value is NSManagedObjectContext.mainThreadContext
     - returns: The array of the instances of NSManagedObject or empty array
     
     */
    class func findAll(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, inContext context: NSManagedObjectContext = NSManagedObjectContext.mainThreadContext) -> [NSManagedObject] {
        return context.fetchObjects(self, predicate: predicate, sortDescriptors: sortDescriptors)
    }
    
    /**
     
     Fetches first NSManagedObject instance in the given context matching the predicate and sorted
     
     - parameter predicate: The default value is nil
     - parameter sortDescriptors: The default value is nil
     - parameter inContext: The default value is NSManagedObjectContext.mainThreadContext
     - returns: NSManagedObject instance or nil
     
     */
    class func findFirstOne(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, inContext context: NSManagedObjectContext = NSManagedObjectContext.mainThreadContext) -> NSManagedObject? {
        return context.fetchFirstOne(self, predicate: predicate, sortDescriptors: sortDescriptors)
    }
    
    /**
     
     Counts the number of the instances of NSManagedObject subclass in the given context matching the predicate
     
     - parameter predicate: The default value is nil
     - parameter inContext: The default value is NSManagedObjectContext.mainThreadContext
     - returns: The number of existing entities
     
     */
    class func countOfEntities(predicate: NSPredicate? = nil, inContext context: NSManagedObjectContext = NSManagedObjectContext.mainThreadContext) -> Int {
        let request = NSFetchRequest(entityName: entityName)
        request.predicate = predicate
        return context.countForFetchRequest(request, error: nil)
    }
    
    /**
     
     Checks is at least one entity of NSManagedObject subclass exists in the given context matching the predicate
     
     - parameter predicate: The default value is nil
     - parameter inContext: The default value is NSManagedObjectContext.mainThreadContext
     - returns: true if at least one entity exists
     
     */
    class func hasAtLeastOneEntity(predicate: NSPredicate? = nil, inContext context: NSManagedObjectContext = NSManagedObjectContext.mainThreadContext) -> Bool {
        return countOfEntities(predicate, inContext: context) > 0
    }
}

public extension NSManagedObject {
    /**
     
     Preforms the aggregation operation on given attribute with the predicate in the given context
     
     - parameter function: The name of the funtion to invoke
     - parameter attribute: The key path that the new expression should evaluate
     - parameter predicate: The default value is nil
     - parameter context: The default value is NSManagedObjectContext.mainThreadContext
     - returns: The result of the function as NSNumber object or nil
     
     */
    class func aggregateOperation(function: String, onAttribute attribute: String, predicate: NSPredicate? = nil, context: NSManagedObjectContext = NSManagedObjectContext.mainThreadContext) -> NSNumber? {
        let expression = NSExpression(forFunction: function, arguments: [NSExpression(forKeyPath: attribute)])
        let expressionDescription = NSExpressionDescription()
        expressionDescription.name = "result"
        expressionDescription.expression = expression
        expressionDescription.expressionResultType = .DoubleAttributeType
        let properties = [expressionDescription]
        let request = NSFetchRequest()
        request.propertiesToFetch = properties
        request.resultType = .DictionaryResultType
        request.predicate = predicate
        request.entity = entityDescription(inContext: context)
        do {
            return try context.executeFetchRequest(request).first?["result"] as? NSNumber
        } catch {
            return nil
        }
    }
}
