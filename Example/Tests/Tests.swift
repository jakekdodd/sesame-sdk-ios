import XCTest
@testable import Sesame

class Tests: XCTestCase {

    override func setUp() {
        super.setUp()

        CoreDataManager().deleteObjects()
        UserDefaults.sesame.removePersistentDomain(forName: Sesame.description())
    }

    override func tearDown() {
        super.tearDown()
    }

    func testMultipleEvents() {
        let sesame = Sesame.dev()
        let addEvent = { sesame.addEvent(for: "appOpen") }
        let countEvents = { return sesame.coreDataManager.countEvents(context: nil, userId: Sesame.devUserId) }
        XCTAssert(countEvents() == 0)

        addEvent()
        XCTAssert(countEvents() == 1)

        addEvent()
        XCTAssert(countEvents() == 2)
    }

    func testMultipleReports() {
        let sesame = Sesame.dev()
        let countReports = { sesame.coreDataManager.fetchReports(context: nil, userId: Sesame.devUserId)?.count }
        XCTAssert(countReports() == 0)

        sesame.addEvent(for: "appOpen")
        XCTAssert(countReports() == 1)

        sesame.addEvent(for: "appClose")
        XCTAssert(countReports() == 2)
    }

    func testDeleteData() {
        let sesame = Sesame.dev()
        let countEvents = { sesame.coreDataManager.countEvents(context: nil, userId: Sesame.devUserId) }
        XCTAssert(countEvents() == 0)

        sesame.addEvent(for: "appOpen")
        sesame.addEvent(for: "appOpen")
        XCTAssert(countEvents() == 2)

        sesame.coreDataManager.deleteObjects()
        XCTAssert(countEvents() == 0)

        sesame.setUserId(Sesame.devUserId)
        sesame.addEvent(for: "appOpen")
        sesame.addEvent(for: "appOpen")
        XCTAssert(countEvents() == 2)

    }

//    func testConcurrentEventsCount() {
//        let sesame = Sesame.dev()
//        let desiredCount = 5
//
//        let group = DispatchGroup()
//        for _ in 1...desiredCount { group.enter() }
//        DispatchQueue.concurrentPerform(iterations: desiredCount) { iteration in
//            switch iteration % 2 {
//            case 0:
//                sesame.addEvent(for: "appOpen")
//            default:
//                sesame.addEvent(for: "appClose")
//            }
//            group.leave()
//        }
//
//        XCTAssert(group.wait(timeout: .now() + 2) == .success)
//
//        let count = sesame.eventCount()
//        print("Got count:\(String(describing: count))")
//        XCTAssert(count == desiredCount)
//    }

    func testAppConfigRemeberLast() {
        var sesame = Sesame.dev()
        let testConfigId = "0123"
        let setConfigId = { sesame.configId = testConfigId }
        let assertConfigId: ((String?) -> Void) = { configId in
            XCTAssert(sesame.configId == configId)
            let (context, config, _) = sesame.contextConfigUser
            context.performAndWait {
                XCTAssert(config?.configId == configId)
            }
        }

        setConfigId()
        assertConfigId(testConfigId)

        sesame = Sesame.dev()
        assertConfigId(testConfigId)
    }

//    func testAppConfigChangeInMultipleContext() {
//        let coreDataManager1 = CoreDataManager()
//        let coreDataManager2 = CoreDataManager()
//        let appConfig1 = coreDataManager1.fetchAppConfig(context: nil)
//        let appConfig2 = coreDataManager2.fetchAppConfig(context: nil)
//        XCTAssert(appConfig1?.managedObjectContext != nil)
//        XCTAssert(appConfig2?.managedObjectContext != nil)
//        let setConfigId: ((AppConfig?, String) -> Void) = { config, configId in
//            config?.managedObjectContext?.performAndWait {
//                config?.configId = configId
//                do {
//                    try config?.managedObjectContext?.save()
//                    config?.managedObjectContext?.parent?.performAndWait {
//                        do {
//                            try config?.managedObjectContext?.parent?.save()
//                        } catch {
//                            Logger.debug(error: error.localizedDescription)
//                        }
//                    }
//                } catch {
//                    Logger.debug(error: error.localizedDescription)
//                }
//            }
//        }
//        let getConfigId: ((AppConfig?) -> String?) = { config in
//            var configId: String?
//            config?.managedObjectContext?.performAndWait {
//                configId = config?.configId
//            }
//            return configId
//        }
//
//        XCTAssert(appConfig1?.configId == appConfig2?.configId)
//
//        Logger.debug("appConfig1?.configId:<\(appConfig1?.configId ?? "nil")>")
//        Logger.debug("appConfig2?.configId:<\(appConfig2?.configId ?? "nil")>")
//        setConfigId(appConfig1, "one")
//        setConfigId(appConfig2, "two")
//        Logger.debug("appConfig1?.configId:<\(appConfig1?.configId ?? "nil")>")
//        Logger.debug("appConfig2?.configId:<\(appConfig2?.configId ?? "nil")>")
//        XCTAssert(appConfig1?.configId != appConfig2?.configId)
//        coreDataManager1.save()
//        Logger.debug("appConfig1?.configId:<\(appConfig1?.configId ?? "nil")>")
//        Logger.debug("appConfig2?.configId:<\(appConfig2?.configId ?? "nil")>")
//        coreDataManager2.save()
//        Logger.debug("appConfig1?.configId:<\(appConfig1?.configId ?? "nil")>")
//        Logger.debug("appConfig2?.configId:<\(appConfig2?.configId ?? "nil")>")
//
//        let coreDataManager3 = CoreDataManager()
//        let appConfig3 = coreDataManager3.fetchAppConfig(context: nil)
//        Logger.debug("appConfig3?.configId:<\(appConfig3?.configId ?? "nil")>")
//    }
//
//    func testUserAddedAfter() {
//        let sesame = Sesame.dev()
//
//    }

