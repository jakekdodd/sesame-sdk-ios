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

    override public func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(BMSCartridge.NeutralCartridgeId, forKey: #keyPath(BMSCartridge.cartridgeId))
    }

    var effectDetailsAsDictionary: [String: Any]? {
        get {
            if let data = effectDetails.data(using: .utf8),
                let json = try? JSONSerialization.jsonObject(with: data, options: []),
                let dict = json as? [String: Any] {
                return dict
            }
            return nil
        }
        set {
            if let dict = newValue,
                let data = try? JSONSerialization.data(withJSONObject: dict),
                let str = String(data: data, encoding: .utf8) {
                effectDetails = str
            }
        }
    }

}

extension BMSCartridge {

    class func fetch(context: NSManagedObjectContext, userId: String, actionName: String) -> BMSCartridge? {
        var value: BMSCartridge?
        context.performAndWait {
            let request = NSFetchRequest<BMSCartridge>(entityName: BMSCartridge.description())
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "\(#keyPath(BMSCartridge.user.id)) == '\(userId)'"),
                NSPredicate(format: "\(#keyPath(BMSCartridge.actionName)) == '\(actionName)'")
                ])
            request.fetchLimit = 1
            do {
                value = try context.fetch(request).first
            } catch let error as NSError {
                BMSLog.error("Could not fetch. \(error)")
            }
        }

        return value
    }

    class func fetch(context: NSManagedObjectContext, userId: String) -> [BMSCartridge]? {
        var value: [BMSCartridge]?
        context.performAndWait {
            let request = NSFetchRequest<BMSCartridge>(entityName: BMSCartridge.description())
            request.predicate = NSPredicate(format: "\(#keyPath(BMSCartridge.user.id)) == '\(userId)'")
            do {
                value = try context.fetch(request)
            } catch let error as NSError {
                BMSLog.error("Could not fetch. \(error)")
            }
        }

        return value
    }

    class func insert(context: NSManagedObjectContext, userId: String, actionName: String, effectDetails: [String: Any]) {
        context.performAndWait {
            guard let user = BMSUser.fetch(context: context, id: userId) else { return }
            guard let entity = NSEntityDescription.entity(forEntityName: BMSCartridge.description(), in: context) else {
                BMSLog.error("Could not create entity for cartridge")
                return
            }
            let cartridge = BMSCartridge(entity: entity, insertInto: context)
            cartridge.actionName = actionName
            cartridge.effectDetailsAsDictionary = effectDetails
            cartridge.user = user
            do {
                try context.save()
            } catch {
                BMSLog.error(error)
            }
        }
    }

    //swiftlint:disable:next function_parameter_count
    class func update(context: NSManagedObjectContext, userId: String, actionName: String, cartridgeId: String, serverUtc: Int64, ttl: Int64, reinforcements: [String], effectDetails: [String: Any]? = nil) {
        context.performAndWait {
            var storedCartridge: BMSCartridge?
            if let cartridge = BMSCartridge.fetch(context: context, userId: userId, actionName: actionName) {
                storedCartridge = cartridge
            } else if let user = BMSUser.fetch(context: context, id: userId),
                let entity = NSEntityDescription.entity(forEntityName: BMSCartridge.description(), in: context) {
                let cartridge = BMSCartridge(entity: entity, insertInto: context)
                cartridge.user = user
                cartridge.actionName = actionName
                cartridge.effectDetailsAsDictionary = effectDetails ?? [:]
            }

            guard let cartridge = storedCartridge else { return }
            cartridge.cartridgeId = cartridgeId
            cartridge.serverUtc = serverUtc
            cartridge.ttl = ttl
            if let effectDetails = effectDetails {
                cartridge.effectDetailsAsDictionary = effectDetails
            }

            for reinforcementName in reinforcements {
                guard let entity =
                    NSEntityDescription.entity(forEntityName: BMSReinforcement.description(), in: context)
                    else { continue }
                let reinforcement = BMSReinforcement(entity: entity, insertInto: context)
                reinforcement.name = reinforcementName
                cartridge.addToReinforcements(reinforcement)
            }

            do {
                try context.save()
            } catch {
                BMSLog.error(error)
            }
        }
    }
}
