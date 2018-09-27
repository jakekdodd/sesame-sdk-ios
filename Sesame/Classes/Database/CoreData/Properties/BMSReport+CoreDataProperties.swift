//
//  BMSReport+CoreDataProperties.swift
//  
//
//  Created by Akash Desai on 9/26/18.
//
//

import Foundation
import CoreData

extension BMSReport {

    @nonobjc class func fetchRequest() -> NSFetchRequest<BMSReport> {
        return NSFetchRequest<BMSReport>(entityName: "BMSReport")
    }

    @NSManaged var actionName: String
    @NSManaged var events: NSOrderedSet
    @NSManaged var user: BMSUser

}

// MARK: Generated accessors for events
extension BMSReport {

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
