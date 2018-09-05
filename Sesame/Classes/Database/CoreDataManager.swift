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
    /// All methods that use `managedObjectContext` should run synchronously on this queue.
    /// This means fetch methods should be sure not to include calls to other fetches inside their queue block.
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
            if managedObjectContext?.hasChanges ?? false {
                do {
                    try managedObjectContext?.save()
                } catch {
                    Logger.debug(error: "\(error)")
                }
            }
        }
    }

    func deleteObjects() {
        queue.sync {
            let rootModels = [User.self, AppConfig.self]
            for model in rootModels {
                let request = NSFetchRequest<NSManagedObject>(entityName: model.description())
                do {
                    if let objects = try managedObjectContext?.fetch(request) {
                        for object in objects {
                            managedObjectContext?.delete(object)
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

    func fetchAppConfig(_ configId: String? = nil) -> AppConfig? {
        var value: AppConfig?

        queue.sync {
            let request = NSFetchRequest<AppConfig>(entityName: AppConfig.description())
            let configIdValue = "\(configId == nil ? "nil" : "'\(configId!)'")"
            request.predicate = NSPredicate(format: "\(#keyPath(AppConfig.configId)) == \(configIdValue)")
            request.fetchLimit = 1
            do {
                if let appConfig = try managedObjectContext?.fetch(request).first {
                    value = appConfig
                } else if let managedObjectContext = managedObjectContext,
                    let appConfigEntity = NSEntityDescription.entity(forEntityName: AppConfig.description(),
                                                                     in: managedObjectContext) {
                    let appConfig = AppConfig(entity: appConfigEntity, insertInto: managedObjectContext)
                    appConfig.configId = configId
                    value = appConfig
                }
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        }

        return value
    }

    // MARK: User

    func fetchUser(for id: String, createIfNotFound: Bool = true) -> User? {
        var value: User?

        queue.sync {
            let request = NSFetchRequest<User>(entityName: User.description())
            request.predicate = NSPredicate(format: "\(#keyPath(User.id)) == '\(id)'")
            request.fetchLimit = 1
            do {
                if let user = try managedObjectContext?.fetch(request).first {
                    value = user
                } else if createIfNotFound,
                    let managedObjectContext = managedObjectContext,
                    let entity = NSEntityDescription.entity(forEntityName: User.description(),
                                                            in: managedObjectContext) {
                    let user = User(entity: entity, insertInto: managedObjectContext)
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

    func fetchReports(userId: String) -> [Report]? {
        var values: [Report]?

        queue.sync {
            let request = NSFetchRequest<Report>(entityName: Report.description())
            request.predicate = NSPredicate(format: "\(#keyPath(Report.user.id)) == '\(userId)'")
            do {
                values = try managedObjectContext?.fetch(request)
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        }

        return values
    }

    func deleteReports(userId: String) {
        queue.sync {
            let request = NSFetchRequest<Report>(entityName: Report.description())
            request.predicate = NSPredicate(format: "\(#keyPath(Report.user.id)) == '\(userId)'")
            do {
                if let reports = try managedObjectContext?.fetch(request) {
                    Logger.debug("Deleting \(reports.count) events")
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

    private func fetchReport(userId: String, actionId: String, createIfNotFound: Bool = true) -> Report? {
        var value: Report?

        queue.sync {
            let request = NSFetchRequest<Report>(entityName: Report.description())
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "\(#keyPath(Report.actionId)) == '\(actionId)'"),
                NSPredicate(format: "\(#keyPath(Report.user.id)) == '\(userId)'")
                ])
            request.fetchLimit = 1
            do {
                if let report = try managedObjectContext?.fetch(request).first {
                    value = report
                } else if createIfNotFound,
                    let managedObjectContext = managedObjectContext,
                    let entity = NSEntityDescription.entity(forEntityName: Report.description(),
                                                            in: managedObjectContext) {
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

    func countEvents(userId: String? = nil) -> Int? {
        var value: Int?

        queue.sync {
            let request = NSFetchRequest<Event>(entityName: Event.description())
            if let userId = userId {
                request.predicate = NSPredicate(format: "\(#keyPath(Event.report.user.id)) == '\(userId)'")
            }
            do {
                value = try managedObjectContext?.count(for: request)
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        }

        return value
    }

    func insertEvent(userId: String, actionId: String, metadata: [String: Any] = [:]) {
        guard let report = fetchReport(userId: userId, actionId: actionId) else { return }

        queue.sync {
            guard let managedObjectContext = managedObjectContext,
                let entity = NSEntityDescription.entity(forEntityName: Event.description(),
                                                        in: managedObjectContext) else {
                Logger.debug(error: "Could not create entity for event")
                return
            }

            let event = Event(entity: entity, insertInto: managedObjectContext)
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
