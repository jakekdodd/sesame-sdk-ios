//
//  BMSAppState+CoreDataProperties.swift
//  
//
//  Created by Akash Desai on 9/26/18.
//
//

import Foundation
import CoreData

extension BMSAppState {

    @nonobjc class func fetchRequest() -> NSFetchRequest<BMSAppState> {
        return NSFetchRequest<BMSAppState>(entityName: "BMSAppState")
    }

    @NSManaged var appId: String
    @NSManaged var auth: String
    @NSManaged var configId: String?
    @NSManaged var revision: Int64
    @NSManaged var trackingEnabled: Bool
    @NSManaged var versionId: String?
    @NSManaged var user: BMSUser?

}
