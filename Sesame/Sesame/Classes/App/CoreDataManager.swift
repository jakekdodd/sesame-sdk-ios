//
//  CoreDataManager.swift
//  Sesame
//
//  Created by Akash Desai on 7/29/18.
//

import Foundation
import CoreData


class CoreDataManager : NSObject, NSFetchedResultsControllerDelegate {

    // MARK: - Members

    lazy var managedObjectModel: NSManagedObjectModel? = {
        if let modelURL = Bundle(for: type(of: self)).url(forResource: "Sesame", withExtension: "momd"),
            let model = NSManagedObjectModel(contentsOf: modelURL) {
            return model
        } else {
            return nil
        }
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        guard let model = managedObjectModel,
            let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last else {
                return nil
        }

        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let url = dir.appendingPathComponent("Sesame.sqlite")
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                               configurationName: nil,
                                               at: url,
                                               options: [NSInferMappingModelAutomaticallyOption: true,
                                                         NSMigratePersistentStoresAutomaticallyOption: true])
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

    // MARK: - Functions

    func fetchUser(for id: String? = nil, createIfNotFound: Bool = true) -> User? {
        let fetchRequest = NSFetchRequest<User>(entityName: "User")
        if let id = id {
            fetchRequest.predicate = NSPredicate(format: "id = '\(id)'")
        }
        fetchRequest.fetchLimit = 1
        do {
            if let user = try managedObjectContext?.fetch(fetchRequest).first {
                return user
            } else if createIfNotFound,
                let managedObjectContext = managedObjectContext,
                let entity = NSEntityDescription.entity(forEntityName: "User", in: managedObjectContext) {
                let user = User(entity: entity, insertInto: managedObjectContext)
                user.id = id ?? UUID().uuidString
                return user
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }

        return nil
    }

    fileprivate func fetchReport(for actionId: String, createIfNotFound: Bool = true) -> Report? {
        let fetchRequest = NSFetchRequest<Report>(entityName: "Report")
        fetchRequest.predicate = NSPredicate(format: "actionId = '\(actionId)'")
        fetchRequest.fetchLimit = 1
        do {
            if let report = try managedObjectContext?.fetch(fetchRequest).first {
                return report
            } else if createIfNotFound,
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
    
    func addEvent(for actionId: String) {
        guard let managedObjectContext = managedObjectContext,
            let report = fetchReport(for: actionId) else {
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

        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
                print("Saved coredata. Reported events for <\(actionId)>:<\(report.events?.count as AnyObject)>")
            } catch {
                Logger.debug(error: "\(error)")
            }
        }

        Logger.debug(confirmed: "Logged event:\(event.debugDescription)")
    }
}

extension Report {
    
    static let ACTION_APP_OPEN = "appOpen"
    static let ACTION_APP_CLOSE = "appClose"
    static let REINFORCEMENT_NUETRAL = "nuetral"
    
}
