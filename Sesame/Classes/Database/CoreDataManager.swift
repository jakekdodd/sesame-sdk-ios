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
                Logger.debug(error: error.localizedDescription)
            }
        }
        return nil
    }()

    fileprivate lazy var managedObjectContext: NSManagedObjectContext? = {
        if let coordinator = persistentStoreCoordinator {
            let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            managedObjectContext.persistentStoreCoordinator = coordinator
            managedObjectContext.mergePolicy = NSOverwriteMergePolicy
            NotificationCenter.default.addObserver(self, selector: #selector(saveChanges(_:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(saveChanges(_:)), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
            return managedObjectContext
        }
        return nil
    }()

    @objc
    func saveChanges(_ notification: Notification) {
        managedObjectContext?.perform {
            if self.managedObjectContext?.hasChanges ?? false {
                do {
                    try self.managedObjectContext?.save()
                } catch {
                    Logger.debug(error: "\(error)")
                }
            }
        }
    }

    // MARK: - Methods

    func save() {
        managedObjectContext?.performAndWait {
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
        managedObjectContext?.performAndWait {
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
                    Logger.debug(error: error.localizedDescription)
                }
            }
            save()
        }
    }

}

// MARK: - Model Specific Methods

extension CoreDataManager {

    // MARK: AppConfig

