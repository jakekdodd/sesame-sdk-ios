//
//  CoreDataManager.swift
//  Sesame
//
//  Created by Akash Desai on 7/29/18.
//

import Foundation
import CoreData


class CoreDataManager : NSObject, NSFetchedResultsControllerDelegate {
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls.last! as NSURL
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle(for: type(of: self)).url(forResource: "Sesame", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        var coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        let url = applicationDocumentsDirectory.appendingPathComponent("Sesame.sqlite")
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch {
            print(error)
        }
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        if let coordinator = persistentStoreCoordinator {
            var managedObjectContext = NSManagedObjectContext()
            managedObjectContext.persistentStoreCoordinator = coordinator
            return managedObjectContext
        } else {
            return nil
        }
    }()
    
    func saveContext() {
        if let moc = managedObjectContext {
            do {
                try moc.save()
            } catch {
                print(error)
            }
            
            print("Object count:\(fetchedResultsController.fetchedObjects?.count)")
        }
    }
    
    func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        fetchRequest.fetchBatchSize = 20
        return fetchRequest
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        let fetchRequest = self.fetchRequest()
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print(error)
        }
        
        return fetchedResultsController
        
    }()
}
//
//class CoreDataManager : NSObject {
//
//    fileprivate var persistentContainerQueue: OperationQueue = {
//        let queue = OperationQueue()
//        queue.maxConcurrentOperationCount = 1
//        return queue
//    }()
//
//    override init() {
//        super.init()
//    }
//
//    @available(iOS 10.0, *)
//    func enqueue(block: @escaping (NSManagedObjectContext) -> Void) {
//        persistentContainerQueue.addOperation {
//            let context = self.persistentContainer.newBackgroundContext()
//            context.performAndWait {
//                block(context)
//                do {
//                    try context.save()
//                } catch {
//                    Logger.debug(error: "Error while saving to Core Data:\(error as AnyObject)")
//                }
//            }
//        }
//    }
//
//    @available(iOS 10.0, *)
//    lazy var persistentContainer: NSPersistentContainer = {
//        let modelURL = Bundle(for: type(of: self)).url(forResource: "Sesame", withExtension: "momd")!
//        let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)!
//        let container = NSPersistentContainer(name: "Sesame", managedObjectModel: managedObjectModel)
//        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
//            if let error = error as NSError? {
//                fatalError("Unresolved error \(error), \(error.userInfo)")
//            }
//        })
//        return container
//    }()
//
////    func saveContext () {
////        let context = persistentContainer.viewContext
////        if context.hasChanges {
////            do {
////                try context.save()
////            } catch {
////                // Replace this implementation with code to handle the error appropriately.
////                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
////                let nserror = error as NSError
////                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
////            }
////        }
////    }
//}
