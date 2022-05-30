//
//  DataShareManager.swift
//  Pirate
//
//  Created by hyperorchid on 2020/2/25.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit
import CoreData

class DataShareManager: NSObject {
        // MARK: - Initialization
        static let GroupIdentity = "group.com.star.theBigDipper"
        public static var sharedInstance = DataShareManager()
        
        func synced(_ lock: AnyObject, closure: () -> ()) {
                objc_sync_enter(lock)
                closure()
                objc_sync_exit(lock)
        }
        
        // MARK: - Core Data stack
        
        public let userDefault = UserDefaults(suiteName: GroupIdentity)!
        
        public lazy var containerURL:URL = {
                return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: DataShareManager.GroupIdentity)!
        }()
        
        lazy var applicationDocumentsDirectory: URL = {
                let urls = Foundation.FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                return urls[urls.count-1]
        }()
        
        lazy var managedObjectModel: NSManagedObjectModel = {
                let modelURL = Bundle.main.url(forResource: "SVN", withExtension: "momd")!
                return NSManagedObjectModel(contentsOf: modelURL)!
        }()
        
        lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
               
                var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
                let options = [
                        NSMigratePersistentStoresAutomaticallyOption: true,
                        NSInferMappingModelAutomaticallyOption: true
                ]
                let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: DataShareManager.GroupIdentity)!
                let url = directory.appendingPathComponent("Receipt.sqlite")
                do {
                        try coordinator!.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
                } catch var error as NSError {
                        coordinator = nil
                        NSLog("=======>Unresolved error \(error), \(error.userInfo)")
                        abort()
                } catch {
                        fatalError()
                }
                return coordinator
        }()
        
        // MARK: - NSManagedObject Contexts
        open class func mainQueueContext() -> NSManagedObjectContext {
                return self.sharedInstance.mainQueueCtxt!
        }
        
        open class func privateQueueContext() -> NSManagedObjectContext {
                return self.sharedInstance.privateQueueCtxt!
        }
        
        lazy var mainQueueCtxt: NSManagedObjectContext? = {
                var managedObjectContext = NSManagedObjectContext(concurrencyType:.mainQueueConcurrencyType)
                managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
                return managedObjectContext
        }()
        
        lazy var privateQueueCtxt: NSManagedObjectContext? = {
                var managedObjectContext = NSManagedObjectContext(concurrencyType:.privateQueueConcurrencyType)
                managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
                return managedObjectContext
        }()
        
        // MARK: - Core Data Saving support
        open class func saveContext(_ context: NSManagedObjectContext?) {
                if let moc = context {
                        if moc.hasChanges {
                                do {
                                        try moc.save()
                                } catch let err{
                                        NSLog("=======>+++++context save err:\(err.localizedDescription)")
                                }
                        }
                }
        }
        open class func syncContext(_ context: NSManagedObjectContext?, obj:NSManagedObject) {
                if let moc = context {
                        moc.refresh(obj, mergeChanges: true)
                }
        }
        open class func syncAllContext(_ context: NSManagedObjectContext?) {
                if let moc = context {
                        moc.refreshAllObjects()
                }
        }
}

extension NSManagedObject {
        
        public class func findEntity(_ entityName: String, where w:NSPredicate? = nil, orderBy:[NSSortDescriptor]? = nil, context: NSManagedObjectContext) -> [AnyObject]? {
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                request.predicate = w
                let result: [AnyObject]?
                do {
                        result = try context.fetch(request)
                } catch let error as NSError {
                        print(error)
                        result = nil
                }
                return result
        }
        
        public class func findAllForEntity(_ entityName: String, context: NSManagedObjectContext) -> [AnyObject]? {
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let result: [AnyObject]?
                do {
                        result = try context.fetch(request)
                } catch let error as NSError {
                        print(error)
                        result = nil
                }
                return result
        }
        
        public class func findOneEntity(_ entityName: String, where w:NSPredicate?=nil, context: NSManagedObjectContext) -> AnyObject? {
                
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                
                request.fetchLimit = 1
                request.predicate = w
                
                let result: AnyObject?
                do {
                        let ret = try context.fetch(request)
                        
                        return ret.last as AnyObject?
                } catch let error as NSError {
                        print(error)
                        result = nil
                }
                return result
        }
}
