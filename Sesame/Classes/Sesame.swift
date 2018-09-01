//
//  Sesame.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation
import CoreData

public protocol SesameEffectDelegate: class {

    /// Override this method to receive reinforcements!
    /// Set this object as the delegate of the Sesame object from your AppDelegate
    ///
    /// - Parameters:
    ///   - app: The Sesame app
    ///   - reinforcement: A string representing the reinforcement effect configured on the web dashboard
    ///   - options: A dictionary with any additional options configured on the web dashboard
    func app(_ app: Sesame, didReceiveReinforcement reinforcement: String, withOptions options: [String: Any]?)
}

public class Sesame: NSObject {

    public fileprivate(set) static var shared: Sesame?

    public var effectDelegate: SesameEffectDelegate? {
        didSet {
            _effect = {_effect}()
        }
    }

    /// If the delegate isn't set when an effect is supposed to show, the effect is stored until the delegate is set
    fileprivate var _effect: (String, [String: Any])? {
        didSet {
            if let effect = _effect,
                let effectDelegate = effectDelegate {
                effectDelegate.app(self, didReceiveReinforcement: effect.0, withOptions: effect.1)
                _effect = nil
            }
        }
    }

    //swiftlint:disable:next weak_delegate
    public let UIApplicationDelegate: SesameUIApplicationDelegate

    public let appId: String
    public let appVersionId: String
    public let auth: String

    let api: APIClient
    var config: AppConfig?

    let coreDataManager: CoreDataManager
    public var reinforcer: Reinforcer

    public init(appId: String, appVersionId: String, auth: String, userId: String? = nil) {
        self.UIApplicationDelegate = SesameUIApplicationDelegate()
        self.appId = appId
        self.appVersionId = appVersionId
        self.auth = auth
        self.api = APIClient()
        self.coreDataManager = CoreDataManager()
        self.reinforcer = Reinforcer()

        super.init()

        self.UIApplicationDelegate.app = self
        self.config = coreDataManager.fetchAppConfig()
        self.config?.user = coreDataManager.fetchUser(for: userId)
    }

    var eventUploadCount: Int = 5
    var eventUploadPeriod: TimeInterval = 30

    fileprivate var uploadScheduled = false

    func set(userId: String?) {
        config?.user = coreDataManager.fetchUser(for: userId)
    }

}

// MARK: - Public Methods

public extension Sesame {

    @objc
    public class func setShared(_ sesame: Sesame) {
        shared = sesame
    }

    @objc
    public class var UIApplicationDelegate: SesameUIApplicationDelegate? {
        return shared?.UIApplicationDelegate
    }
}

// MARK: - Internal Methods

extension Sesame {

    func receive(appOpenAction: AppOpenAction?) {
        switch appOpenAction?.cueCategory {
        case .internal?,
             .external?:

            let reinforcement = reinforcer.cartridge.removeDecision()
            Logger.debug(confirmed: "Next reinforcement:\(reinforcement)")
            _effect = (reinforcement, [:])

            addEvent(for: "appOpen")
//            sendBoot()

        case .synthetic?:
            break

        case nil:
            break
        }
    }

}

// MARK: - For development

public extension Sesame {
    public func testEvent(_ actionId: String) {
        addEvent(for: actionId, metadata: ["key": "otherValue"])
    }
}

// MARK: - Private Methods

private extension Sesame {

    func addEvent(for actionId: String, metadata: [String: Any] = [:]) {
        coreDataManager.insertEvent(userId: config?.user?.id, actionId: actionId, metadata: metadata)
        let eventCount = coreDataManager.countEvents()

        Logger.debug("Reported #\(eventCount ?? -1) events total")

        if eventCount ?? 0 >= eventUploadCount {
            sendTracks()
        }
    }

    func sendBoot(completion: @escaping (Bool) -> Void = {_ in}) {
        var payload = api.createPayload(for: self)
        payload["initialBoot"] = false
        payload["inProduction"] = false
        payload["currentVersion"] = appVersionId
        payload["currentConfig"] = "\(config?.revision ?? 0)"

        api.post(endpoint: .boot, jsonObject: payload) { response in
            guard let response = response,
                response["errors"] == nil else {
                    completion(false)
                    return
            }

            print("before:\(self.config.debugDescription)")
            if /*let revision = response["revision"] as? Int64,*/
                let configValues = response["config"] as? [String: Any] {
//                self.config?.revision = revision
                if let trackingEnabled = configValues["trackingEnabled"] as? Bool {
                    self.config?.trackingEnabled = trackingEnabled
                }
                if let trackingCapabilities = configValues["trackingCapabilities"] as? [String: Any] {
                    if let applicationState = trackingCapabilities["applicationState"] as? Bool {
                        self.config?.trackingCapabilities?.applicationState = applicationState
                    }
                }

////                config = AppConfig(revision, configValues)
//                if let context = self.config?.managedObjectContext {
//                    self.coreDataManager.save()
//                }
////                self.coreDataManager.save()
//                print("after:\(self.config.debugDescription)")
            }
            }.start()
    }

    func sendTracks(completion: @escaping (Bool) -> Void = {_ in}) {
        var payload = api.createPayload(for: self)
        payload["versionId"] = appVersionId
        payload["tracks"] = {
            var tracks = [[String: Any]]()
            if let reports = coreDataManager.fetchReports() {
                for case let report in reports {
                    guard let reportEvents = report.events else { continue }

                    var track = [String: Any]()
                    track["actionName"] = report.actionId
                    track["type"] = "NON_REINFORCEABLE"
                    var events = [[String: Any]]()
                    for case let reportEvent as Event in reportEvents {
                        var event = [String: Any]()
                        event["utc"] = reportEvent.utc
                        event["timezoneOffset"] = reportEvent.timezoneOffset
                        event["metadata"] = reportEvent.metadata?.jsonDecoded()
                        events.append(event)
                    }
                    track["events"] = events

                    tracks.append(track)
                }
            }
            return tracks
        }()

        api.post(endpoint: .track, jsonObject: payload) { response in
            self.coreDataManager.deleteReports()
            guard let response = response,
                response["errors"] == nil else {
                    completion(false)
                    return
            }
            completion(true)
            }.start()
    }
}
