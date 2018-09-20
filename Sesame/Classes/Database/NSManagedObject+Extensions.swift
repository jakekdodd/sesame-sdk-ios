//
//  NSManagedObject+Extensions.swift
//  Pods-Sesame_Example
//
//  Created by Akash Desai on 9/4/18.
//

import CoreData

public extension BMSReinforcement {
    @objc static let NeutralName = "NEUTRAL_RESP"
}

extension BMSEvent {
    static let AppOpenName = "appOpen"

    override public func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(Int64(Date().timeIntervalSince1970 * 1000), forKey: #keyPath(BMSEvent.utc))
        setPrimitiveValue(Int64(NSTimeZone.default.secondsFromGMT() * 1000), forKey: #keyPath(BMSEvent.timezoneOffset))
    }
}

extension BMSReport {
    static let NonReinforceableType = "NON_REINFORCEABLE"
}

extension BMSCartridge {
    static let NeutralCartridgeId = "CLIENT_NEUTRAL"

    override public func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(BMSCartridge.NeutralCartridgeId, forKey: #keyPath(BMSCartridge.cartridgeId))
    }

    var effectDetailsAsDictionary: [String: Any]? {
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

extension BMSUser {
    override public func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(UUID().uuidString, forKey: #keyPath(BMSUser.id))
    }
}

extension Optional where Wrapped == String {
    var predicateValue: String {
        return self == nil ? "nil" : "'\(self!)'"
    }
}
