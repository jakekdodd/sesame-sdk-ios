//
//  BMSUser+CoreDataClass.swift
//  
//
//  Created by Akash Desai on 9/26/18.
//
//

import Foundation
import CoreData

@objc(BMSUser)
class BMSUser: NSManagedObject {

    @NSManaged var id: String
    @NSManaged var appState: BMSAppState?
    @NSManaged var cartridges: Set<BMSCartridge>
    @NSManaged var reports: Set<BMSEventReport>

    override public func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(UUID().uuidString, forKey: #keyPath(BMSUser.id))
    }

    // MARK: Generated accessors for reports
    @objc(addReportsObject:)
    @NSManaged public func addToReports(_ value: BMSEventReport)

    @objc(removeReportsObject:)
    @NSManaged public func removeFromReports(_ value: BMSEventReport)

    @objc(addReports:)
    @NSManaged public func addToReports(_ values: NSSet)

    @objc(removeReports:)
    @NSManaged public func removeFromReports(_ values: NSSet)

    // MARK: Generated accessors for cartridges
    @objc(addCartridgesObject:)
    @NSManaged public func addToCartridges(_ value: BMSCartridge)

    @objc(removeCartridgesObject:)
    @NSManaged public func removeFromCartridges(_ value: BMSCartridge)

    @objc(addCartridges:)
    @NSManaged public func addToCartridges(_ values: NSSet)

    @objc(removeCartridges:)
    @NSManaged public func removeFromCartridges(_ values: NSSet)

}

extension BMSUser {

    class func create(in context: NSManagedObjectContext) -> BMSUser? {
        guard let entity = NSEntityDescription.entity(forEntityName: "BMSUser", in: context) else {
            return nil
        }
        return BMSUser(entity: entity, insertInto: context)
    }

    @nonobjc public class func request() -> NSFetchRequest<BMSUser> {
        return NSFetchRequest<BMSUser>(entityName: "BMSUser")
    }

    class func fetch(context: NSManagedObjectContext, id: String) -> BMSUser? {
        var value: BMSUser?
        context.performAndWait {
            let request = BMSUser.request()
            request.predicate = NSPredicate(format: "\(#keyPath(BMSUser.id)) == '\(id)'")
            request.fetchLimit = 1
            do {
                value = try context.fetch(request).first
            } catch let error as NSError {
                BMSLog.error("Could not fetch. \(error)")
            }
        }
        return value
    }

    @discardableResult
    class func delete(context: NSManagedObjectContext) -> Int? {
        var value: Int?
        context.performAndWait {
            let request = BMSUser.request()
            do {
                value = try context.fetch(request).map({context.delete($0)}).count
                if context.hasChanges {
                    try context.save()
                }
            } catch {
                BMSLog.error(error)
            }
        }
        return value
    }

    class func insert(context: NSManagedObjectContext, id: String) -> BMSUser? {
        var value: BMSUser?
        context.performAndWait {
            let request = BMSUser.request()
            request.predicate = NSPredicate(format: "\(#keyPath(BMSUser.id)) == '\(id)'")
            if let user = BMSUser.create(in: context) {
                user.id = id
                do {
                    try context.save()
                } catch let error as NSError {
                    BMSLog.error("Could not fetch. \(error)")
                }
                value = user
            }
        }
        return value
    }
}
