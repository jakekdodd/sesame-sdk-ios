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
        let addEvent = { sesame.addEvent(actionName: SesameConstants.AppOpenAction) }
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

        sesame.addEvent(actionName: SesameConstants.AppOpenAction)
        XCTAssert(countReports() == 1)

        sesame.addEvent(actionName: "appClose")
        XCTAssert(countReports() == 2)
    }

    func testDeleteData() {
        let sesame = Sesame.dev()
        let countEvents = { sesame.coreDataManager.countEvents(context: nil, userId: Sesame.devUserId) }
        XCTAssert(countEvents() == 0)

        sesame.addEvent(actionName: SesameConstants.AppOpenAction)
        sesame.addEvent(actionName: SesameConstants.AppOpenAction)
        XCTAssert(countEvents() == 2)

        sesame.coreDataManager.deleteObjects()
        XCTAssert(countEvents() == 0)

        sesame.setUserId(Sesame.devUserId)
        sesame.addEvent(actionName: SesameConstants.AppOpenAction)
        sesame.addEvent(actionName: SesameConstants.AppOpenAction)
        XCTAssert(countEvents() == 2)

    }

    func testConcurrentEventsCount() {
        let sesame = Sesame.dev()
        let desiredCount = 5

        let group = DispatchGroup()
        for _ in 1...desiredCount { group.enter() }
        DispatchQueue.concurrentPerform(iterations: desiredCount) { iteration in
//        for iteration in 1...desiredCount {
            switch iteration % 2 {
            case 0:
                sesame.addEvent(actionName: SesameConstants.AppOpenAction)
            default:
                sesame.addEvent(actionName: "appClose")
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
        let assertConfigId: ((String?) -> Void) = { configId in
            XCTAssert(sesame.configId == configId)
            let context = sesame.coreDataManager.newContext()
            context.performAndWait {
                let config = sesame.coreDataManager.fetchAppConfig(context: context, sesame.configId)
                XCTAssert(config?.configId == configId)
            }
        }

        setConfigId()
        assertConfigId(testConfigId)

        sesame = Sesame.dev()
        assertConfigId(testConfigId)
    }

    func testUserChange() {
        let sesame = Sesame.dev()
        let user1 = "ann"
        let user2 = "bob"
        var currentUser = user1
        let setUser1 = { currentUser = user1; sesame.setUserId(currentUser) }
        let setUser2 = { currentUser = user2; sesame.setUserId(currentUser) }
        let addEvent = { sesame.addEvent(actionName: SesameConstants.AppOpenAction) }
        let countEvents = { return sesame.coreDataManager.countEvents(context: nil, userId: currentUser) ?? -1 }
        let deleteReports = { sesame.coreDataManager.deleteReports(context: nil, userId: currentUser) }

        sesame.coreDataManager.deleteObjects()
        sesame.setUserId(nil)
        XCTAssert(sesame.getUserId() == nil)

        setUser1()
        XCTAssert(sesame.getUserId() == user1)
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
            let context = sesame.coreDataManager.newContext()
            context.performAndWait {
                guard let userId = sesame.getUserId(context),
                    let cartridges = sesame.coreDataManager.fetchCartridges(context: context, userId: userId) else {
                        fatalError()
                }
                XCTAssert(cartridges.count != 0)
                for cartridge in cartridges {
                    XCTAssert(cartridge.reinforcements?.count == 0)
                    sesame.sendRefresh(userId: userId, actionName: cartridge.actionName!) { _ in
                        if let cartridges = sesame.coreDataManager.fetchCartridges(context: context, userId: userId) {
                            XCTAssert(cartridges.count != 0)
                            for cartridge in cartridges {
                                XCTAssert(cartridge.reinforcements!.count > 0)
                            }
                            promise.fulfill()
                        } else { XCTFail("No cartridges") }
                    }
                }
            }
        }

        waitForExpectations(timeout: 3)
    }

}
