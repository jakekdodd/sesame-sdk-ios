//
//  BMSReinforcement+CoreDataClass.swift
//  
//
//  Created by Akash Desai on 9/26/18.
//
//

import Foundation
import CoreData

@objc(BMSReinforcement)
public class BMSReinforcement: NSManagedObject {

    @objc public static let NeutralName = "NEUTRAL_RESP"

}

extension BMSReinforcement {
    class func insert(context: NSManagedObjectContext, cartridge: BMSCartridge, name: String) -> BMSReinforcement? {
        var value: BMSReinforcement?
        context.performAndWait {
            if let entity =
                NSEntityDescription.entity(forEntityName: BMSReinforcement.description(), in: context) {
                let reinforcement = BMSReinforcement(entity: entity, insertInto: context)
                reinforcement.name = name
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
