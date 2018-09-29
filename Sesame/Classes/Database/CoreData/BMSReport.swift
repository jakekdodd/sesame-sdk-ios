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

    static let NonReinforceableType = "NON_REINFORCEABLE"

}

extension BMSReport {

    class func fetch(context: NSManagedObjectContext, userId: String, actionName: String, createIfNotFound: Bool = true) -> BMSReport? {
        var value: BMSReport?
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
                    let user = BMSUser.fetch(context: context, id: userId),
                    let entity = NSEntityDescription.entity(forEntityName: BMSReport.description(), in: context) {
                    let report = BMSReport(entity: entity, insertInto: context)
                    report.actionName = actionName
                    report.user = user
                    value = report
                    try context.save()
                }
            } catch {
                BMSLog.error("Could not fetch. \(error)")
            }
        }

        return value
    }

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

    class func delete(context: NSManagedObjectContext, userId: String) {
        context.performAndWait {
            let request = NSFetchRequest<BMSReport>(entityName: BMSReport.description())
            request.predicate = NSPredicate(format: "\(#keyPath(BMSReport.user.id)) == '\(userId)'")
            do {
                let reports = try context.fetch(request)
                for report in reports {
                    context.delete(report)
                }
                try context.save()
            } catch {
                BMSLog.error(error)
            }
        }
    }

}
