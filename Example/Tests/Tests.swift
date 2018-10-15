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
        let sesame = MockSesame()
        let addEvent = { sesame.addEvent(actionName: Mock.ename1) }
        let countEvents = { return BMSEvent.count(context: sesame.coreDataManager.newContext(), userId: Mock.uid1) }
        XCTAssert(countEvents() == 0)

        addEvent()
        XCTAssert(countEvents() == 1)

        addEvent()
        XCTAssert(countEvents() == 2)
    }

    func testMultipleReports() {
        let sesame = MockSesame()
        let countReports = { BMSEventReport.fetch(context: sesame.coreDataManager.newContext(), userId: Mock.uid1)?.count }
        XCTAssert(countReports() == 0)

        sesame.addEvent(actionName: Mock.ename1)
        XCTAssert(countReports() == 1)

        sesame.addEvent(actionName: "appClose")
        XCTAssert(countReports() == 2)
    }

    func testConcurrentEventsCount() {
        let sesame = MockSesame()
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

    //swiftlint:disable:next function_body_length
    func testUserChange() {
        let sesame = MockSesame()
        let user1 = "ann"
        let user2 = "bob"
        var currentUser = user1
        let setUser1 = { currentUser = user1; sesame.setUserId(currentUser) }
        let setUser2 = { currentUser = user2; sesame.setUserId(currentUser) }
        let addEvent = { sesame.addEvent(actionName: BMSEvent.AppOpenName) }
        let countEvents = {
            return BMSEvent.count(context: sesame.coreDataManager.newContext(),
                                                  userId: currentUser) ?? -1
        }
        let deleteEvents = {
            _ = sesame.coreDataManager.newContext { context in
                _ = (BMSEventReport.fetch(context: context, userId: currentUser, actionName: BMSEvent.AppOpenName)?
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
        let sesame = MockSesame()

        let promise = expectation(description: "Did configure on boot")
        sesame.sendBoot { _ in
            sesame.coreDataManager.newContext { context in
                XCTAssert(BMSAppState.fetch(context: context, appId: sesame.appId)?.actionIds?.count ?? 0 > 0)
                promise.fulfill()
            }
        }

        waitForExpectations(timeout: 3)
    }

    func testReinforce() {
        let sesame = MockSesame()

        let promise = expectation(description: "Did refresh")
        sesame.sendBoot { success in
            XCTAssert(success)
            sesame.sendReinforce(context: sesame.coreDataManager.newContext()) { success in
                XCTAssert(success)
                sesame.coreDataManager.newContext { context in
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

    class ReinforcementDelegate: NSObject, SesameReinforcementDelegate {
        var didGetView: (() -> Void) = { }
        func reinforce(sesame: Sesame, effectViewController: BMSEffectViewController) {
            didGetView()
        }
    }

    func testReinforceDelegate() {
        let sesame = MockSesame()
        let delegate = ReinforcementDelegate()
        sesame.reinforcementDelegate = delegate

        let promise = expectation(description: "Did get reinforcement")
        delegate.didGetView = {
            promise.fulfill()
        }
        sesame.sendBoot { success in
            XCTAssert(success)
            sesame.sendReinforce(context: sesame.coreDataManager.newContext()) { success in
                XCTAssert(success)
                sesame.addEvent(actionName: Mock.aname1, reinforce: true)
            }
        }

        waitForExpectations(timeout: 3)
    }

}
