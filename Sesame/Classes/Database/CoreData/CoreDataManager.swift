//
//  CoreDataManager.swift
//  Sesame
//
//  Created by Akash Desai on 7/29/18.
//

import Foundation
import CoreData

class CoreDataManager: NSObject {

    // MARK: - CoreData Objects

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
                BMSLog.error(error)
            }
        }
        return nil
    }()

    private lazy var managedObjectContext: NSManagedObjectContext? = {
        if let coordinator = persistentStoreCoordinator {
            let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            managedObjectContext.persistentStoreCoordinator = coordinator
            managedObjectContext.mergePolicy = NSOverwriteMergePolicy
            // Setup notifications
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(saveChanges(_:)),
                                                   name: UIApplication.didEnterBackgroundNotification,
                                                   object: nil)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(saveChanges(_:)),
                                                   name: UIApplication.willTerminateNotification,
                                                   object: nil)
            return managedObjectContext
        }
        return nil
    }()

    func newContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = managedObjectContext
        return context
    }

    // MARK: - Save & Delete Methods

    @objc
    func saveChanges(_ notification: Notification?) {
        managedObjectContext?.perform {
            if self.managedObjectContext?.hasChanges ?? false {
                do {
                    try self.managedObjectContext?.save()
                } catch {
                    BMSLog.error("\(error)")
                }
            }
        }
    }

    func save() {
        managedObjectContext?.performAndWait {
            if managedObjectContext?.hasChanges ?? false {
                do {
                    try managedObjectContext?.save()
                } catch {
                    BMSLog.error("\(error)")
                }
            }
        }
    }

    func deleteObjects() {
        managedObjectContext?.performAndWait {
            let rootModels = [BMSUser.self, BMSAppState.self]
            for model in rootModels {
                let request = NSFetchRequest<NSManagedObject>(entityName: model.description())
                do {
                    if let objects = try managedObjectContext?.fetch(request) {
                        for object in objects {
                            managedObjectContext?.delete(object)
                        }
                    }
                } catch {
                    BMSLog.error(error)
                }
            }
            save()
        }
    }

}

// MARK: - Model Specific Methods

extension CoreDataManager {

    // MARK: AppState

    func fetchAppState(context: NSManagedObjectContext?, _ configId: String?, createIfNotFound: Bool = true) -> BMSAppState? {
        var value: BMSAppState?
        let context = context ?? newContext()
        context.performAndWait {
            let request = NSFetchRequest<BMSAppState>(entityName: BMSAppState.description())
            request.predicate = NSPredicate(format: "\(#keyPath(BMSAppState.configId)) == \(configId.predicateValue)")
            request.fetchLimit = 1
            do {
                if let appState = try context.fetch(request).first {
                    value = appState
                } else if createIfNotFound,
                    let appStateEntity = NSEntityDescription.entity(forEntityName: BMSAppState.description(),
                                                                           in: context) {
                    let appState = BMSAppState(entity: appStateEntity, insertInto: context)
                    appState.configId = configId
                    value = appState
                }
            } catch let error as NSError {
                BMSLog.error("Could not fetch. \(error)")
            }
        }

        return value
    }

    // MARK: User

    func fetchUser(context: NSManagedObjectContext?, id: String, createIfNotFound: Bool = true) -> BMSUser? {
        var value: BMSUser?
        let context = context ?? newContext()
        context.performAndWait {
            let request = NSFetchRequest<BMSUser>(entityName: BMSUser.description())
            request.predicate = NSPredicate(format: "\(#keyPath(BMSUser.id)) == '\(id)'")
            request.fetchLimit = 1
            do {
                if let user = try context.fetch(request).first {
                    value = user
                } else if createIfNotFound,
                    let entity = NSEntityDescription.entity(forEntityName: BMSUser.description(),
                                                            in: context) {
                    let user = BMSUser(entity: entity, insertInto: context)
                    user.id = id
                    value = user
                }
            } catch let error as NSError {
                BMSLog.error("Could not fetch. \(error)")
            }
        }

        return value
    }

    // MARK: Report

