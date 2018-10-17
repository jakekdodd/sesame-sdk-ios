//
//  BMSReinforcedAction.swift
//  Sesame
//
//  Created by Akash Desai on 10/15/18.
//
//

import Foundation
import CoreData

@objc(BMSReinforcedAction)
public class BMSReinforcedAction: NSManagedObject {

}

extension BMSReinforcedAction {

    @discardableResult
    class func insert(context: NSManagedObjectContext, appState: BMSAppState, id: String, name: String, reinforcements: [BMSReinforcement.Holder]) -> BMSReinforcedAction? {
        var value: BMSReinforcedAction?
        context.performAndWait {
            if let reinforcedAction = BMSReinforcedAction.create(in: context) {
                reinforcedAction.appState = appState
                reinforcedAction.id = id
                reinforcedAction.name = name
                for reinforcement in reinforcements {
                    guard let id = reinforcement.id,
                        let name = reinforcement.name,
                    let effects = reinforcement.effects,
                    let reinforcement = BMSReinforcement.insert(context: context, reinforcedAction: reinforcedAction, id: id, name: name, effectDicts: effects)
                     else { continue }
                    BMSLog.info("""
                        Reinforcement name:\(reinforcement.name)
                        effects:\(reinforcement.effects.map({$0.name}))
                        attributes:\(reinforcement.effects.map({$0.attributes.map({$0.key})}))
                        done
                        """)
                }

                BMSLog.warning("Inserted reinforced action:\(reinforcedAction.name)")
                do {
                    try context.save()
                } catch let error as NSError {
                    BMSLog.error("Could not insert. \(error)")
                }
                value = reinforcedAction
            }
        }
        return value
    }
}
