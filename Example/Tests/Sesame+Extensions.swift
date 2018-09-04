//
//  Sesame+Extensions.swift
//  Sesame_Example
//
//  Created by Akash Desai on 9/1/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
@testable import Sesame

extension Sesame {
    class var dev: Sesame {
        return Sesame.init(appId: "570ffc491b4c6e9869482fbf",
                           appVersionId: "rams1",
                           auth: "d388c7074d8a283bff1f01eb932c1c9e6bec3b10")
    }

    var eventCountForCurrentUser: Int? {
        return coreDataManager.countEvents(userId: config?.user?.id)
    }

    func addEventForCurrentUser(actionId: String = "appOpen", metadata: [String: Any] = [:]) {
        coreDataManager.insertEvent(userId: config?.user?.id, actionId: actionId, metadata: metadata)
    }
}
