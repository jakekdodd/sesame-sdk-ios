//
//  BMSCartridge+CoreDataClass.swift
//  
//
//  Created by Akash Desai on 9/26/18.
//
//

import Foundation
import CoreData

@objc(BMSCartridge)
class BMSCartridge: NSManagedObject {
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
