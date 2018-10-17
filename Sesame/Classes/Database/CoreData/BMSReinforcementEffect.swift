//
//  BMSReinforcementEffect.swift
//  
//
//  Created by Akash Desai on 10/2/18.
//
//

import Foundation
import CoreData

@objc(BMSReinforcementEffect)
public class BMSReinforcementEffect: NSManagedObject { }

extension BMSReinforcementEffect {

    @discardableResult
    class func insert(context: NSManagedObjectContext, reinforcement: BMSReinforcement, name: String, attributes: [String: NSObject]) -> BMSReinforcementEffect? {
        var value: BMSReinforcementEffect?
        context.performAndWait {
            guard let effect = BMSReinforcementEffect.create(in: context) else {
                return
            }
            effect.name = name
            _ = attributes.compactMap({
                BMSReinforcementEffectAttribute.insert(context: context,
                                                       reinforementEffect: effect,
                                                       key: $0.key,
                                                       value: $0.value)
            })
            reinforcement.addToEffects(effect)
            do {
                try context.save()
            } catch let error as NSError {
                BMSLog.error(error)
            }
            value = effect
        }
        return value
    }
}
