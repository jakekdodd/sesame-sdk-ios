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
class BMSCartridgeReinforcement: NSManagedObject {

    @objc static let NeutralName = "NEUTRAL_RESP"
    @objc static let NeutralId = NeutralName

    @NSManaged var id: String
    @NSManaged var idx: Int32
    @NSManaged var cartridge: BMSCartridge
    @NSManaged var event: BMSEvent?

    struct Holder {
        var id: String?
        var idx: Int32?
    }

}

extension BMSCartridgeReinforcement {

    class func create(in context: NSManagedObjectContext) -> BMSCartridgeReinforcement? {
        guard let entity = NSEntityDescription.entity(forEntityName: "BMSCartridgeReinforcement", in: context) else {
            return nil
        }
        return BMSCartridgeReinforcement(entity: entity, insertInto: context)
    }

    class func request() -> NSFetchRequest<BMSCartridgeReinforcement> {
        return NSFetchRequest<BMSCartridgeReinforcement>(entityName: "BMSCartridgeReinforcement")
    }

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
                BMSLog.info("Inserted reinforcement #\(idx) id:\(id) for actionId:\(cartridge.actionId)")
                value = reinforcement
            }
        }
        return value
    }

}
