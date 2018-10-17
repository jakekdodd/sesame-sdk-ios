//
//  BMSCartridgeReinforcement+CoreDataProperties.swift
//  
//
//  Created by Akash Desai on 9/26/18.
//
//

import Foundation
import CoreData

extension BMSCartridgeReinforcement {

    @nonobjc class func request() -> NSFetchRequest<BMSCartridgeReinforcement> {
        return NSFetchRequest<BMSCartridgeReinforcement>(entityName: "BMSCartridgeReinforcement")
    }

    class func create(in context: NSManagedObjectContext) -> BMSCartridgeReinforcement? {
        guard let entity = NSEntityDescription.entity(forEntityName: "BMSCartridgeReinforcement", in: context) else {
            return nil
        }
        return BMSCartridgeReinforcement(entity: entity, insertInto: context)
    }

    @NSManaged var id: String
    @NSManaged var idx: Int32
    @NSManaged var cartridge: BMSCartridge
    @NSManaged var event: BMSEvent?

}
