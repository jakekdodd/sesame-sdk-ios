//
//  BMSEvent+CoreDataProperties.swift
//  
//
//  Created by Akash Desai on 9/26/18.
//
//

import Foundation
import CoreData

extension BMSEvent {

    @nonobjc class func fetchRequest() -> NSFetchRequest<BMSEvent> {
        return NSFetchRequest<BMSEvent>(entityName: "BMSEvent")
    }

    @NSManaged var metadata: String?
    @NSManaged var sessionId: NSNumber?
    @NSManaged var timezoneOffset: Int64
    @NSManaged var utc: Int64
    @NSManaged var report: BMSReport
    @NSManaged public var reinforcement: BMSReinforcement?

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

}