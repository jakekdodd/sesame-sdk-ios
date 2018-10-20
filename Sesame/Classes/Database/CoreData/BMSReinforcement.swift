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
}

extension BMSReinforcement {

    var holder: BMSReinforcement.Holder {
        return .init(id: id, name: name, effects: effects.map({$0.holder}))
    }

    @discardableResult
    class func insert(context: NSManagedObjectContext, reinforcedAction: BMSReinforcedAction, id: String, name: String, effects: [BMSReinforcementEffect.Holder]) -> BMSReinforcement? {
        var value: BMSReinforcement?
        context.performAndWait {
            if let reinforcement = BMSReinforcement.create(in: context) {
                reinforcement.id = id
                reinforcement.name = name
                for effect in effects {
                    guard let name = effect.name,
                        let attributes = effect.attributes
                        else { continue }
                    BMSReinforcementEffect.insert(context: context, reinforcement: reinforcement, name: name, attributes: attributes)
                }
                reinforcedAction.addToReinforcements(reinforcement)

                do {
                    try context.save()
                    BMSLog.info(confirmed: "Inserted reinforcement:\(name)")
                    value = reinforcement
                } catch {
                    BMSLog.error(error)
                }
            }
        }
        return value
    }

}
