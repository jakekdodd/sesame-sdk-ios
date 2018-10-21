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
class BMSReinforcementEffect: NSManagedObject {

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

    class func fetch() -> NSFetchRequest<BMSReinforcementEffect> {
        return NSFetchRequest<BMSReinforcementEffect>(entityName: "BMSReinforcementEffect")
    }

    @discardableResult
    class func insert(context: NSManagedObjectContext, reinforcement: BMSReinforcement, name: String, attributes: EffectAttributes) -> BMSReinforcementEffect? {
        var value: BMSReinforcementEffect?
        context.performAndWait {
            if let effect = BMSReinforcementEffect.create(in: context) {
                effect.name = name
                reinforcement.addToEffects(effect)
                for (key, value) in attributes {
                    BMSReinforcementEffectAttribute.insert(context: context,
                                                           reinforementEffect: effect,
                                                           key: key,
                                                           value: value)
                }
                do {
                    try context.save()
                } catch let error as NSError {
                    BMSLog.error(error)
                }
                BMSLog.info(confirmed:
                    "Inserted reinforcement effect <\(effect.name)> for reinforcement <\(reinforcement.name)>"
                )
                value = effect
            }
        }
        return value
    }
}
