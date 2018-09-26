//
//  BMSIntegrationState+CoreDataClass.swift
//  
//
//  Created by Akash Desai on 9/26/18.
//
//

import Foundation
import CoreData

@objc(BMSAppState)
class BMSAppState: NSManagedObject {

    public static var shared: BMSAppState? {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        if let entity = NSEntityDescription.entity(forEntityName: BMSAppState.description(), in: context) {
            return BMSAppState(entity: entity, insertInto: context)
        } else {
            return nil
        }
    }

}
