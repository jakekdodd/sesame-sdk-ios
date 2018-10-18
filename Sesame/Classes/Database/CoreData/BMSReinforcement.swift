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
        var effects: [EffectAttributes]?
    }
}

extension BMSReinforcement {

    var holder: BMSReinforcement.Holder {
        return .init(id: id, name: name, effects: effectsAttributes)
    }

    @discardableResult
    class func insert(context: NSManagedObjectContext, reinforcedAction: BMSReinforcedAction, id: String, name: String, effects: [EffectAttributes]) -> BMSReinforcement? {
        var value: BMSReinforcement?
        context.performAndWait {
            if let reinforcement = BMSReinforcement.create(in: context) {
                reinforcement.id = id
                reinforcement.name = name
                for effectAttributes in effects {
                    guard let name = effectAttributes["name"] as? String else { continue }
                    BMSReinforcementEffect.insert(context: context, reinforcement: reinforcement, name: name, effectAttributes: effectAttributes)
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
