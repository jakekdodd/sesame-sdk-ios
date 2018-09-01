import XCTest
@testable import Sesame

class Tests: XCTestCase {

    override func setUp() {
        super.setUp()

        CoreDataManager().eraseAll()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testEventsCount() {
        let coreDataManager = CoreDataManager()
        let desiredCount = 5

        let group = DispatchGroup()
        for _ in 1...desiredCount { group.enter() }
        DispatchQueue.concurrentPerform(iterations: desiredCount) { iteration in
//        for iteration in 1...desiredCount {
            switch iteration % 2 {
            case 0:
                coreDataManager.addEvent(for: "appOpen")
            default:
                coreDataManager.addEvent(for: "appClose")
            }
            group.leave()
        }

        XCTAssert(group.wait(timeout: .now() + 2) == .success)

        let count = coreDataManager.eventsCount()
        print("Got count:\(count)")
        XCTAssert(count == desiredCount)

//        var events = [Event]()
//        for case let report in coreDataManager.reports() {
//
//        }
    }

    func testMultipleEvents() {
        let coreDataManager = CoreDataManager()
        let eventCount = { coreDataManager.eventsCount() }
        XCTAssert(eventCount() == 0)

        coreDataManager.addEvent(for: "appOpen")
        XCTAssert(eventCount() == 1)

        coreDataManager.addEvent(for: "appOpen")
        XCTAssert(eventCount() == 2)
    }

    func testMultipleReports() {
        let coreDataManager = CoreDataManager()
        let reportCount = { coreDataManager.reports()?.count }
        XCTAssert(reportCount() == 0)

        coreDataManager.addEvent(for: "appOpen")
        XCTAssert(reportCount() == 1)

        coreDataManager.addEvent(for: "appClose")
        XCTAssert(reportCount() == 2)
    }

    func testErase() {
        let coreDataManager = CoreDataManager()
        let eventCount = { coreDataManager.eventsCount() }
        XCTAssert(eventCount() == 0)
        coreDataManager.addEvent(for: "appOpen")
        coreDataManager.addEvent(for: "appOpen")
        XCTAssert(eventCount() == 2)

        coreDataManager.eraseAll()
        XCTAssert(eventCount() == 0)
        coreDataManager.addEvent(for: "appOpen")
        coreDataManager.addEvent(for: "appOpen")
        XCTAssert(eventCount() == 2)

    }

    func testSomething() {
//        let coredatamanager = CoreDataManager()
        print(Report.self.debugDescription())
    }

}
