//
//  BMSReinforcedAction+CoreDataProperties.swift
//  Sesame
//
//  Created by Akash Desai on 10/15/18.
//
//

import Foundation
import CoreData


extension BMSReinforcedAction {

    @nonobjc class func request() -> NSFetchRequest<BMSReinforcedAction> {
        return NSFetchRequest<BMSReinforcedAction>(entityName: "BMSReinforcedAction")
    }

    class func create(in context: NSManagedObjectContext) -> BMSReinforcedAction? {
        guard let entity = NSEntityDescription.entity(forEntityName: "BMSReinforcedAction", in: context) else {
            return nil
        }
        return BMSReinforcedAction(entity: entity, insertInto: context)
    }

    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var appState: BMSAppState
    @NSManaged var reinforcements: Set<BMSReinforcement>

}

// MARK: Generated accessors for reinforcements
extension BMSReinforcedAction {

    @objc(addReinforcementsObject:)
    @NSManaged func addToReinforcements(_ value: BMSReinforcement)

    @objc(removeReinforcementsObject:)
    @NSManaged func removeFromReinforcements(_ value: BMSReinforcement)

    @objc(addReinforcements:)
    @NSManaged func addToReinforcements(_ values: NSSet)

    @objc(removeReinforcements:)
    @NSManaged func removeFromReinforcements(_ values: NSSet)

}
