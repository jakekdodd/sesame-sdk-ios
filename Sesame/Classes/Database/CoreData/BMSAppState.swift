//
//  BMSIntegrationState+CoreDataClass.swift
//  
//
//  Created by Akash Desai on 9/26/18.
//
//

import Foundation
import CoreData

@objc(BMSAppState)
class BMSAppState: NSManagedObject {

    @NSManaged var appId: String
    @NSManaged var auth: String
    @NSManaged var revision: Int64
    @NSManaged var trackingEnabled: Bool
    @NSManaged var versionId: String?
    @NSManaged var reinforcedActions: Set<BMSReinforcedAction>
    @NSManaged var user: BMSUser?

    var basicAuth: HTTPClient.AuthorizationHeader {
        return .basic(appId, auth)
    }

    // MARK: Generated accessors for reinforcedActions
    @objc(addReinforcedActionsObject:)
    @NSManaged public func addToReinforcedActions(_ value: BMSReinforcedAction)

    @objc(removeReinforcedActionsObject:)
    @NSManaged public func removeFromReinforcedActions(_ value: BMSReinforcedAction)

    @objc(addReinforcedActions:)
    @NSManaged public func addToReinforcedActions(_ values: NSSet)

    @objc(removeReinforcedActions:)
    @NSManaged public func removeFromReinforcedActions(_ values: NSSet)

}

extension BMSAppState {

    class func create(in context: NSManagedObjectContext) -> BMSAppState? {
        guard let entity = NSEntityDescription.entity(forEntityName: "BMSAppState", in: context) else {
            return nil
        }
        return BMSAppState(entity: entity, insertInto: context)
    }

    class func request() -> NSFetchRequest<BMSAppState> {
        return NSFetchRequest<BMSAppState>(entityName: "BMSAppState")
    }

    class func fetch(context: NSManagedObjectContext, appId: String) -> BMSAppState? {
        var value: BMSAppState?
        context.performAndWait {
            let request = BMSAppState.request()
            request.predicate = NSPredicate(format: "\(#keyPath(BMSAppState.appId)) == '\(appId)'")
            request.fetchLimit = 1
            do {
                value = try context.fetch(request).first
            } catch let error as NSError {
                BMSLog.error("Could not fetch \(error)")
            }
        }
        return value
    }

    @discardableResult
    class func delete(context: NSManagedObjectContext, appId: String) -> Int? {
        var count: Int?
        context.performAndWait {
            let request = BMSAppState.request()
            request.predicate = NSPredicate(format: "\(#keyPath(BMSAppState.appId)) == '\(appId)'")
            do {
                count = try context.fetch(request).map({context.delete($0)}).count
                if context.hasChanges {
                    try context.save()
                }
            } catch let error as NSError {
                BMSLog.error("Could not fetch or insert. \(error)")
            }
        }
        return count
    }

    class func insert(context: NSManagedObjectContext, appId: String, auth: String, versionId: String? = nil) -> BMSAppState? {
        var value: BMSAppState?
        context.performAndWait {
            if let appState = BMSAppState.create(in: context) {
                appState.appId = appId
                appState.auth = auth
                appState.versionId = versionId
                do {
                    try context.save()
                } catch let error as NSError {
                    BMSLog.error("Could not insert. \(error)")
                }
                BMSLog.warning("Inserted appState with id:\(appId)")
                value = appState
            }
        }
        return value
    }

}
