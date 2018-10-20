//
//  BMSEventReport+CoreDataClass.swift
//  
//
//  Created by Akash Desai on 9/26/18.
//
//

import Foundation
import CoreData

@objc enum BMSEventReportType: Int32 {

    case reinforceable, nonreinforceable

    var stringValue: String {
        switch self {
        case .reinforceable:    return "REINFORCEABLE"
        case .nonreinforceable: return "NON_REINFORCEABLE"
        }
    }

}

@objc(BMSEventReport)
class BMSEventReport: NSManagedObject {

    @NSManaged var type: BMSEventReportType
    @NSManaged var actionName: String
    @NSManaged var events: NSOrderedSet
    @NSManaged var user: BMSUser

    // MARK: Generated accessors for events
    @objc(insertObject:inEventsAtIndex:)
    @NSManaged func insertIntoEvents(_ value: BMSEvent, at idx: Int)

    @objc(removeObjectFromEventsAtIndex:)
    @NSManaged func removeFromEvents(at idx: Int)

    @objc(insertEvents:atIndexes:)
    @NSManaged func insertIntoEvents(_ values: [BMSEvent], at indexes: NSIndexSet)

    @objc(removeEventsAtIndexes:)
    @NSManaged func removeFromEvents(at indexes: NSIndexSet)

    @objc(replaceObjectInEventsAtIndex:withObject:)
    @NSManaged func replaceEvents(at idx: Int, with value: BMSEvent)

    @objc(replaceEventsAtIndexes:withEvents:)
    @NSManaged func replaceEvents(at indexes: NSIndexSet, with values: [BMSEvent])

    @objc(addEventsObject:)
    @NSManaged func addToEvents(_ value: BMSEvent)

    @objc(removeEventsObject:)
    @NSManaged func removeFromEvents(_ value: BMSEvent)

    @objc(addEvents:)
    @NSManaged func addToEvents(_ values: NSOrderedSet)

    @objc(removeEvents:)
    @NSManaged func removeFromEvents(_ values: NSOrderedSet)

}

extension BMSEventReport {

    class func create(in context: NSManagedObjectContext) -> BMSEventReport? {
        guard let entity = NSEntityDescription.entity(forEntityName: "BMSEventReport", in: context) else {
            return nil
        }
        return BMSEventReport(entity: entity, insertInto: context)
    }

    @nonobjc class func request() -> NSFetchRequest<BMSEventReport> {
        return NSFetchRequest<BMSEventReport>(entityName: "BMSEventReport")
    }

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
