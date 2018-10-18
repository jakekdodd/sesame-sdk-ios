//
//  BMSReinforcementEffect.swift
//  
//
//  Created by Akash Desai on 10/2/18.
//
//

import Foundation
import CoreData

typealias EffectAttributes = [String: NSObject?]

@objc(BMSReinforcementEffect)
public class BMSReinforcementEffect: NSManagedObject { }

extension BMSReinforcementEffect {

    @discardableResult
    class func insert(context: NSManagedObjectContext, reinforcement: BMSReinforcement, name: String, effectAttributes: EffectAttributes) -> BMSReinforcementEffect? {
        var value: BMSReinforcementEffect?
        context.performAndWait {
            guard let effect = BMSReinforcementEffect.create(in: context) else {
                return
            }
            effect.name = name
            for (key, value) in effectAttributes {
                _ = BMSReinforcementEffectAttribute.insert(context: context,
                                                           reinforementEffect: effect,
                                                           key: key,
                                                           value: value)
            }
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
