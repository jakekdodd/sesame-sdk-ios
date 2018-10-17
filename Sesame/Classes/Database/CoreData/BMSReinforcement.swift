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
        var effects: [[String: NSObject]]?
    }
}

extension BMSReinforcement {

    @discardableResult
    class func insert(context: NSManagedObjectContext, reinforcedAction: BMSReinforcedAction, id: String, name: String, effectDicts: [[String: NSObject]]) -> BMSReinforcement? {
        var value: BMSReinforcement?
        context.performAndWait {
            if let reinforcement = BMSReinforcement.create(in: context) {
                reinforcement.id = id
                reinforcement.name = name
                for effectDict in effectDicts {
                    guard let name = effectDict["name"] as? String else { continue }
                    BMSReinforcementEffect.insert(context: context, reinforcement: reinforcement, name: name, attributes: effectDict)
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
