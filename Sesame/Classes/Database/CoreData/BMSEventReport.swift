//
//  BMSEventReport+CoreDataClass.swift
//  
//
//  Created by Akash Desai on 9/26/18.
//
//

import Foundation
import CoreData

@objc(BMSEventReport)
class BMSEventReport: NSManagedObject { }

extension BMSEventReport {

    class func fetch(context: NSManagedObjectContext, userId: String) -> [BMSEventReport]? {
        var values: [BMSEventReport]?
        context.performAndWait {
            let request = BMSEventReport.request()
            request.predicate = NSPredicate(format: "\(#keyPath(BMSEventReport.user.id)) == '\(userId)'")
            do {
                values = try context.fetch(request)
            } catch let error as NSError {
                BMSLog.error("Could not fetch. \(error)")
            }
        }
        return values
    }

    class func fetch(context: NSManagedObjectContext, userId: String, actionName: String) -> BMSEventReport? {
        var value: BMSEventReport?
        context.performAndWait {
            let request = BMSEventReport.request()
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "\(#keyPath(BMSEventReport.user.id)) == '\(userId)'"),
                NSPredicate(format: "\(#keyPath(BMSEventReport.actionName)) == '\(actionName)'")
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

    class func insert(context: NSManagedObjectContext, userId: String, actionName: String) -> BMSEventReport? {
        var value: BMSEventReport?
        context.performAndWait {
            if let user = BMSUser.fetch(context: context, id: userId),
                let report = BMSEventReport.create(in: context) {
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
