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
    /// All public facing methods should run synchronously on this queue
    /// Private fetch methods should be sure not to include another fetch inside their queue block
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
                try coordinator.addPersistentStore(ofType: NSSQLiteStoreType,
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
            managedObjectContext.mergePolicy = NSRollbackMergePolicy
            return managedObjectContext
        }
        return nil
    }()

    // MARK: - Methods

    func save() {
        queue.sync {
            if self.managedObjectContext?.hasChanges ?? false {
                do {
                    try self.managedObjectContext?.save()
                } catch {
                    Logger.debug(error: "\(error)")
                }
            }
        }
    }

    func deleteObjects() {
        queue.sync {
            let modelTypes = [Report.self, Event.self, User.self]
            for model in modelTypes {
                let request = NSFetchRequest<NSManagedObject>(entityName: model.description())
                do {
                    if let objects = try self.managedObjectContext?.fetch(request) {
                        for object in objects {
                            self.managedObjectContext?.delete(object)
                        }
                    }
                } catch {
                    print(error)
                }
            }
        }

        save()
    }

}

// MARK: - Model Specific Methods

extension CoreDataManager {

    // MARK: AppConfig

    func fetchAppConfig() -> AppConfig? {
        var value: AppConfig?

        queue.sync {
            let request = NSFetchRequest<AppConfig>(entityName: "AppConfig")
            request.fetchLimit = 1
            do {
                if let appConfig = try self.managedObjectContext?.fetch(request).first {
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

    func fetchUser(for id: String?, createIfNotFound: Bool = true) -> User? {
        var value: User?

        queue.sync {
            let request = NSFetchRequest<User>(entityName: "User")
            request.predicate = NSPredicate(format: "id == \(id == nil ? "nil" : "'\(id!)'")")
            request.fetchLimit = 1
            do {
                if let user = try managedObjectContext?.fetch(request).first {
                    value = user
                } else if createIfNotFound,
                    let managedObjectContext = managedObjectContext,
                    let entity = NSEntityDescription.entity(forEntityName: "User", in: managedObjectContext) {
                    let user = User(entity: entity, insertInto: managedObjectContext)
                    user.fallbackId = UUID().uuidString
                    user.id = id
                    value = user
                }
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        }

        return value
    }

    // MARK: Report

    func fetchReports(userId: String?) -> [Report]? {
        var values: [Report]?

        queue.sync {
            let request = NSFetchRequest<Report>(entityName: "Report")
            request.predicate = NSPredicate(format: "user.id == \(userId == nil ? "nil" : "'\(userId!)'")")
            do {
                values = try managedObjectContext?.fetch(request)
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        }

        return values
    }

    func deleteReports(userId: String?) {
        queue.sync {
            let request = NSFetchRequest<Report>(entityName: "Report")
            request.predicate = NSPredicate(format: "user.id == \(userId == nil ? "nil" : "'\(userId!)'")")
            do {
                if let reports = try managedObjectContext?.fetch(request) {
                    Logger.debug("Deleting \(String(describing: reports.count)) events")
                    for report in reports {
                        managedObjectContext?.delete(report)
                    }
                }
            } catch {
                print(error)
            }
        }

        save()
    }

    private func fetchReport(userId: String?, actionId: String, createIfNotFound: Bool = true) -> Report? {
        var value: Report?

        queue.sync {
            let request = NSFetchRequest<Report>(entityName: "Report")
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "actionId = '\(actionId)'"),
                NSPredicate(format: "user.id = \(userId == nil ? "nil" : "'\(userId!)'")")
                ])
            request.fetchLimit = 1
            do {
                if let report = try managedObjectContext?.fetch(request).first {
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
        }

        if let report = value,
            report.user == nil {
            report.user = fetchUser(for: userId)
        }

        return value
    }

    // MARK: Event

    func countEvents(userId: String?) -> Int? {
        var value: Int?

        queue.sync {
            let request = NSFetchRequest<Event>(entityName: "Event")
            request.predicate = NSPredicate(format: "report.user.id == \(userId == nil ? "nil" : "'\(userId!)'")")
            do {
                value = try managedObjectContext?.count(for: request)
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        }

        return value
    }

    func insertEvent(userId: String?, actionId: String, metadata: [String: Any] = [:]) {
        guard let report = fetchReport(userId: userId, actionId: actionId) else { return }

        queue.sync {
            guard let managedObjectContext = self.managedObjectContext,
                let entity = NSEntityDescription.entity(forEntityName: "Event", in: managedObjectContext) else {
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

            Logger.debug("Logged event #\(report.events?.count ?? -1) with actionId:\(actionId)")
        }

        save()
    }

}
