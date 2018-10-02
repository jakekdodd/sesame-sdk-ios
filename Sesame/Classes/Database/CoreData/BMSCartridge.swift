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

    var needsRefresh: Bool {
        return (reinforcements.array as? [BMSReinforcement])?.filter({$0.event == nil}).isEmpty ?? false
    }

    var nextReinforcement: BMSReinforcement? {
        guard let context = managedObjectContext else { return nil }
        var value: BMSReinforcement?
        context.performAndWait {
//            BMSLog.warning("Total Cartridges: \(BMSCartridge.fetch(context: context, userId: user.id)?.count ?? -1)")
            if let reinforcements = reinforcements.array as? [BMSReinforcement],
                let reinforcement = reinforcements.filter({$0.event == nil}).first {
                value = reinforcement
//                BMSLog.warning("Available Reinforcements:\(reinforcements.filter({$0.event == nil}).count)")
            } else if cartridgeId == BMSCartridge.NeutralCartridgeId,
                let reinforcement = BMSReinforcement.insert(context: context,
                                                            cartridge: self,
                                                            name: BMSReinforcement.NeutralName,
                                                            idx: Int32(reinforcements.count)
                                                            ) {
                BMSLog.warning("Cartridge is empty. Delivering default reinforcement.")
                value = reinforcement
            }
        }
        return value
    }

}

extension BMSCartridge {

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

    class func fetch(context: NSManagedObjectContext, userId: String, actionName: String) -> [BMSCartridge]? {
        var value: [BMSCartridge]?
        context.performAndWait {
            let request = BMSCartridge.request()
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "\(#keyPath(BMSCartridge.user.id)) == '\(userId)'"),
                NSPredicate(format: "\(#keyPath(BMSCartridge.actionName)) == '\(actionName)'")
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
    class func insert(context: NSManagedObjectContext, userId: String, actionName: String, cartridgeId: String = BMSCartridge.NeutralCartridgeId, utc: Int64 = Int64(Date().timeIntervalSinceNow * 1000), ttl: Int64 = 0, reinforcementNames: [String] = []) -> BMSCartridge? {
        var value: BMSCartridge?
        context.performAndWait {
            if let user = BMSUser.fetch(context: context, id: userId),
                let entity = NSEntityDescription.entity(forEntityName: BMSCartridge.description(), in: context) {
                let cartridge = BMSCartridge(entity: entity, insertInto: context)
                cartridge.user = user
                cartridge.actionName = actionName
                cartridge.cartridgeId = cartridgeId
                cartridge.utc = utc
                cartridge.ttl = ttl
                var idx: Int32 = 0
                _ = reinforcementNames.compactMap({
                    _ = BMSReinforcement.insert(context: context, cartridge: cartridge, name: $0, idx: idx)
                    idx += 1
                })
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
