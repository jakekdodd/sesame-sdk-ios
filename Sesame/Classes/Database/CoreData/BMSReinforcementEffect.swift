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
public class BMSReinforcementEffect: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var reinforcement: BMSReinforcement
    @NSManaged var attributes: Set<BMSReinforcementEffectAttribute>

    var attributesDictionary: EffectAttributes {
        return Dictionary(uniqueKeysWithValues: attributes.map({($0.key, $0.value)}))
    }

    struct Holder {
        var name: String?
        var attributes: EffectAttributes?
    }

    var holder: BMSReinforcementEffect.Holder {
        return .init(name: name, attributes: attributesDictionary)
    }

    // MARK: Generated accessors for attributes
    @objc(addAttributesObject:)
    @NSManaged public func addToAttributes(_ value: BMSReinforcementEffectAttribute)

    @objc(removeAttributesObject:)
    @NSManaged public func removeFromAttributes(_ value: BMSReinforcementEffectAttribute)

    @objc(addAttributes:)
    @NSManaged public func addToAttributes(_ values: NSSet)

    @objc(removeAttributes:)
    @NSManaged public func removeFromAttributes(_ values: NSSet)

}

extension BMSReinforcementEffect {

    class func create(in context: NSManagedObjectContext) -> BMSReinforcementEffect? {
        guard let entity = NSEntityDescription.entity(forEntityName: "BMSReinforcementEffect", in: context) else {
            return nil
        }
        return BMSReinforcementEffect(entity: entity, insertInto: context)
    }

    @nonobjc class func fetch() -> NSFetchRequest<BMSReinforcementEffect> {
        return NSFetchRequest<BMSReinforcementEffect>(entityName: "BMSReinforcementEffect")
    }

    @discardableResult
    class func insert(context: NSManagedObjectContext, reinforcement: BMSReinforcement, name: String, attributes: EffectAttributes) -> BMSReinforcementEffect? {
        var value: BMSReinforcementEffect?
        context.performAndWait {
            guard let effect = BMSReinforcementEffect.create(in: context) else {
                return
            }
            effect.name = name
            for (key, value) in attributes {
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
