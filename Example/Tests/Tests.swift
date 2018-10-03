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

    func testBoot() {
        let sesame = Sesame.dev()

        let promise = expectation(description: "Did configure on boot")
        sesame.sendBoot { _ in
            sesame.coreDataManager.inNewContext { context in
                XCTAssert(BMSAppState.fetch(context: context, appId: sesame.appId)?.actionIds?.count ?? 0 > 0)
                promise.fulfill()
            }
        }

        waitForExpectations(timeout: 3)
    }

    func testReinforce() {
        let sesame = Sesame.dev()

        let promise = expectation(description: "Did refresh")
        sesame.sendBoot { success in
            XCTAssert(success)
            sesame.sendReinforce(context: sesame.coreDataManager.newContext()) { success in
                XCTAssert(success)
                sesame.coreDataManager.inNewContext { context in
                    guard let userId = sesame.getUserId(context),
                        let cartridges = BMSCartridge.fetch(context: context, userId: userId),
                        !cartridges.isEmpty,
                        cartridges.filter({$0.reinforcements.count == 0}).isEmpty
                        else {
                            fatalError()
                    }
                    promise.fulfill()
                }
            }
        }

        waitForExpectations(timeout: 3)
    }

}

extension BMSAppState {
    var actionIds: [String]? {
        return (effectDetailsAsDictionary?["reinforcedActions"] as? [[String: Any]])?.compactMap({$0["id"] as? String})
    }
}