    private func fetchReport(context: NSManagedObjectContext?, userId: String, actionName: String, createIfNotFound: Bool = true) -> BMSReport? {
        var value: BMSReport?
        let context = context ?? newContext()
        context.performAndWait {
            let request = NSFetchRequest<BMSReport>(entityName: BMSReport.description())
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "\(#keyPath(BMSReport.actionName)) == '\(actionName)'"),
                NSPredicate(format: "\(#keyPath(BMSReport.user.id)) == '\(userId)'")
                ])
            request.fetchLimit = 1
            do {
                if let report = try context.fetch(request).first {
                    value = report
                } else if createIfNotFound,
                    let user = fetchUser(context: context, id: userId),
                    let entity = NSEntityDescription.entity(forEntityName: BMSReport.description(), in: context) {
                    let report = BMSReport(entity: entity, insertInto: context)
                    report.actionName = actionName
                    report.user = user
                    value = report
                }
            } catch {
                BMSLog.error("Could not fetch. \(error)")
            }
        }

        return value
    }

    func fetchReports(context: NSManagedObjectContext?, userId: String) -> [BMSReport]? {
        var values: [BMSReport]?
        let context = context ?? newContext()
        context.performAndWait {
            let request = NSFetchRequest<BMSReport>(entityName: BMSReport.description())
            request.predicate = NSPredicate(format: "\(#keyPath(BMSReport.user.id)) == '\(userId)'")
            do {
                values = try context.fetch(request)
            } catch let error as NSError {
                BMSLog.error("Could not fetch. \(error)")
            }
        }

        return values
    }

    func deleteReports(context: NSManagedObjectContext?, userId: String) {
        let context = context ?? newContext()
        context.performAndWait {
            let request = NSFetchRequest<BMSReport>(entityName: BMSReport.description())
            request.predicate = NSPredicate(format: "\(#keyPath(BMSReport.user.id)) == '\(userId)'")
            do {
                let reports = try context.fetch(request)
                for report in reports {
                    context.delete(report)
                }
                try context.save()
                save()
            } catch {
                BMSLog.error(error)
            }
        }
    }

    // MARK: Event

    func insertEvent(context: NSManagedObjectContext?, userId: String, actionName: String, sessionId: NSNumber?, metadata: [String: Any] = [:]) {
        let context = context ?? newContext()
        context.performAndWait {
            guard let report = fetchReport(context: context, userId: userId, actionName: actionName),
                let entity = NSEntityDescription.entity(forEntityName: BMSEvent.description(), in: context) else {
                    return
            }
            let event = BMSEvent(entity: entity, insertInto: context)
            do {
                event.sessionId = sessionId
                event.metadata = String(data: try JSONSerialization.data(withJSONObject: metadata), encoding: .utf8)
            } catch {
                BMSLog.error(error)
            }
            event.report = report
            do {
                try context.save()
                save()
//                BMSLog.debug("Logged event #\(report.events?.count ?? -1) with actionName:\(actionName)")
            } catch {
                BMSLog.error(error)
            }
        }
    }

    func countEvents(context: NSManagedObjectContext?, userId: String? = nil) -> Int? {
        var value: Int?
        let context = context ?? newContext()
        context.performAndWait {
            let request = NSFetchRequest<BMSEvent>(entityName: BMSEvent.description())
            if let userId = userId {
                request.predicate = NSPredicate(format: "\(#keyPath(BMSEvent.report.user.id)) == '\(userId)'")
            }
            do {
                value = try context.count(for: request)
            } catch let error as NSError {
                BMSLog.error("Could not fetch. \(error)")
            }
        }

        return value
    }

    // MARK: Cartridge

    func insertCartridge(context: NSManagedObjectContext?, userId: String, actionName: String, effectDetails: [String: Any]) {
        let context = context ?? newContext()
        context.performAndWait {
            guard let user = fetchUser(context: context, id: userId) else { return }
            guard let entity = NSEntityDescription.entity(forEntityName: BMSCartridge.description(), in: context) else {
                BMSLog.error("Could not create entity for cartridge")
                return
            }
            let cartridge = BMSCartridge(entity: entity, insertInto: context)
            cartridge.actionName = actionName
            cartridge.effectDetailsAsDictionary = effectDetails
            cartridge.user = user
            do {
                try context.save()
                save()
            } catch {
                BMSLog.error(error)
            }
        }
    }

    //swiftlint:disable:next function_parameter_count
    func updateCartridge(context: NSManagedObjectContext?, userId: String, actionName: String, cartridgeId: String, serverUtc: Int64, ttl: Int64, reinforcements: [String], effectDetails: [String: Any]? = nil) {
        let context = context ?? newContext()
        context.performAndWait {
            var storedCartridge: BMSCartridge?
            if let cartridge = fetchCartridge(context: context, userId: userId, actionName: actionName) {
                storedCartridge = cartridge
            } else if let user = fetchUser(context: context, id: userId),
                let entity = NSEntityDescription.entity(forEntityName: BMSCartridge.description(), in: context) {
                let cartridge = BMSCartridge(entity: entity, insertInto: context)
                cartridge.user = user
                cartridge.actionName = actionName
                cartridge.effectDetailsAsDictionary = effectDetails ?? [:]
            }

            guard let cartridge = storedCartridge else { return }
            cartridge.cartridgeId = cartridgeId
            cartridge.serverUtc = serverUtc
            cartridge.ttl = ttl
            if let effectDetails = effectDetails {
                cartridge.effectDetailsAsDictionary = effectDetails
            }

            for reinforcementName in reinforcements {
                guard let entity =
                    NSEntityDescription.entity(forEntityName: BMSReinforcement.description(), in: context)
                    else { continue }
                let reinforcement = BMSReinforcement(entity: entity, insertInto: context)
                reinforcement.name = reinforcementName
                cartridge.addToReinforcements(reinforcement)
            }

            do {
                try context.save()
                save()
            } catch {
                BMSLog.error(error)
            }
        }
    }

    func fetchCartridge(context: NSManagedObjectContext?, userId: String, actionName: String) -> BMSCartridge? {
        var value: BMSCartridge?
        let context = context ?? newContext()
        context.performAndWait {
            let request = NSFetchRequest<BMSCartridge>(entityName: BMSCartridge.description())
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "\(#keyPath(BMSCartridge.user.id)) == '\(userId)'"),
                NSPredicate(format: "\(#keyPath(BMSCartridge.actionName)) == '\(actionName)'")
                ])
            request.fetchLimit = 1
            do {
                value = try context.fetch(request).first
            } catch let error as NSError {
                BMSLog.error("Could not fetch. \(error)")
            }
        }

        return value
    }

    func fetchCartridges(context: NSManagedObjectContext?, userId: String) -> [BMSCartridge]? {
        var values: [BMSCartridge]?
        let context = context ?? newContext()
        context.performAndWait {
            let request = NSFetchRequest<BMSCartridge>(entityName: BMSCartridge.description())
            request.predicate = NSPredicate(format: "\(#keyPath(BMSCartridge.user.id)) == '\(userId)'")
            do {
                values = try context.fetch(request)
            } catch let error as NSError {
                BMSLog.error("Could not fetch. \(error)")
            }
        }

        return values
    }
}

extension Optional where Wrapped == String {
    var predicateValue: String {
        return self == nil ? "nil" : "'\(self!)'"
    }
}
