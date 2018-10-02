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
        let addEvent = { sesame.addEvent(actionName: BMSEvent.AppOpenName) }
        let countEvents = { return BMSEvent.count(context: sesame.coreDataManager.newContext(), userId: Sesame.devUserId) }
        XCTAssert(countEvents() == 0)

        addEvent()
        XCTAssert(countEvents() == 1)

        addEvent()
        XCTAssert(countEvents() == 2)
    }

    func testMultipleReports() {
        let sesame = Sesame.dev()
        let countReports = { BMSReport.fetch(context: sesame.coreDataManager.newContext(), userId: Sesame.devUserId)?.count }
        XCTAssert(countReports() == 0)

        sesame.addEvent(actionName: BMSEvent.AppOpenName)
        XCTAssert(countReports() == 1)

        sesame.addEvent(actionName: "appClose")
        XCTAssert(countReports() == 2)
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
                sesame.addEvent(actionName: BMSEvent.AppOpenName)
            default:
                sesame.addEvent(actionName: "appClose")
            }
            group.leave()
        }

        XCTAssert(group.wait(timeout: .now() + 2) == .success)

        let count = sesame.eventCount()
        BMSLog.info("Got count:\(String(describing: count))")
        XCTAssert(count == desiredCount)
    }

//    func testAppStateRemeberLast() {
//        var sesame = Sesame.dev()
//        let testConfigId = "0123"
//        let setConfigId = { sesame.configId = testConfigId }
//        let assertConfigId: ((String?) -> Void) = { configId in
//            XCTAssert(sesame.configId == configId)
//            let context = sesame.coreDataManager.newContext()
//            context.performAndWait {
//                let config = BMSAppState.fetch(context: context, configId: sesame.configId)
//                XCTAssert(config?.configId == configId)
//            }
//        }
//
//        setConfigId()
//        assertConfigId(testConfigId)
//
//        sesame = Sesame.dev()
//        assertConfigId(testConfigId)
//    }

    func testUserChange() {
        let sesame = Sesame.dev()
        let user1 = "ann"
        let user2 = "bob"
        var currentUser = user1
        let setUser1 = { currentUser = user1; sesame.setUserId(currentUser) }
        let setUser2 = { currentUser = user2; sesame.setUserId(currentUser) }
        let addEvent = { sesame.addEvent(actionName: BMSEvent.AppOpenName) }
        let countEvents = { return BMSEvent.count(context: sesame.coreDataManager.newContext(), userId: currentUser) ?? -1 }
        let deleteEvents = {
            sesame.coreDataManager.inNewContext { context in
                _ = (BMSReport.fetch(context: context, userId: currentUser, actionName: BMSEvent.AppOpenName)?
                    .events.array as? [BMSEvent])?
                    .map({context.delete($0)})
            }
        }

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
        deleteEvents()
        XCTAssert(countEvents() == 0)

        setUser1()
        XCTAssert(countEvents() == 2)
        deleteEvents()
        XCTAssert(countEvents() == 0)
    }

    func testSendTracks() {
        let sesame = Sesame.dev()

        sesame.addEvent(actionName: "action1")
        sesame.addEvent(actionName: "action1")
        sesame.addEvent(actionName: "action2")

        let promise = expectation(description: "Did send tracks")
        sesame.sendTracks(context: sesame.coreDataManager.newContext(), userId: sesame.getUserId()!) { success in
            XCTAssert(success)
            XCTAssert(BMSReport.fetch(context: sesame.coreDataManager.newContext(),
                                      userId: sesame.getUserId()!)?
                .count == 0)
            promise.fulfill()
        }

        waitForExpectations(timeout: 3)
    }

    func testCartridgeStorage() {
        let sesame = Sesame.dev()

        let promise = expectation(description: "Did boot")
        sesame.sendBoot { _ in
            guard let userId = sesame.getUserId() else { fatalError() }
            let context = sesame.coreDataManager.newContext()
            for cartridge in BMSCartridge.fetch(context: context, userId: userId) ?? [] {
                BMSLog.info(cartridge.debugDescription)
            }
            promise.fulfill()
        }

        waitForExpectations(timeout: 3)
    }

    func testCartridgeRefresh() {
        let sesame = Sesame.dev()

        let promise = expectation(description: "Did refresh")
        sesame.sendBoot { _ in
            let context = sesame.coreDataManager.newContext()
            context.performAndWait {
                guard let userId = sesame.getUserId(context) else {
                    fatalError()
                }
                sesame.sendRefresh(context: context, actionName: BMSEvent.AppOpenName) { success in
                    XCTAssert(success)
                    let context = sesame.coreDataManager.newContext()
                    context.performAndWait {
                        guard let cartridges = BMSCartridge.fetch(context: context, userId: userId)?.first else { fatalError() }
                        XCTAssert(!cartridges.reinforcements.array.isEmpty)
                        promise.fulfill()
                    }
                }
            }
        }

        waitForExpectations(timeout: 3)
    }

}
