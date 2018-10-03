//
//  Sesame+Extensions.swift
//  Sesame_Example
//
//  Created by Akash Desai on 9/1/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

@testable import Sesame
import CoreData.NSManagedObjectContext

extension Sesame {

    static var devUserId = "dev"

    static func dev(user userId: String = Sesame.devUserId) -> Sesame {
        let sesame = Sesame(appId: "570ffc491b4c6e9869482fbf",
                      auth: "d388c7074d8a283bff1f01eb932c1c9e6bec3b10",
                      versionId: "sesame2",
                      userId: userId)
        sesame.api = MockAPIClient()
        return sesame
    }

}

extension CoreDataManager {
    func inNewContext(completion: (NSManagedObjectContext) -> Void) {
        let context = newContext()
        context.performAndWait {
            completion(context)
            try? context.save()
        }
    }
}