    func testUserChange() {
        let sesame = Sesame.dev()
        let context = sesame.coreDataManager.newContext()
        let user1 = "ann"
        let user2 = "bob"
        var currentUser = user1
        let setUser1 = { currentUser = user1; sesame.setUserId(currentUser) }
        let setUser2 = { currentUser = user2; sesame.setUserId(currentUser) }
        let addEvent = { sesame.addEvent(for: "appOpen") }
        let countEvents = { return sesame.coreDataManager.countEvents(context: context, userId: currentUser) ?? -1 }
        let deleteReports = { sesame.coreDataManager.deleteReports(context: context, userId: currentUser) }

        sesame.coreDataManager.deleteObjects()
        sesame.setUserId(nil)
        XCTAssert(sesame.getUserId() == nil)

        setUser1()
        XCTAssert(countEvents() == 0)
        addEvent()
        XCTAssert(countEvents() == 1)

        setUser2()
        XCTAssert(sesame.getUserId() == user2)
        XCTAssert(countEvents() == 0)
        addEvent()
        XCTAssert(countEvents() == 1)

        setUser1()
        XCTAssert(sesame.getUserId() == user1)
        XCTAssert(countEvents() == 1)
        addEvent()
        XCTAssert(countEvents() == 2)

        setUser2()
        XCTAssert(sesame.getUserId() == user2)
        XCTAssert(countEvents() == 1)
        deleteReports()
        XCTAssert(countEvents() == 0)

        setUser1()
        XCTAssert(countEvents() == 2)
        deleteReports()
        XCTAssert(countEvents() == 0)
    }

    func testCartridgeStorage() {
        let sesame = Sesame.dev()

        let promise = expectation(description: "Did boot")
        sesame.sendBoot { _ in
            guard let userId = sesame.getUserId() else { fatalError() }
            for cartridge in sesame.coreDataManager.fetchCartridges(context: nil, userId: userId) ?? [] {
                Logger.debug(cartridge.debugDescription)
            }
            promise.fulfill()
        }

        waitForExpectations(timeout: 3)
    }

    func testCartridgeRefresh() {
        let sesame = Sesame.dev()

        let promise = expectation(description: "Did boot")
        sesame.sendBoot { _ in
            guard let userId = sesame.getUserId() else { fatalError() }
            let (context, _, user) = sesame.contextConfigUser
            if let cartridges = sesame.coreDataManager.fetchCartridges(context: context, userId: userId) {
                let group = DispatchGroup()
                XCTAssert(cartridges.count != 0)
                for cartridge in cartridges {
                    context.performAndWait {
                        group.enter()
                        XCTAssert(cartridge.reinforcements?.count == 0)
                        sesame.sendRefresh(userId: userId, actionName: cartridge.actionName!) { _ in
                            group.leave()
                        }
                    }
                }
                group.notify(queue: DispatchQueue.global()) {
                    let (context, _, _) = sesame.contextConfigUser
                    if let cartridges = sesame.coreDataManager.fetchCartridges(context: context, userId: userId) {
                        context.performAndWait {
                            XCTAssert(cartridges.count != 0)
                            for cartridge in cartridges {
                                XCTAssert(cartridge.reinforcements!.count > 0)
                            }
                            promise.fulfill()
                        }
                    }
                }

            }
        }

        waitForExpectations(timeout: 3)
    }

}
