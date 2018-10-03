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

    class func request() -> NSFetchRequest<BMSAppState> {
        return NSFetchRequest<BMSAppState>(entityName: "BMSAppState")
    }

    @NSManaged var appId: String
    @NSManaged var auth: String
    @NSManaged var versionId: String?
    @NSManaged var configId: String?
    @NSManaged var revision: Int64
    @NSManaged var trackingEnabled: Bool
    @NSManaged var user: BMSUser?
    @NSManaged var effectDetails: String

    var effectDetailsAsDictionary: [String: Any]? {
        get {
            return .from(string: effectDetails)
        }
        set {
            if let dict = newValue.toString() {
                effectDetails = dict
            }
        }
    }

}
