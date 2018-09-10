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
        let countEvents = { return sesame.coreDataManager.countEvents(userId: Sesame.devUserId) }
        XCTAssert(countEvents() == 0)

        addEvent()
        XCTAssert(countEvents() == 1)

        addEvent()
        XCTAssert(countEvents() == 2)
    }

    func testMultipleReports() {
        let sesame = Sesame.dev()
        let countReports = { sesame.coreDataManager.fetchReports(userId: Sesame.devUserId)?.count }
        XCTAssert(countReports() == 0)

        sesame.addEvent(for: "appOpen")
        XCTAssert(countReports() == 1)

        sesame.addEvent(for: "appClose")
        XCTAssert(countReports() == 2)
    }

    func testDeleteData() {
        let sesame = Sesame.dev()
        let countEvents = { sesame.coreDataManager.countEvents(userId: Sesame.devUserId) }
        XCTAssert(countEvents() == 0)

        sesame.addEvent(for: "appOpen")
        sesame.addEvent(for: "appOpen")
        XCTAssert(countEvents() == 2)

        sesame.coreDataManager.deleteObjects()
        XCTAssert(countEvents() == 0)

        sesame.userId = Sesame.devUserId
        sesame.addEvent(for: "appOpen")
        sesame.addEvent(for: "appOpen")
        XCTAssert(countEvents() == 2)

    }

    func testEventsCount() {
        let sesame = Sesame.dev()
        let desiredCount = 5

        let group = DispatchGroup()
        for _ in 1...desiredCount { group.enter() }
        DispatchQueue.concurrentPerform(iterations: desiredCount) { iteration in
            switch iteration % 2 {
            case 0:
                sesame.addEvent(for: "appOpen")
            default:
                sesame.addEvent(for: "appClose")
            }
            group.leave()
        }

        XCTAssert(group.wait(timeout: .now() + 2) == .success)

        let count = sesame.eventCount()
        print("Got count:\(String(describing: count))")
        XCTAssert(count == desiredCount)
    }

    func testAppConfigRemeberLast() {
        var sesame = Sesame.dev()
        let testConfigId = "0123"
        let setConfigId = { sesame.configId = testConfigId }
        XCTAssert(sesame.configId == nil)
        XCTAssert(sesame.config?.configId == nil)

        setConfigId()
        XCTAssert(sesame.configId == testConfigId)
        XCTAssert(sesame.config?.configId == testConfigId)

        sesame = Sesame.dev()
        XCTAssert(sesame.configId == testConfigId)
        XCTAssert(sesame.config?.configId == testConfigId)
    }

    func testAppConfigChangeInMultipleContext() {
        let coreDataManager1 = CoreDataManager()
        let coreDataManager2 = CoreDataManager()
        let appConfig1 = coreDataManager1.fetchAppConfig()
        let appConfig2 = coreDataManager2.fetchAppConfig()
        XCTAssert(appConfig1 != nil)
        XCTAssert(appConfig2 != nil)
        XCTAssert(appConfig1?.configId == appConfig2?.configId)

        Logger.debug("appConfig1?.configId:<\(appConfig1?.configId ?? "nil")>")
        Logger.debug("appConfig2?.configId:<\(appConfig2?.configId ?? "nil")>")
        appConfig1?.configId = "one"
        appConfig2?.configId = "two"
        XCTAssert(appConfig1?.configId != appConfig2?.configId)
        Logger.debug("appConfig1?.configId:<\(appConfig1?.configId ?? "nil")>")
        Logger.debug("appConfig2?.configId:<\(appConfig2?.configId ?? "nil")>")
        coreDataManager1.save()
        Logger.debug("appConfig1?.configId:<\(appConfig1?.configId ?? "nil")>")
        Logger.debug("appConfig2?.configId:<\(appConfig2?.configId ?? "nil")>")
        coreDataManager2.save()
        Logger.debug("appConfig1?.configId:<\(appConfig1?.configId ?? "nil")>")
        Logger.debug("appConfig2?.configId:<\(appConfig2?.configId ?? "nil")>")

        let coreDataManager3 = CoreDataManager()
        let appConfig3 = coreDataManager3.fetchAppConfig()
        Logger.debug("appConfig3?.configId:<\(appConfig3?.configId ?? "nil")>")
    }

    func testUserAddedAfter() {
        let sesame = Sesame.dev()

    }

    func testUserChange() {
        let sesame = Sesame.dev()
        let user1 = "ann"
        let user2 = "bob"
        var currentUser = user1
        let setUser1 = { currentUser = user1; sesame.userId = currentUser }
        let setUser2 = { currentUser = user2; sesame.userId = currentUser }
        let addEvent = { sesame.addEvent(for: "appOpen") }
        let countEvents = { return sesame.coreDataManager.countEvents(userId: currentUser) ?? -1 }
        let deleteReports = { sesame.coreDataManager.deleteReports(userId: currentUser) }

        sesame.coreDataManager.deleteObjects()
        sesame.userId = nil
        XCTAssert(sesame.userId == nil)

        setUser1()
        XCTAssert(countEvents() == 0)
        addEvent()
        XCTAssert(countEvents() == 1)

        setUser2()
        XCTAssert(sesame.userId == user2)
        XCTAssert(countEvents() == 0)
        addEvent()
        XCTAssert(countEvents() == 1)

        setUser1()
        XCTAssert(sesame.userId == user1)
        XCTAssert(countEvents() == 1)
        addEvent()
        XCTAssert(countEvents() == 2)

        setUser2()
        XCTAssert(sesame.userId == user2)
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
            guard let userId = sesame.userId else { fatalError() }
            for cartridge in sesame.coreDataManager.fetchCartridges(userId: userId) ?? [] {
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
            guard let userId = sesame.userId else { fatalError() }
            if let cartridges = sesame.coreDataManager.fetchCartridges(userId: userId) {
                let group = DispatchGroup()
                XCTAssert(cartridges.count != 0)
                for cartridge in cartridges {
                    group.enter()
                    XCTAssert(cartridge.reinforcements?.count == 0)
                    sesame.sendRefresh(userId: userId, actionName: cartridge.actionName!) { _ in
                        group.leave()
                    }
                }
                group.notify(queue: DispatchQueue.global()) {
                    if let cartridges = sesame.coreDataManager.fetchCartridges(userId: userId) {
                        XCTAssert(cartridges.count != 0)
                        for cartridge in cartridges {
                            XCTAssert(cartridge.reinforcements!.count > 0)
                        }
                        promise.fulfill()
                    }
                }

            }
        }

        waitForExpectations(timeout: 3)
    }

}
