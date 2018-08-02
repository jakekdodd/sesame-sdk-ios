//
//  CoreDataManager.swift
//  Sesame
//
//  Created by Akash Desai on 7/29/18.
//

import Foundation
import CoreData

class CoreDataManager : NSObject {
    
    fileprivate var persistentContainerQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    override init() {
        super.init()
    }
    
    func enqueue(block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainerQueue.addOperation {
            let context = self.persistentContainer.newBackgroundContext()
            context.performAndWait {
                block(context)
                do {
                    try context.save()
                } catch {
                    Logger.debug(error: "Error while saving to Core Data:\(error as AnyObject)")
                }
            }
        }
    }
    
    lazy var persistentContainer: NSPersistentContainer = {
        let modelURL = Bundle(for: type(of: self)).url(forResource: "Sesame", withExtension: "momd")!
        let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)!
        let container = NSPersistentContainer(name: "Sesame", managedObjectModel: managedObjectModel)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
//    func saveContext () {
//        let context = persistentContainer.viewContext
//        if context.hasChanges {
//            do {
//                try context.save()
//            } catch {
//                // Replace this implementation with code to handle the error appropriately.
//                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//                let nserror = error as NSError
//                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
//            }
//        }
//    }
}
