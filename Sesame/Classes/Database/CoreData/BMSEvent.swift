//
//  BMSEvent+CoreDataClass.swift
//  
//
//  Created by Akash Desai on 9/26/18.
//
//

import Foundation
import CoreData

@objc(BMSEvent)
class BMSEvent: NSManagedObject {

    static let AppOpenName = "appOpen"

    @NSManaged var metadata: String?
    @NSManaged var sessionId: NSNumber?
    @NSManaged var timezoneOffset: Int64
    @NSManaged var utc: Int64
    @NSManaged var report: BMSEventReport
    @NSManaged var reinforcement: BMSCartridgeReinforcement?

    var metadataAsDictionary: [String: Any]? {
        get {
            return (metadata == nil) ? nil : .from(string: metadata!)
        }
        set {
            if let dict = newValue.toString() {
                metadata = dict
            }
        }
    }

    override public func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(Int64(Date().timeIntervalSince1970 * 1000), forKey: #keyPath(BMSEvent.utc))
        setPrimitiveValue(Int64(NSTimeZone.default.secondsFromGMT() * 1000), forKey: #keyPath(BMSEvent.timezoneOffset))
    }

}

extension BMSEvent {

    class func create(in context: NSManagedObjectContext) -> BMSEvent? {
        guard let entity = NSEntityDescription.entity(forEntityName: "BMSEvent", in: context) else {
            return nil
        }
        return BMSEvent(entity: entity, insertInto: context)
    }

    @nonobjc class func request() -> NSFetchRequest<BMSEvent> {
        return NSFetchRequest<BMSEvent>(entityName: "BMSEvent")
    }

    @discardableResult
    class func insert(context: NSManagedObjectContext, userId: String, actionName: String, reinforcement: BMSCartridgeReinforcement? = nil, sessionId: NSNumber? = nil, metadata: [String: Any] = [:]) -> BMSEvent? {
        var value: BMSEvent?
        context.performAndWait {
            guard let report = BMSEventReport.fetch(context: context, userId: userId, actionName: actionName) ??
                BMSEventReport.insert(context: context, userId: userId, actionName: actionName),
                let event = BMSEvent.create(in: context) else {
                    return
            }
            event.report = report
            event.reinforcement = reinforcement
            event.sessionId = sessionId
            event.metadataAsDictionary = metadata
            do {
                try context.save()
                BMSLog.info("Logged event #\(report.events.count) for actionName:\(actionName)")
            } catch {
                BMSLog.error(error)
            }
            value = event
        }
        return value
    }

    class func count(context: NSManagedObjectContext, userId: String? = nil) -> Int? {
        var value: Int?
        context.performAndWait {
            let request = BMSEvent.request()
            if let userId = userId {
                request.predicate = NSPredicate(format: "\(#keyPath(BMSEvent.report.user.id)) == '\(userId)'")
            }
            do {
                value = try context.count(for: request)
            } catch let error as NSError {
                BMSLog.error("Could not fetch. \(error)")
            }
        }
        return value
    }

}
