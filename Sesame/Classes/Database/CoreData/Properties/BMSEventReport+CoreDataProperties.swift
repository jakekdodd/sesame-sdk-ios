//
//  BMSEventReport+CoreDataProperties.swift
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

extension BMSEventReport {

    @nonobjc class func request() -> NSFetchRequest<BMSEventReport> {
        return NSFetchRequest<BMSEventReport>(entityName: "BMSEventReport")
    }

    class func create(in context: NSManagedObjectContext) -> BMSEventReport? {
        guard let entity = NSEntityDescription.entity(forEntityName: "BMSEventReport", in: context) else {
            return nil
        }
        return BMSEventReport(entity: entity, insertInto: context)
    }

    @NSManaged var type: BMSEventReportType
    @NSManaged var actionName: String
    @NSManaged var events: NSOrderedSet
    @NSManaged var user: BMSUser

}

// MARK: Generated accessors for events
extension BMSEventReport {

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
