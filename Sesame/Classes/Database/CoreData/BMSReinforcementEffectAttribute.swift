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

    enum Key: String {
        case name, duration
    }

}

extension BMSReinforcementEffectAttribute {
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
