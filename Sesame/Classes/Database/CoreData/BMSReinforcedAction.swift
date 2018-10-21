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
class BMSReinforcedAction: NSManagedObject {

    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var appState: BMSAppState
    @NSManaged var reinforcements: Set<BMSReinforcement>

    // MARK: Generated accessors for reinforcements
    @objc(addReinforcementsObject:)
    @NSManaged func addToReinforcements(_ value: BMSReinforcement)

    @objc(removeReinforcementsObject:)
    @NSManaged func removeFromReinforcements(_ value: BMSReinforcement)

    @objc(addReinforcements:)
    @NSManaged func addToReinforcements(_ values: NSSet)

    @objc(removeReinforcements:)
    @NSManaged func removeFromReinforcements(_ values: NSSet)

}

extension BMSReinforcedAction {

    class func create(in context: NSManagedObjectContext) -> BMSReinforcedAction? {
        guard let entity = NSEntityDescription.entity(forEntityName: "BMSReinforcedAction", in: context) else {
            return nil
        }
        return BMSReinforcedAction(entity: entity, insertInto: context)
    }

    class func request() -> NSFetchRequest<BMSReinforcedAction> {
        return NSFetchRequest<BMSReinforcedAction>(entityName: "BMSReinforcedAction")
    }

    @discardableResult
    class func insert(context: NSManagedObjectContext, appState: BMSAppState, id: String, name: String, reinforcements: [BMSReinforcement.Holder]) -> BMSReinforcedAction? {
        var value: BMSReinforcedAction?
        context.performAndWait {
            if let reinforcedAction = BMSReinforcedAction.create(in: context) {
                reinforcedAction.id = id
                reinforcedAction.name = name
                appState.addToReinforcedActions(reinforcedAction)
                for reinforcement in reinforcements {
                    guard let id = reinforcement.id,
                        let name = reinforcement.name,
                        let effects = reinforcement.effects
                        else { continue }
                    BMSReinforcement.insert(context: context,
                                            reinforcedAction: reinforcedAction,
                                            id: id,
                                            name: name,
                                            effects: effects)
                }
                do {
                    try context.save()
                } catch let error as NSError {
                    BMSLog.error("Could not insert. \(error)")
                }
                BMSLog.warning(
                    "Inserted reinforced action <\(reinforcedAction.name)> " +
                    "with <\(reinforcedAction.reinforcements.count)> reinforcements"
                )
                value = reinforcedAction
            }
        }
        return value
    }
}
