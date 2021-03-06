//
//  Test+CoreData.swift
//
//
//  Created by Akash Desai on 9/30/18.
//

import XCTest
@testable import Sesame
import CoreData

class TestCoreData: XCTestCase {

    override func setUp() {
        CoreDataManager().deleteObjects()
    }

    override func tearDown() {

    }

    func testAppState() {
        let coreData = CoreDataManager()

        XCTAssert(BMSAppState.fetch(context: coreData.newContext(), appId: Mock.app1) == nil)

        coreData.newContext { context in
            _ = BMSAppState.insert(context: context, appId: Mock.app1, auth: Mock.auth1)
        }
        XCTAssert(BMSAppState.fetch(context: coreData.newContext(), appId: Mock.app1) != nil)

        XCTAssert(BMSAppState.delete(context: coreData.newContext(), appId: Mock.app1) == 1)

        XCTAssert(BMSAppState.fetch(context: coreData.newContext(), appId: Mock.app1) == nil)
    }

    func testUser() {
        let coreData = CoreDataManager()

        XCTAssert(BMSUser.fetch(context: coreData.newContext(), id: Mock.uid1) == nil)

        coreData.newContext { context in
            _ = BMSUser.insert(context: context, id: Mock.uid1)
        }
        XCTAssert(BMSUser.fetch(context: coreData.newContext(), id: Mock.uid1) != nil)

        XCTAssert(BMSUser.delete(context: coreData.newContext()) == 1)

        XCTAssert(BMSUser.fetch(context: coreData.newContext(), id: Mock.uid1) == nil)
    }

    func testEvent() {
        let coreData = CoreDataManager()

        coreData.newContext { context in
            XCTAssert(nil != BMSUser.insert(context: context, id: Mock.uid1))
            XCTAssert(BMSEvent.count(context: context) == 0)

            XCTAssert(nil != BMSEvent.insert(context: context, userId: Mock.uid1, actionName: Mock.aname1))
            XCTAssert(BMSEvent.count(context: context) == 1)
        }
    }

    func testCartridge() {
        let coreData = CoreDataManager()

        coreData.newContext { context in
            guard let user = BMSUser.insert(context: context, id: Mock.uid1) else { fatalError() }
            guard nil != BMSCartridge.insert(context: context,
                                                      userId: user.id,
                                                      actionId: Mock.aid1)
                else { fatalError() }
            XCTAssert(BMSEvent.count(context: context) == 0)

            guard nil != BMSEvent.insert(context: context,
                                          userId: user.id,
                                          actionName: Mock.aname1)
                else { fatalError() }
            XCTAssert(BMSEvent.count(context: context) == 1)
        }
    }

    func testCartridgeReinforcement() {
        let coreData = CoreDataManager()

        coreData.newContext { context in
            guard let user = BMSUser.insert(context: context,
                                            id: Mock.uid1)
                else { fatalError() }
            XCTAssert(BMSCartridge.fetch(context: context, userId: Mock.uid1)?.isEmpty ?? false)

            guard let cartridge = BMSCartridge.insert(context: context,
                                                      userId: user.id,
                                                      actionId: Mock.aid1,
                                                      cartridgeId: Mock.cid1,
                                                      ttl: 3600000,
                                                      reinforcementIdAndName: [(Mock.rid1, Mock.rname1)])
                else { fatalError() }
            XCTAssert(BMSCartridge.fetch(context: context,
                                         userId: Mock.uid1)?.count ?? 0 == 1)
            XCTAssert(BMSCartridge.fetch(context: context,
                                         userId: Mock.uid1,
                                         actionId: Mock.aid1)?.first != nil)

            guard let reinforcement = cartridge.nextReinforcement,
                reinforcement.name == Mock.rname1,
                nil != BMSEvent.insert(context: context,
                                         userId: user.id,
                                         actionName: Mock.aname1,
                                         reinforcement: reinforcement)
                else { fatalError() }

            guard cartridge.nextReinforcement == nil else { fatalError() }

            _ = (BMSReport.fetch(context: context, userId: user.id)?
                .flatMap({$0.events}) as? [BMSEvent])?.compactMap({context.delete($0)})
            XCTAssert(BMSReport.fetch(context: context, userId: user.id)?.count == 0)
        }
    }

    func testCartridgeNeutral() {
        let coreData = CoreDataManager()

        coreData.newContext { context in
            guard let user = BMSUser.insert(context: context, id: Mock.uid1) else { fatalError() }
            XCTAssert(BMSCartridge.fetch(context: context,
                                         userId: Mock.uid1,
                                         actionId: Mock.aid1)?.isEmpty ?? false)

            XCTAssert(nil != BMSCartridge.insert(context: context,
                                                      userId: user.id,
                                                      actionId: Mock.aid1,
                                                      cartridgeId: BMSCartridge.NeutralCartridgeId))

            XCTAssert(BMSCartridge.fetch(context: context,
                                         userId: user.id)?.count ?? 0 == 1)
            XCTAssert(BMSCartridge.fetch(context: context,
                                         userId: user.id,
                                         actionId: Mock.aid1)?.first != nil)
            coreData.save()
        }

        coreData.newContext { context in
            guard let user = BMSUser.insert(context: context, id: Mock.uid1),
                let cartridge = BMSCartridge.fetch(context: context, userId: user.id, actionId: Mock.aid1)?.first,
                let reinforcement = cartridge.nextReinforcement,
                reinforcement.name == BMSReinforcement.NeutralName
            else { fatalError() }
            guard nil != BMSEvent.insert(context: context,
                                          userId: user.id,
                                          actionName: Mock.aname1,
                                          reinforcement: reinforcement)
                else { fatalError() }

            XCTAssert(cartridge.nextReinforcement?.name == BMSReinforcement.NeutralName)
        }
    }

    func testReport() {
        let coreData = CoreDataManager()

        coreData.newContext { context in
            guard let user = BMSUser.insert(context: context,
                                            id: Mock.uid1)
                else { fatalError() }
            XCTAssert(BMSReport.fetch(context: context,
                                      userId: user.id)?.isEmpty ?? false)

            XCTAssert(BMSReport.insert(context: context,
                                       userId: user.id,
                                       actionName: Mock.aname1) != nil)
            XCTAssert(BMSReport.fetch(context: context,
                                      userId: Mock.uid1)?.count ?? 0 == 1)
            XCTAssert(BMSReport.fetch(context: context,
                                      userId: Mock.uid1,
                                      actionName: Mock.aname1) != nil)

            XCTAssert(BMSEvent.insert(context: context,
                                      userId: user.id,
                                      actionName: Mock.aname1) != nil)
            XCTAssert(BMSReport.fetch(context: context,
                                      userId: user.id,
                                      actionName: Mock.aname1)?.events.count == 1)

            _ = (BMSReport.fetch(context: context,
                            userId: user.id,
                                 actionName: Mock.aname1)?.events.array as? [BMSEvent])?
                .compactMap({context.delete($0)})
            XCTAssert(BMSReport.fetch(context: context,
                                      userId: user.id)?.isEmpty ?? false)
        }

    }
}
