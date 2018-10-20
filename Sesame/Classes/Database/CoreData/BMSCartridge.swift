//
//  BMSCartridge+CoreDataClass.swift
//  
//
//  Created by Akash Desai on 9/26/18.
//
//

import Foundation
import CoreData

@objc(BMSCartridge)
class BMSCartridge: NSManagedObject {

    static let NeutralCartridgeId = "CLIENT_NEUTRAL"

    @NSManaged var actionId: String
    @NSManaged var cartridgeId: String
    @NSManaged var utc: Int64
    @NSManaged var ttl: Int64
    @NSManaged var reinforcements: NSOrderedSet
    @NSManaged var user: BMSUser

    var nextReinforcement: BMSCartridgeReinforcement? {
        guard let context = managedObjectContext else { return nil }
        var value: BMSCartridgeReinforcement?
        context.performAndWait {
//            let cartridgeCount = BMSCartridge.fetch(context: context, userId: user.id)?.compactMap({$0})
//            BMSLog.warning("Total Cartridges: \(cartridgeCount as AnyObject)")
            if (utc + ttl) >= Int64(1000 * Date().timeIntervalSince1970),
                let reinforcements = reinforcements.array as? [BMSCartridgeReinforcement],
                let reinforcement = reinforcements.filter({$0.event == nil}).first {
                value = reinforcement
                BMSLog.warning("Available Reinforcements:\(reinforcements.filter({$0.event == nil}).count)")
            } else if cartridgeId == BMSCartridge.NeutralCartridgeId,
                let reinforcement = BMSCartridgeReinforcement.insert(context: context,
                                                            cartridge: self,
                                                            id: BMSCartridgeReinforcement.NeutralId,
                                                            idx: Int32(reinforcements.count)
                                                            ) {
                BMSLog.warning("Cartridge is empty. Delivering default reinforcement.")
                value = reinforcement
            }
        }
        return value
    }

    // MARK: Generated accessors for reinforcements
    @objc(insertObject:inReinforcementsAtIndex:)
    @NSManaged func insertIntoReinforcements(_ value: BMSCartridgeReinforcement, at idx: Int)

    @objc(removeObjectFromReinforcementsAtIndex:)
    @NSManaged func removeFromReinforcements(at idx: Int)

    @objc(insertReinforcements:atIndexes:)
    @NSManaged func insertIntoReinforcements(_ values: [BMSCartridgeReinforcement], at indexes: NSIndexSet)

    @objc(removeReinforcementsAtIndexes:)
    @NSManaged func removeFromReinforcements(at indexes: NSIndexSet)

    @objc(replaceObjectInReinforcementsAtIndex:withObject:)
    @NSManaged func replaceReinforcements(at idx: Int, with value: BMSCartridgeReinforcement)

    @objc(replaceReinforcementsAtIndexes:withReinforcements:)
    @NSManaged func replaceReinforcements(at indexes: NSIndexSet, with values: [BMSCartridgeReinforcement])

    @objc(addReinforcementsObject:)
    @NSManaged func addToReinforcements(_ value: BMSCartridgeReinforcement)

    @objc(removeReinforcementsObject:)
    @NSManaged func removeFromReinforcements(_ value: BMSCartridgeReinforcement)

    @objc(addReinforcements:)
    @NSManaged func addToReinforcements(_ values: NSOrderedSet)

    @objc(removeReinforcements:)
    @NSManaged func removeFromReinforcements(_ values: NSOrderedSet)

}

extension BMSCartridge {

    class func create(in context: NSManagedObjectContext) -> BMSCartridge? {
        guard let entity = NSEntityDescription.entity(forEntityName: "BMSCartridge", in: context) else {
            return nil
        }
        return BMSCartridge(entity: entity, insertInto: context)
    }

    class func request() -> NSFetchRequest<BMSCartridge> {
        return NSFetchRequest<BMSCartridge>(entityName: "BMSCartridge")
    }

