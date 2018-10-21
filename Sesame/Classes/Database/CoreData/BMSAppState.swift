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

    /// AppId that can be found on https://dashboard.boundless.ai
    @NSManaged var appId: String

    /// Auth that can be found on https://dashboard.boundless.ai
    @NSManaged var auth: String

    /// Revision for your app version that can be found on https://dashboard.boundless.ai
    @NSManaged var revision: Int64

    /// TrackingEnabled that is controlled from https://dashboard.boundless.ai
    @NSManaged var trackingEnabled: Bool

    /// VersionId that can be found on https://dashboard.boundless.ai Used as an identifier in reinforcement experiments
    @NSManaged var versionId: String?

    /// Actions to reinforce like appOpen. Configured on https://dashboard.boundless.ai
    @NSManaged var reinforcedActions: Set<BMSReinforcedAction>

    /// The current user
    @NSManaged var user: BMSUser?

    /// The appId and auth as an http header
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

    /// Creates a new instance of the object in the given context.
    /// You should set its member variables after creating it.
    /// Does not save.
    ///
    /// - Parameter context: The context to create an instance in
    /// - Returns: A new instance
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
