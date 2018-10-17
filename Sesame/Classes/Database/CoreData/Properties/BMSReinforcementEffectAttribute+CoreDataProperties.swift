//
//  BMSReinforcementEffectAttribute+CoreDataProperties.swift
//  
//
//  Created by Akash Desai on 10/2/18.
//
//

import Foundation
import CoreData

extension BMSReinforcementEffectAttribute {

    @nonobjc class func fetch() -> NSFetchRequest<BMSReinforcementEffectAttribute> {
        return NSFetchRequest<BMSReinforcementEffectAttribute>(entityName: "BMSReinforcementEffectAttribute")
    }

    class func create(in context: NSManagedObjectContext) -> BMSReinforcementEffectAttribute? {
        guard let entity = NSEntityDescription.entity(forEntityName: "BMSReinforcementEffectAttribute",
                                                      in: context) else {
            return nil
        }
        return BMSReinforcementEffectAttribute(entity: entity, insertInto: context)
    }

    @NSManaged var key: String
    @NSManaged var value: NSObject?
    @NSManaged var effect: BMSReinforcementEffect

}