    class func needsRefresh(context: NSManagedObjectContext, userId: String, actionIds: [String]) -> [String] {
        var value = [String]()
        context.performAndWait {
            let now = Int64(Date().timeIntervalSince1970 * 1000)
            for actionId in actionIds {
                guard let cartridge = BMSCartridge.fetch(context: context,
                                                         userId: userId,
                                                         actionId: actionId)?
                    .first else {
                        value.append(actionId)
                        continue
                }
                if cartridge.cartridgeId == BMSCartridge.NeutralCartridgeId ||
                    cartridge.utc + cartridge.ttl < now ||
                    cartridge.reinforcements.filter({($0 as? BMSCartridgeReinforcement)?.event == nil}).isEmpty {
                    value.append(actionId)
                    continue
                }
            }
        }
        return value
    }

    class func fetch(context: NSManagedObjectContext, userId: String) -> [BMSCartridge]? {
        var value: [BMSCartridge]?
        context.performAndWait {
            let request = BMSCartridge.request()
            request.predicate = NSPredicate(format: "\(#keyPath(BMSCartridge.user.id)) == '\(userId)'")
            do {
                value = try context.fetch(request)
            } catch let error as NSError {
                BMSLog.error("Could not fetch. \(error)")
            }
        }
        return value
    }

    class func fetch(context: NSManagedObjectContext, userId: String, actionId: String) -> [BMSCartridge]? {
        var value: [BMSCartridge]?
        context.performAndWait {
            let request = BMSCartridge.request()
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "\(#keyPath(BMSCartridge.user.id)) == '\(userId)'"),
                NSPredicate(format: "\(#keyPath(BMSCartridge.actionId)) == '\(actionId)'")
                ])
            request.sortDescriptors = [NSSortDescriptor(key: #keyPath(BMSCartridge.utc), ascending: false)]
            do {
                value = try context.fetch(request)
            } catch let error as NSError {
                BMSLog.error("Could not fetch. \(error)")
            }
        }
        return value
    }

    @discardableResult
    class func deleteStale(context: NSManagedObjectContext, userId: String) -> Int {
        var value = 0
        context.performAndWait {
            let now = Int64(Date().timeIntervalSince1970 * 1000)
            for cartridge in fetch(context: context, userId: userId) ?? [] {
                if (cartridge.utc + cartridge.ttl) < now {
                    if cartridge.reinforcements.array.filter({($0 as? BMSCartridgeReinforcement)?.event != nil}).isEmpty {
                        context.delete(cartridge)
                        value += 1
                    }
                } else if cartridge.reinforcements.array.isEmpty {
                    context.delete(cartridge)
                    value += 1
                }
            }
        }
        return value
    }

    @discardableResult
    class func insert(context: NSManagedObjectContext, user: BMSUser, actionId: String, cartridgeId: String = BMSCartridge.NeutralCartridgeId, utc: Int64 = Int64(Date().timeIntervalSince1970 * 1000), ttl: Int64 = 0, reinforcements: [BMSCartridgeReinforcement.Holder] = []) -> BMSCartridge? {
        var value: BMSCartridge?
        context.performAndWait {
            if let cartridge = BMSCartridge.create(in: context) {
                cartridge.user = user
                cartridge.actionId = actionId
                cartridge.cartridgeId = cartridgeId
                cartridge.utc = utc
                cartridge.ttl = ttl
                for reinforcement in reinforcements {
                    guard let id = reinforcement.id,
                        let idx = reinforcement.idx else { continue }
                    BMSCartridgeReinforcement.insert(context: context, cartridge: cartridge, id: id, idx: idx)
                }
                BMSLog.warning("Inserted cartridge with :\(cartridge.reinforcements.count) reinforcements")
                do {
                    try context.save()
                } catch let error as NSError {
                    BMSLog.error("Could not insert. \(error)")
                }
                value = cartridge
            }
        }
        return value
    }

}
