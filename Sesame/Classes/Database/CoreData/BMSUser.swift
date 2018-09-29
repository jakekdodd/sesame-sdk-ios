//
//  BMSUser+CoreDataClass.swift
//  
//
//  Created by Akash Desai on 9/26/18.
//
//

import Foundation
import CoreData

@objc(BMSUser)
class BMSUser: NSManagedObject {

    override public func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(UUID().uuidString, forKey: #keyPath(BMSUser.id))
    }

}

extension BMSUser {
    class func fetch(context: NSManagedObjectContext, id: String, createIfNotFound: Bool = true) -> BMSUser? {
        var value: BMSUser?
        context.performAndWait {
            let request = NSFetchRequest<BMSUser>(entityName: BMSUser.description())
            request.predicate = NSPredicate(format: "\(#keyPath(BMSUser.id)) == '\(id)'")
            request.fetchLimit = 1
            do {
                if let user = try context.fetch(request).first {
                    value = user
                } else if createIfNotFound,
                    let entity = NSEntityDescription.entity(forEntityName: BMSUser.description(),
                                                            in: context) {
                    let user = BMSUser(entity: entity, insertInto: context)
                    user.id = id
                    value = user
                    try context.save()
                }
            } catch let error as NSError {
                BMSLog.error("Could not fetch. \(error)")
            }
        }

        return value
    }
}
