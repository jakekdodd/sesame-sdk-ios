//
//  NSManagedObject+Extensions.swift
//  Pods-Sesame_Example
//
//  Created by Akash Desai on 9/4/18.
//

import CoreData

extension Event {
    override public func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(Int64(Date().timeIntervalSince1970 * 1000), forKey: #keyPath(Event.utc))
        setPrimitiveValue(Int64(NSTimeZone.default.secondsFromGMT() * 1000), forKey: #keyPath(Event.timezoneOffset))
    }
}

extension AppConfig {
    override public func awakeFromInsert() {
        super.awakeFromInsert()
        if let managedObjectContext = managedObjectContext,
            let trackingCapabilitiesEntity = NSEntityDescription.entity(forEntityName: "TrackingCapabilities",
                                                                        in: managedObjectContext) {
            let trackingCapabilities = TrackingCapabilities(entity: trackingCapabilitiesEntity,
                                                            insertInto: managedObjectContext)
            setPrimitiveValue(trackingCapabilities, forKey: #keyPath(AppConfig.trackingCapabilities))
            trackingCapabilities.setPrimitiveValue(self, forKey: #keyPath(TrackingCapabilities.appConfig))
        }
    }
}

extension User {
    override public func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(UUID().uuidString, forKey: #keyPath(User.id))
    }
}

extension Cartridge {

    static let NeutralCartridgeId = "CLIENT_NEUTRAL"

    override public func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(Cartridge.NeutralCartridgeId, forKey: #keyPath(Cartridge.cartridgeId))
    }

    var effectDetailsDictionary: [String: Any]? {
        get {
            if let data = effectDetails?.data(using: .utf8),
                let json = try? JSONSerialization.jsonObject(with: data, options: []),
                let dict = json as? [String: Any] {
                return dict
            }
            return nil
        }
        set {
            if let dict = newValue,
                let data = try? JSONSerialization.data(withJSONObject: dict),
                let str = String(data: data, encoding: .utf8) {
                effectDetails = str
            }
        }
    }
}
