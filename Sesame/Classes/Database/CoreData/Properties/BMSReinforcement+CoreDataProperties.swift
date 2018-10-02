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

    @nonobjc class func request() -> NSFetchRequest<BMSReinforcement> {
        return NSFetchRequest<BMSReinforcement>(entityName: "BMSReinforcement")
    }

    @NSManaged var name: String
    @NSManaged var idx: Int32
    @NSManaged var cartridge: BMSCartridge
    @NSManaged var event: BMSEvent?

}
