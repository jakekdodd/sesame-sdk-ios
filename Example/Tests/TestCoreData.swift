//
//  TestCoreData.swift
//  
//
//  Created by Akash Desai on 9/30/18.
//

import XCTest
@testable import Sesame
import CoreData

class TestCoreData: XCTestCase {

    var testAppId = "testAppId"
    var testAppAuth = "testAppAuth"
    var testUserId = "dev"
    var testActionName = "testAction"
    var testCartridgeId = "testCartridgeId"

    override func setUp() {
        CoreDataManager().deleteObjects()
    }

    override func tearDown() {

    }

    func testAppState() {
        let coreData = CoreDataManager()

        XCTAssert(BMSAppState.fetch(context: coreData.newContext(), appId: testAppId) == nil)

        coreData.inNewContext { context in
            _ = BMSAppState.insert(context: context, appId: testAppId, auth: testAppAuth)
        }
        XCTAssert(BMSAppState.fetch(context: coreData.newContext(), appId: testAppId) != nil)

        XCTAssert(BMSAppState.delete(context: coreData.newContext(), appId: testAppId) == 1)

        XCTAssert(BMSAppState.fetch(context: coreData.newContext(), appId: testAppId) == nil)
    }

    func testUser() {
        let coreData = CoreDataManager()

        XCTAssert(BMSUser.fetch(context: coreData.newContext(), id: testUserId) == nil)

        coreData.inNewContext { context in
            _ = BMSUser.insert(context: context, id: testUserId)
        }
        XCTAssert(BMSUser.fetch(context: coreData.newContext(), id: testUserId) != nil)

        XCTAssert(BMSUser.delete(context: coreData.newContext()) == 1)

        XCTAssert(BMSUser.fetch(context: coreData.newContext(), id: testUserId) == nil)
    }

    func testEvent() {
        let coreData = CoreDataManager()

        coreData.inNewContext { context in
            guard let user = BMSUser.insert(context: context, id: testUserId) else { fatalError() }
            XCTAssert(BMSEvent.count(context: context) == 0)

            guard let _ = BMSEvent.insert(context: context, userId: user.id, actionName: testActionName) else { fatalError() }
            XCTAssert(BMSEvent.count(context: context) == 1)
        }
    }

    func testCartridge() {
        let coreData = CoreDataManager()

        coreData.inNewContext { context in
            guard let user = BMSUser.insert(context: context, id: testUserId) else { fatalError() }
            XCTAssert(BMSCartridge.fetch(context: context, userId: testUserId, actionName: testActionName) == nil)

            guard let cartridge = BMSCartridge.insert(context: context,
                                                      userId: user.id,
                                                      actionName: testActionName,
                                                      cartridgeId: testCartridgeId,
                                                      reinforcementNames: ["reward"])
                else { fatalError() }
            XCTAssert(BMSCartridge.fetch(context: context, userId: testUserId, actionName: testActionName) != nil)

            guard let reinforcement = cartridge.nextReinforcement,
                reinforcement.name == "reward",
                nil != BMSEvent.insert(context: context,
                                         userId: user.id,
                                         actionName: testActionName,
                                         reinforcement: reinforcement)
                else { fatalError() }

            guard cartridge.nextReinforcement == nil else { fatalError() }
        }
    }

    func testCartridgeNeutral() {
        let coreData = CoreDataManager()

        coreData.inNewContext { context in
            guard let user = BMSUser.insert(context: context, id: testUserId) else { fatalError() }
            XCTAssert(BMSCartridge.fetch(context: context, userId: testUserId, actionName: testActionName) == nil)

            guard let cartridge = BMSCartridge.insert(context: context,
                                                      userId: user.id,
                                                      actionName: testActionName,
                                                      cartridgeId: BMSCartridge.NeutralCartridgeId)
                else { fatalError() }
            XCTAssert(BMSCartridge.fetch(context: context, userId: testUserId, actionName: testActionName) != nil)

            guard let reinforcement = cartridge.nextReinforcement,
                reinforcement.name == BMSReinforcement.NeutralName
            else { fatalError() }
            guard nil != BMSEvent.insert(context: context,
                                          userId: user.id,
                                          actionName: testActionName,
                                          reinforcement: reinforcement)
                else { fatalError() }

            XCTAssert(cartridge.nextReinforcement?.name == BMSReinforcement.NeutralName)
        }
    }
}

extension CoreDataManager {
    func inNewContext(completion: (NSManagedObjectContext) -> Void) {
        let context = newContext()
        context.performAndWait {
            completion(context)
        }
    }
}
