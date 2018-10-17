//
//  BMSCartridgeReinforcement+CoreDataClass.swift
//  
//
//  Created by Akash Desai on 9/26/18.
//
//

import Foundation
import CoreData

@objc(BMSCartridgeReinforcement)
public class BMSCartridgeReinforcement: NSManagedObject {

    struct Holder {
        var id: String?
        var idx: Int32?
    }

    @objc public static let NeutralName = "NEUTRAL_RESP"
    @objc public static let NeutralId = NeutralName

}

extension BMSCartridgeReinforcement {

    @discardableResult
    class func insert(context: NSManagedObjectContext, cartridge: BMSCartridge, id: String, idx: Int32) -> BMSCartridgeReinforcement? {
        var value: BMSCartridgeReinforcement?
        context.performAndWait {
            if let reinforcement = BMSCartridgeReinforcement.create(in: context) {
                reinforcement.id = id
                reinforcement.idx = idx
                cartridge.addToReinforcements(reinforcement)
                do {
                    try context.save()
                } catch let error as NSError {
                    BMSLog.error("Could not insert. \(error)")
                }
                value = reinforcement
            }
        }
        return value
    }
    
}
