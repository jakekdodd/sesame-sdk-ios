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
    static let SessionStartName = "BMSSessionStart"
    static let SessionEndName = "BMSSessionEnd"
    static let SessionInterruptionStartName = "BMSSessionInterruptionStart"
    static let SessionInterruptionEndName = "BMSSessionInterruptionEnd"

    override public func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(Int64(Date().timeIntervalSince1970 * 1000), forKey: #keyPath(BMSEvent.utc))
        setPrimitiveValue(Int64(NSTimeZone.default.secondsFromGMT() * 1000), forKey: #keyPath(BMSEvent.timezoneOffset))
    }
}

extension BMSEvent {

    class func insert(context: NSManagedObjectContext, userId: String, actionName: String, sessionId: NSNumber?, metadata: [String: Any] = [:]) {
        context.performAndWait {
            guard let report = BMSReport.fetch(context: context, userId: userId, actionName: actionName),
                let entity = NSEntityDescription.entity(forEntityName: BMSEvent.description(), in: context) else {
                    return
            }
            let event = BMSEvent(entity: entity, insertInto: context)
            do {
                event.sessionId = sessionId
                event.metadata = String(data: try JSONSerialization.data(withJSONObject: metadata), encoding: .utf8)
            } catch {
                BMSLog.error(error)
            }
            event.report = report
            do {
                try context.save()
//                BMSLog.debug("Logged event #\(report.events?.count ?? -1) with actionName:\(actionName)")
            } catch {
                BMSLog.error(error)
            }
        }
    }

    class func count(context: NSManagedObjectContext, userId: String? = nil) -> Int? {
        var value: Int?
        context.performAndWait {
            let request = NSFetchRequest<BMSEvent>(entityName: BMSEvent.description())
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
