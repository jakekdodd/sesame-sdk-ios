import XCTest
@testable import Sesame

class Tests: XCTestCase {

    override func setUp() {
        super.setUp()

//        CoreDataManager().deleteObjects()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testMultipleEvents() {
        let coreDataManager = CoreDataManager()
        let eventCount = { coreDataManager.countEvents() }
        XCTAssert(eventCount() == 0)

        coreDataManager.insertEvent(actionId: "appOpen")
        XCTAssert(eventCount() == 1)

        coreDataManager.insertEvent(actionId: "appOpen")
        XCTAssert(eventCount() == 2)
    }

    func testMultipleReports() {
        let coreDataManager = CoreDataManager()
        let reportCount = { coreDataManager.fetchReports()?.count }
        XCTAssert(reportCount() == 0)

        coreDataManager.insertEvent(actionId: "appOpen")
        XCTAssert(reportCount() == 1)

        coreDataManager.insertEvent(actionId: "appClose")
        XCTAssert(reportCount() == 2)
    }

    func testErase() {
        let coreDataManager = CoreDataManager()
        let eventCount = { coreDataManager.countEvents() }
        XCTAssert(eventCount() == 0)
        coreDataManager.insertEvent(actionId: "appOpen")
        coreDataManager.insertEvent(actionId: "appOpen")
        XCTAssert(eventCount() == 2)

        coreDataManager.deleteObjects()
        XCTAssert(eventCount() == 0)
        coreDataManager.insertEvent(actionId: "appOpen")
        coreDataManager.insertEvent(actionId: "appOpen")
        XCTAssert(eventCount() == 2)

    }

    func testEventsCount() {
        let coreDataManager = CoreDataManager()
        let desiredCount = 5

        let group = DispatchGroup()
        for _ in 1...desiredCount { group.enter() }
        DispatchQueue.concurrentPerform(iterations: desiredCount) { iteration in
            switch iteration % 2 {
            case 0:
                coreDataManager.insertEvent(actionId: "appOpen")
            default:
                coreDataManager.insertEvent(actionId: "appClose")
            }
            group.leave()
        }

        XCTAssert(group.wait(timeout: .now() + 2) == .success)

        let count = coreDataManager.countEvents()
        print("Got count:\(String(describing: count))")
        XCTAssert(count == desiredCount)

        //        var events = [Event]()
        //        for case let report in coreDataManager.fetchReports() {
        //
        //        }
    }

    func testMultipleChange() {
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

    func testUserChange() {
        let sesame = Sesame.dev
        sesame.coreDataManager.deleteObjects()

        Logger.debug("sesame.eventCountForUser:\(String(describing: sesame.eventCountForUser))")
        XCTAssert(sesame.eventCountForUser == 0)

        sesame.addEventForUser()
        Logger.debug("sesame.eventCountForUser:\(String(describing: sesame.eventCountForUser))")
        XCTAssert(sesame.eventCountForUser == 1)

        sesame.set(userId: "bob")

        Logger.debug("sesame.eventCountForUser:\(String(describing: sesame.eventCountForUser))")
        XCTAssert(sesame.eventCountForUser == 0)

        sesame.addEventForUser()
        Logger.debug("sesame.eventCountForUser:\(String(describing: sesame.eventCountForUser))")
        XCTAssert(sesame.eventCountForUser == 1)

        sesame.set(userId: nil)

        Logger.debug("sesame.eventCountForUser:\(String(describing: sesame.eventCountForUser))")
        XCTAssert(sesame.eventCountForUser == 1)

        sesame.addEventForUser()
        Logger.debug("sesame.eventCountForUser:\(String(describing: sesame.eventCountForUser))")
        XCTAssert(sesame.eventCountForUser == 2)

    }

    func testSomething() {
//        let coredatamanager = CoreDataManager()
        print(Report.self.debugDescription())
    }

}

extension User {
    func countEvents() -> Int {
        var count = 0
        if let reports = reports {
            for case let report as Report in reports {
                if let events = report.events {
                    count += events.count
                }
            }
        }
        return count
    }
}
