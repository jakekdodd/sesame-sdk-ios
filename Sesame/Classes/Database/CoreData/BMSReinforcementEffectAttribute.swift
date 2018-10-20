//
//  BMSReinforcementEffectAttribute.swift
//  
//
//  Created by Akash Desai on 10/2/18.
//
//

import Foundation
import CoreData

@objc(BMSReinforcementEffectAttribute)
public class BMSReinforcementEffectAttribute: NSManagedObject {

    @NSManaged var key: String
    @NSManaged var value: NSObject?
    @NSManaged var effect: BMSReinforcementEffect

}

extension BMSReinforcementEffectAttribute {

    class func create(in context: NSManagedObjectContext) -> BMSReinforcementEffectAttribute? {
        guard let entity = NSEntityDescription.entity(forEntityName: "BMSReinforcementEffectAttribute",
                                                      in: context) else {
                                                        return nil
        }
        return BMSReinforcementEffectAttribute(entity: entity, insertInto: context)
    }

    @nonobjc class func fetch() -> NSFetchRequest<BMSReinforcementEffectAttribute> {
        return NSFetchRequest<BMSReinforcementEffectAttribute>(entityName: "BMSReinforcementEffectAttribute")
    }

    class func insert(context: NSManagedObjectContext, reinforementEffect: BMSReinforcementEffect, key: String, value attributeValue: NSObject?) -> BMSReinforcementEffectAttribute? {

        var value: BMSReinforcementEffectAttribute?
        context.performAndWait {
            if let attr = BMSReinforcementEffectAttribute.create(in: context) {
                attr.key = key
                attr.value = attributeValue
                reinforementEffect.addToAttributes(attr)
                do {
                    try context.save()
                } catch let error as NSError {
                    BMSLog.error(error)
                }
//                BMSLog.info("Inserted attribute key:\(attr.key) value:\(attr.value)")
                value = attr
            }
        }
        return value
    }
}
