//
//  BMSReinforcement+CoreDataProperties.swift
//  
//
//  Created by Akash Desai on 9/26/18.
//
//

import Foundation
import CoreData

extension BMSReinforcement {

    @nonobjc class func fetchRequest() -> NSFetchRequest<BMSReinforcement> {
        return NSFetchRequest<BMSReinforcement>(entityName: "BMSReinforcement")
    }

    @NSManaged var name: String
    @NSManaged var cartridge: BMSCartridge
    @NSManaged var event: BMSEvent?

}