    func newContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = managedObjectContext
        return context
    }

    func fetchAppConfig(context: NSManagedObjectContext?, _ configId: String?) -> AppConfig? {
        var value: AppConfig?
        let context = context ?? newContext()
        context.performAndWait {
            let request = NSFetchRequest<AppConfig>(entityName: AppConfig.description())
            request.predicate = NSPredicate(format: "\(#keyPath(AppConfig.configId)) == \(configId.predicateValue)")
            request.fetchLimit = 1
            do {
                if let appConfig = try context.fetch(request).first {
                    value = appConfig
                } else if let appConfigEntity = NSEntityDescription.entity(forEntityName: AppConfig.description(),
                                                                           in: context) {
                    let appConfig = AppConfig(entity: appConfigEntity, insertInto: context)
                    if let trackingCapabilitiesEntity = NSEntityDescription.entity(forEntityName: TrackingCapabilities.description(),
                                                                                    in: context) {
                        let trackingCapabilities = TrackingCapabilities(entity: trackingCapabilitiesEntity,
                                                                        insertInto: context)
                        appConfig.trackingCapabilities = trackingCapabilities
                    }
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

    func fetchUser(context: NSManagedObjectContext?, id: String, createIfNotFound: Bool = true) -> User? {
        var value: User?
        let context = context ?? newContext()
        context.performAndWait {
            let request = NSFetchRequest<User>(entityName: User.description())
            request.predicate = NSPredicate(format: "\(#keyPath(User.id)) == '\(id)'")
            request.fetchLimit = 1
            do {
                if let user = try context.fetch(request).first {
                    value = user
                } else if createIfNotFound,
                    let entity = NSEntityDescription.entity(forEntityName: User.description(),
                                                            in: context) {
                    let user = User(entity: entity, insertInto: context)
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

    func fetchReports(context: NSManagedObjectContext?, userId: String) -> [Report]? {
        var values: [Report]?
        let context = context ?? newContext()
        context.performAndWait {
            let request = NSFetchRequest<Report>(entityName: Report.description())
            request.predicate = NSPredicate(format: "\(#keyPath(Report.user.id)) == '\(userId)'")
            do {
                values = try context.fetch(request)
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        }

        return values
    }

    func deleteReports(context: NSManagedObjectContext?, userId: String) {
        let context = context ?? newContext()
        context.performAndWait {
            let request = NSFetchRequest<Report>(entityName: Report.description())
            request.predicate = NSPredicate(format: "\(#keyPath(Report.user.id)) == '\(userId)'")
            do {
                let reports = try context.fetch(request)
                for report in reports {
                    context.delete(report)
                }
                try context.save()
            } catch {
                Logger.debug(error: error.localizedDescription)
            }
            save()
        }
    }

    private func fetchReport(context: NSManagedObjectContext?, userId: String, actionName: String, createIfNotFound: Bool = true) -> Report? {
        var value: Report?
        let context = context ?? newContext()
        context.performAndWait {
            let request = NSFetchRequest<Report>(entityName: Report.description())
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "\(#keyPath(Report.actionName)) == '\(actionName)'"),
                NSPredicate(format: "\(#keyPath(Report.user.id)) == '\(userId)'")
                ])
            request.fetchLimit = 1
            do {
                if let report = try context.fetch(request).first {
                    value = report
                } else if createIfNotFound,
                    let entity = NSEntityDescription.entity(forEntityName: Report.description(),
                                                            in: context) {
                    let report = Report(entity: entity, insertInto: context)
                    report.actionName = actionName
                    report.user = fetchUser(context: context, id: userId)
                    value = report
                }
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        }

        return value
    }

    // MARK: Event

    func countEvents(context: NSManagedObjectContext?, userId: String? = nil) -> Int? {
        var value: Int?
        let context = context ?? newContext()
        context.performAndWait {
            let request = NSFetchRequest<Event>(entityName: Event.description())
            if let userId = userId {
                request.predicate = NSPredicate(format: "\(#keyPath(Event.report.user.id)) == '\(userId)'")
            }
            do {
                value = try context.count(for: request)
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        }

        return value
    }

    func insertEvent(context: NSManagedObjectContext?, userId: String, actionName: String, metadata: [String: Any] = [:]) {
        let context = context ?? newContext()
        context.performAndWait {
            guard let report = fetchReport(context: context, userId: userId, actionName: actionName) else { return }
            guard let entity = NSEntityDescription.entity(forEntityName: Event.description(),
                                                        in: context) else {
                Logger.debug(error: "Could not create entity for event")
                return
            }

            let event = Event(entity: entity, insertInto: context)
            do {
                event.metadata = String(data: try JSONSerialization.data(withJSONObject: metadata),
                                        encoding: .utf8)
            } catch {
                Logger.debug(error: error.localizedDescription)
            }
            event.report = report
            do {
                try context.save()
            } catch {
                Logger.debug(error: error.localizedDescription)
            }

//            Logger.debug("Logged event #\(report.events?.count ?? -1) with actionName:\(actionName)")
            save()
        }

    }

    // MARK: Cartridge

    func insertCartridge(context: NSManagedObjectContext?, userId: String, actionName: String, effectDetails: [String: Any]) {
        let context = context ?? newContext()
        context.performAndWait {
            guard let user = fetchUser(context: context, id: userId) else { return }
            guard let entity = NSEntityDescription.entity(forEntityName: Cartridge.description(),
                                                        in: context) else {
                                                            Logger.debug(error: "Could not create entity for cartridge")
                                                            return
            }

            let cartridge = Cartridge(entity: entity, insertInto: context)
            cartridge.actionName = actionName
            cartridge.effectDetailsDictionary = effectDetails
            cartridge.user = user
            do {
                try context.save()
            } catch {
                Logger.debug(error: error.localizedDescription)
            }
            save()
        }
    }

    func fetchCartridge(context: NSManagedObjectContext?, userId: String, actionName: String) -> Cartridge? {
        var value: Cartridge?
        let context = context ?? newContext()
        context.performAndWait {
            let request = NSFetchRequest<Cartridge>(entityName: Cartridge.description())
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "\(#keyPath(Cartridge.user.id)) == '\(userId)'"),
                NSPredicate(format: "\(#keyPath(Cartridge.actionName)) == '\(actionName)'")
                ])
            request.fetchLimit = 1
            do {
                value = try context.fetch(request).first
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        }

        return value
    }

    func fetchCartridges(context: NSManagedObjectContext?, userId: String) -> [Cartridge]? {
        var values: [Cartridge]?
        let context = context ?? newContext()
        context.performAndWait {
            let request = NSFetchRequest<Cartridge>(entityName: Cartridge.description())
            request.predicate = NSPredicate(format: "\(#keyPath(Cartridge.user.id)) == '\(userId)'")
            do {
                values = try context.fetch(request)
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        }

        return values
    }

    //swiftlint:disable:next function_parameter_count
    func updateCartridge(context: NSManagedObjectContext?, userId: String, actionName: String, cartridgeId: String, serverUtc: Int64, ttl: Int64, reinforcements: [String]) {
        let context = context ?? newContext()
        context.performAndWait {
            let oldCartridge = fetchCartridge(context: context, userId: userId, actionName: actionName)
            guard let user = fetchUser(context: context, id: userId) else { return }
            guard let entity = NSEntityDescription.entity(forEntityName: Cartridge.description(), in: context) else {
                Logger.debug(error: "Could not create entity for cartridge")
                return
            }

            let cartridge = Cartridge(entity: entity, insertInto: context)
            cartridge.user = user
            cartridge.actionName = actionName
            cartridge.cartridgeId = cartridgeId
            cartridge.serverUtc = serverUtc
            cartridge.ttl = ttl
            for reinforcementName in reinforcements {
                guard let entity = NSEntityDescription.entity(forEntityName: Reinforcement.description(),
                                                              in: context)
                    else { continue }
                let reinforcement = Reinforcement(entity: entity, insertInto: context)
                reinforcement.name = reinforcementName
                cartridge.addToReinforcements(reinforcement)
            }
            if let oldCartridge = oldCartridge {
                cartridge.effectDetails = oldCartridge.effectDetails
                context.delete(oldCartridge)
            }

            do {
                try context.save()
            } catch {
                Logger.debug(error: error.localizedDescription)
            }
            save()
        }
    }

    // MARK: Reinforcement
}
