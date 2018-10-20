//
//  Mock+Sesame.swift
//  Sesame_Example
//
//  Created by Akash Desai on 9/1/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

@testable import Sesame
import CoreData.NSManagedObjectContext

struct Mock {

    static let aid1 = "actionId1"
    static let aname1 = "appOpen"
    static let cid1 = "cartridgeId1"
    static let rid1 = "reinforcementId1"
    static let rname1 = "sheen"
    static let ename1 = "event1"

    static let auth1 = "d388c7074d8a283bff1f01eb932c1c9e6bec3b10"
    static let app1 = "570ffc491b4c6e9869482fbf"
    static let uid1 = "user1"
    static let version1 = "sesame2"

}

class MockSesame: Sesame {

    override init(appId: String = Mock.app1, auth: String = Mock.auth1, versionId: String? = Mock.version1, userId: String = Mock.uid1) {
        super.init(appId: appId, auth: auth, versionId: versionId, userId: userId)
        api = MockAPIClient()
    }

}
