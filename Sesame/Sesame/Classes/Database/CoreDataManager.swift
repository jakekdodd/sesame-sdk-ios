//
//  CoreDataManager.swift
//  Sesame
//
//  Created by Akash Desai on 7/29/18.
//

import Foundation
import CoreData


class CoreDataManager : NSObject, NSFetchedResultsControllerDelegate {

    // MARK: - CoreData Objects

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

    // MARK: - Methods

    func save() {
        if managedObjectContext?.hasChanges ?? false {
            do {
                try managedObjectContext?.save()
            } catch {
                Logger.debug(error: "\(error)")
            }
        }
    }

    // MARK: AppConfig

    func fetchAppConfig() -> AppConfig? {
        let fetchRequest = NSFetchRequest<AppConfig>(entityName: "AppConfig")
        fetchRequest.fetchLimit = 1
        do {
            if let appConfig = try managedObjectContext?.fetch(fetchRequest).first {
                return appConfig
            } else if let managedObjectContext = managedObjectContext,
                let appConfigEntity = NSEntityDescription.entity(forEntityName: "AppConfig", in: managedObjectContext),
                let trackingCapabilitiesEntity = NSEntityDescription.entity(forEntityName: "TrackingCapabilities", in: managedObjectContext)
            {
                let trackingCapabilities = TrackingCapabilities(entity: trackingCapabilitiesEntity, insertInto: managedObjectContext)
                let appConfig = AppConfig(entity: appConfigEntity, insertInto: managedObjectContext)
                appConfig.trackingCapabilities = trackingCapabilities

                return appConfig
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }

        return nil
    }

    // MARK: User

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

    // MARK: Report

    func reports() -> [Report]? {
        let fetchRequest = NSFetchRequest<Report>(entityName: "Report")

        do {
            if let events = try managedObjectContext?.fetch(fetchRequest) {
                return events
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

    // MARK: Event
    
    func addEvent(for actionId: String, metadata: [String: Any] = [:]) {
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
        event.utc = Int64(Date().timeIntervalSince1970 * 1000)
        event.timezoneOffset = Int64(NSTimeZone.default.secondsFromGMT() * 1000)
        do {
            event.metadata = String(data: try JSONSerialization.data(withJSONObject: metadata),
                                    encoding: .utf8)
        } catch {
            print(error)
        }
        event.report = report
        save()
        print("Saved coredata. Reported events for <\(actionId)>:<\(report.events?.count as AnyObject)>")

        Logger.debug(confirmed: "Logged event:\(event.debugDescription)")
    }

}

extension Report {
    
    static let ACTION_APP_OPEN = "appOpen"
    static let ACTION_APP_CLOSE = "appClose"
    static let REINFORCEMENT_NUETRAL = "nuetral"
    
}
