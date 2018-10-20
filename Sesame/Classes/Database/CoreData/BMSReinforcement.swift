//
//  BMSReinforcement+CoreDataClass.swift
//  Sesame
//
//  Created by Akash Desai on 10/15/18.
//
//

import Foundation
import CoreData

@objc(BMSReinforcement)
class BMSReinforcement: NSManagedObject {

    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var action: BMSReinforcedAction
    @NSManaged var effects: Set<BMSReinforcementEffect>

    struct Holder {
        var id: String?
        var name: String?
        var effects: [BMSReinforcementEffect.Holder]?

        var effectsDictionary: [String: [EffectAttributes]]? {
            guard let effects = effects else { return nil }
            return Dictionary(grouping: effects, by: {
                $0.name ?? ""
            }).mapValues({
                $0.compactMap({
                    $0.attributes
                })
            })
        }
    }

    var holder: BMSReinforcement.Holder {
        return .init(id: id, name: name, effects: effects.map({$0.holder}))
    }

    // MARK: Generated accessors for effects
    @objc(addEffectsObject:)
    @NSManaged func addToEffects(_ value: BMSReinforcementEffect)

    @objc(removeEffectsObject:)
    @NSManaged func removeFromEffects(_ value: BMSReinforcementEffect)

    @objc(addEffects:)
    @NSManaged func addToEffects(_ values: NSSet)

    @objc(removeEffects:)
    @NSManaged func removeFromEffects(_ values: NSSet)

}

extension BMSReinforcement {

    class func create(in context: NSManagedObjectContext) -> BMSReinforcement? {
        guard let entity = NSEntityDescription.entity(forEntityName: "BMSReinforcement", in: context) else {
            return nil
        }
        return BMSReinforcement(entity: entity, insertInto: context)
    }

    class func request() -> NSFetchRequest<BMSReinforcement> {
        return NSFetchRequest<BMSReinforcement>(entityName: "BMSReinforcement")
    }

    @discardableResult
    class func insert(context: NSManagedObjectContext, reinforcedAction: BMSReinforcedAction, id: String, name: String, effects: [BMSReinforcementEffect.Holder]) -> BMSReinforcement? {
        var value: BMSReinforcement?
        context.performAndWait {
            if let reinforcement = BMSReinforcement.create(in: context) {
                reinforcement.id = id
                reinforcement.name = name
                reinforcedAction.addToReinforcements(reinforcement)
                for effect in effects {
                    guard let name = effect.name,
                        let attributes = effect.attributes
                        else { continue }
                    BMSReinforcementEffect.insert(context: context,
                                                  reinforcement: reinforcement,
                                                  name: name,
                                                  attributes: attributes)
                }

                do {
                    try context.save()
                } catch {
                    BMSLog.error(error)
                }
                BMSLog.info(confirmed: "Inserted reinforcement <\(name)> for action <\(reinforcedAction.name)>")
                value = reinforcement
            }
        }
        return value
    }

}
