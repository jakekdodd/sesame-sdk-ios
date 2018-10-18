//
//  BMSReinforcement+CoreDataProperties.swift
//  Sesame
//
//  Created by Akash Desai on 10/15/18.
//
//

import Foundation
import CoreData

extension BMSReinforcement {

    @nonobjc class func request() -> NSFetchRequest<BMSReinforcement> {
        return NSFetchRequest<BMSReinforcement>(entityName: "BMSReinforcement")
    }

    class func create(in context: NSManagedObjectContext) -> BMSReinforcement? {
        guard let entity = NSEntityDescription.entity(forEntityName: "BMSReinforcement", in: context) else {
            return nil
        }
        return BMSReinforcement(entity: entity, insertInto: context)
    }

    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var action: BMSReinforcedAction
    @NSManaged var effects: Set<BMSReinforcementEffect>

    var effectsAttributes: [EffectAttributes] {
        return effects.map({$0.attributesDictionary})
    }

}

// MARK: Generated accessors for effects
extension BMSReinforcement {

    @objc(addEffectsObject:)
    @NSManaged func addToEffects(_ value: BMSReinforcementEffect)

    @objc(removeEffectsObject:)
    @NSManaged func removeFromEffects(_ value: BMSReinforcementEffect)

    @objc(addEffects:)
    @NSManaged func addToEffects(_ values: NSSet)

    @objc(removeEffects:)
    @NSManaged func removeFromEffects(_ values: NSSet)

}
