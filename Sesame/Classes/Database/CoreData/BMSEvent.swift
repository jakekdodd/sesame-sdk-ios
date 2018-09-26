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
