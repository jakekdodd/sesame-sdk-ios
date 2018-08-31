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

}
