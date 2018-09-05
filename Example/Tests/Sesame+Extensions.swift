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

    static var devUserId = "dev"

    static func dev(user userId: String = Sesame.devUserId) -> Sesame {
        return Sesame(appId: "570ffc491b4c6e9869482fbf",
                      appVersionId: "rams1",
                      auth: "d388c7074d8a283bff1f01eb932c1c9e6bec3b10",
                      userId: userId)
    }

}
