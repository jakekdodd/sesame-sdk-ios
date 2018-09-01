//
//  CoreDataManager.swift
//  Sesame
//
//  Created by Akash Desai on 7/29/18.
//

import Foundation
import CoreData

extension CoreDataManager {
    class Helper {

    }
}

class CoreDataManager: NSObject, NSFetchedResultsControllerDelegate {

    // MARK: - CoreData Objects

    /// The context is used only on this queue.
    /// All public facing methods are run synchronously on this queue if they return a result, asynchronously otherwise.
    /// Private methods called within public methods can use the queue asynchronously
    /// but not synchronously due to deadlock.
    fileprivate let queue = DispatchQueue(label: "Sesame.CoreDataManager")

    private lazy var managedObjectModel: NSManagedObjectModel? = {
        if let modelURL = Bundle(for: type(of: self)).url(forResource: "Sesame", withExtension: "momd"),
            let model = NSManagedObjectModel(contentsOf: modelURL) {
            return model
        }
        return nil
    }()

    private lazy var persistentStoreURL: URL? = {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last {
            return dir.appendingPathComponent("Sesame.sqlite")
        }
        return nil
    }()

    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        if let model = managedObjectModel,
            let persistentStoreURL = persistentStoreURL {
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)

            do {
                try coordinator.addPersistentStore(ofType: NSInMemoryStoreType,
                                                   configurationName: nil,
                                                   at: persistentStoreURL,
                                                   options: [NSInferMappingModelAutomaticallyOption: true,
                                                             NSMigratePersistentStoresAutomaticallyOption: true])
                return coordinator
            } catch {
                print(error)
            }
        }
        return nil
    }()

    fileprivate lazy var managedObjectContext: NSManagedObjectContext? = {
        if let coordinator = persistentStoreCoordinator {
            let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            managedObjectContext.persistentStoreCoordinator = coordinator
            return managedObjectContext
        }
        return nil
    }()

    // MARK: - Methods

    fileprivate func save() {
        queue.async {
            if self.managedObjectContext?.hasChanges ?? false {
                do {
                    try self.managedObjectContext?.save()
                } catch {
                    Logger.debug(error: "\(error)")
                }
            }
        }
    }

    func eraseAll() {
        queue.sync {
            let modelTypes = [Report.self, Event.self, User.self]
            for model in modelTypes {
                let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: model.description())
                do {
                    if let objects = try self.managedObjectContext?.fetch(fetchRequest) {
                        for object in objects {
                            self.managedObjectContext?.delete(object)
                        }
                    }
                } catch {
                    print(error)
                }
            }
            self.save()
        }

//        return nil

//
//        guard let model = managedObjectModel,
//            let persistentStoreURL = persistentStoreURL else {
//                return
//        }
//        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
//
//        do {
//            managedObjectContext?.dele
//            try coordinator.destroyPersistentStore(at: persistentStoreURL, ofType: NSSQLiteStoreType, options: nil)
//        } catch {
//            print(error)
//        }
    }

}

// MARK: - Model Specific Methods

extension CoreDataManager {

    // MARK: AppConfig

    func fetchAppConfig() -> AppConfig? {
        var value: AppConfig?

        queue.sync {
            let fetchRequest = NSFetchRequest<AppConfig>(entityName: "AppConfig")
            fetchRequest.fetchLimit = 1
            do {
                if let appConfig = try self.managedObjectContext?.fetch(fetchRequest).first {
                    value = appConfig
                } else if let managedObjectContext = self.managedObjectContext,
                    let appConfigEntity = NSEntityDescription.entity(forEntityName: "AppConfig",
                                                                     in: managedObjectContext),
                    let trackingCapabilitiesEntity = NSEntityDescription.entity(forEntityName: "TrackingCapabilities",
                                                                                in: managedObjectContext) {
                    let trackingCapabilities = TrackingCapabilities(entity: trackingCapabilitiesEntity,
                                                                    insertInto: managedObjectContext)
                    let appConfig = AppConfig(entity: appConfigEntity, insertInto: managedObjectContext)
                    appConfig.trackingCapabilities = trackingCapabilities

                    value = appConfig
                }
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        }
        return value
    }

    // MARK: User

//    func fetchUser(for id: String? = nil, createIfNotFound: Bool = true) -> User? {
//        let fetchRequest = NSFetchRequest<User>(entityName: "User")
//        if let id = id {
//            fetchRequest.predicate = NSPredicate(format: "id = '\(id)'")
//        }
//        fetchRequest.fetchLimit = 1
//        do {
//            if let user = try managedObjectContext?.fetch(fetchRequest).first {
//                return user
//            } else if createIfNotFound,
//                let managedObjectContext = managedObjectContext,
//                let entity = NSEntityDescription.entity(forEntityName: "User", in: managedObjectContext) {
//                let user = User(entity: entity, insertInto: managedObjectContext)
//                user.id = id ?? UUID().uuidString
//                return user
//            }
//        } catch let error as NSError {
//            print("Could not fetch. \(error), \(error.userInfo)")
//        }
//
//        return nil
//    }

    // MARK: Report

    func reports() -> [Report]? {
        var values: [Report]?

        queue.sync {
            let fetchRequest = NSFetchRequest<Report>(entityName: "Report")
            do {
                values = try managedObjectContext?.fetch(fetchRequest)
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        }

        return values
    }

    fileprivate func fetchReport(for actionId: String, createIfNotFound: Bool = true) -> Report? {
        var value: Report?

//        queue.sync {
            let fetchRequest = NSFetchRequest<Report>(entityName: "Report")
            fetchRequest.predicate = NSPredicate(format: "actionId = '\(actionId)'")
            fetchRequest.fetchLimit = 1
            do {
                if let report = try managedObjectContext?.fetch(fetchRequest).first {
                    value = report
                } else if createIfNotFound,
                    let managedObjectContext = managedObjectContext,
                    let entity = NSEntityDescription.entity(forEntityName: "Report", in: managedObjectContext) {
                    let report = Report(entity: entity, insertInto: managedObjectContext)
                    report.actionId = actionId
                    value = report
                }
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
//        }

        return value
    }

    func eraseReports() {

        queue.sync {
            let fetchRequest = NSFetchRequest<Report>(entityName: "Report")
            do {
                for report in try self.managedObjectContext?.fetch(fetchRequest) ?? [] {
                    self.managedObjectContext?.delete(report)
                }
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
            self.save()
        }

    }

    // MARK: Event

    func eventsCount() -> Int? {
        var value: Int?

        queue.sync {
            let fetchRequest = NSFetchRequest<Event>(entityName: "Event")
            do {
                value = try managedObjectContext?.count(for: fetchRequest)
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        }

        return value
    }

    func addEvent(for actionId: String, metadata: [String: Any] = [:]) {
        queue.sync {
            guard let managedObjectContext = self.managedObjectContext,
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

            Logger.debug("Logged event #\(report.events?.count ?? -1) with actionId:\(actionId)")
        }
    }

}
