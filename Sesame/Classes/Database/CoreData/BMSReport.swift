//
//  BMSReport+CoreDataClass.swift
//  
//
//  Created by Akash Desai on 9/26/18.
//
//

import Foundation
import CoreData

@objc(BMSReport)
class BMSReport: NSManagedObject {

}

extension BMSReport {

    class func fetch(context: NSManagedObjectContext, userId: String) -> [BMSReport]? {
        var values: [BMSReport]?
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

    class func fetch(context: NSManagedObjectContext, userId: String, actionName: String) -> BMSReport? {
        var value: BMSReport?
        context.performAndWait {
            let request = NSFetchRequest<BMSReport>(entityName: BMSReport.description())
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "\(#keyPath(BMSReport.user.id)) == '\(userId)'"),
                NSPredicate(format: "\(#keyPath(BMSReport.actionName)) == '\(actionName)'")
                ])
            request.fetchLimit = 1
            do {
                value = try context.fetch(request).first
            } catch {
                BMSLog.error("Could not fetch. \(error)")
            }
        }
        return value
    }

    @discardableResult
    class func delete(context: NSManagedObjectContext, userId: String) -> Int? {
        var value: Int?
        context.performAndWait {
            let request = NSFetchRequest<BMSReport>(entityName: BMSReport.description())
            request.predicate = NSPredicate(format: "\(#keyPath(BMSReport.user.id)) == '\(userId)'")
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

    class func insert(context: NSManagedObjectContext, userId: String, actionName: String) -> BMSReport? {
        var value: BMSReport?
        context.performAndWait {
            if let user = BMSUser.fetch(context: context, id: userId),
                let entity = NSEntityDescription.entity(forEntityName: BMSReport.description(), in: context) {
                let report = BMSReport(entity: entity, insertInto: context)
                report.actionName = actionName
                report.user = user
                do {
                    try context.save()
                } catch {
                    BMSLog.error("Could not fetch. \(error)")
                }
                value = report
            }
        }
        return value
    }

}
