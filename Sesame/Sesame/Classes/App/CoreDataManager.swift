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

extension CoreDataManager {
    
    func fetchTrackReport(actionId: String, create: Bool = true) -> Report? {
        let fetchRequest = NSFetchRequest<Report>(entityName: "Report")
        fetchRequest.predicate = NSPredicate(format: "actionId = '\(actionId)'")
        fetchRequest.fetchLimit = 1
        do {
            if let report = try managedObjectContext?.fetch(fetchRequest).first {
                return report
            } else if create,
                let managedObjectContext = managedObjectContext,
                let entity = NSEntityDescription.entity(forEntityName: "Report", in: managedObjectContext) {
                let report = Report(entity: entity, insertInto: managedObjectContext)
                report.actionId = actionId
                return report
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        return nil
    }
    
    func addEvent(_ actionId: String) {
        guard let managedObjectContext = managedObjectContext,
            let report = fetchTrackReport(actionId: actionId) else {
            Logger.debug(error: "Could not create report for actionId:\(actionId)")
            return
        }
        
        guard let entity = NSEntityDescription.entity(forEntityName: "Event", in: managedObjectContext) else {
            Logger.debug(error: "Could not create entity for event")
            return
        }
        
        let event = Event(entity: entity, insertInto: managedObjectContext)
        event.utc = Date()
        event.report = report
        
        do {
            try managedObjectContext.save()
            print("Saved coredata. Reported events for <\(actionId)>:<\(report.events?.count as AnyObject)>")
        } catch {
            Logger.debug(error: "\(error)")
        }
    }
}

extension Report {
    
    static let ACTION_APP_OPEN = "appOpen"
    static let ACTION_APP_CLOSE = "appClose"
    static let REINFORCEMENT_NUETRAL = "nuetral"
    
}
