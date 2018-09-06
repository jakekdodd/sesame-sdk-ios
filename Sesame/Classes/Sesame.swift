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
    public let auth: String

    let api: APIClient
    var config: AppConfig? {
        return coreDataManager.fetchAppConfig(configId)
    }

    let coreDataManager: CoreDataManager
    @objc var configId: String? {
        get {
            return UserDefaults.sesame.string(forKey: #keyPath(Sesame.configId))
        }
        set {
            UserDefaults.sesame.set(newValue, forKey: #keyPath(Sesame.configId))
        }
    }
//    public var reinforcer: Reinforcer

    public init(appId: String, appVersionId: String, auth: String, userId: String) {
        self.UIApplicationDelegate = SesameUIApplicationDelegate()
        self.appId = appId
        self.auth = auth
        self.api = APIClient()
        self.coreDataManager = CoreDataManager()
//        self.reinforcer = Reinforcer()

        super.init()

        self.UIApplicationDelegate.app = self
        let config = self.config
        config?.user = coreDataManager.fetchUser(for: userId)
        if config?.versionId == nil {
            config?.versionId = appVersionId
        }
        coreDataManager.save()

        sendBoot()
    }

    var eventUploadCount: Int = 5
    var eventUploadPeriod: TimeInterval = 30

    fileprivate var uploadScheduled = false

    var userId: String? {
        get {
            guard let userId = config?.user?.id else {
                Logger.debug(error: "User not set")
                return nil
            }
            return userId
        }
        set {
            config?.user = newValue == nil ? nil : coreDataManager.fetchUser(for: newValue!)
            coreDataManager.save()
        }
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
        guard let userId = userId else { return }

        switch appOpenAction?.cueCategory {
        case .internal?,
             .external?:

            if let cartridge = coreDataManager.fetchCartridge(userId: userId, actionName: "appOpen"),
                let reinforcement = cartridge.reinforcements?.firstObject as? Reinforcement,
                let reinforcementName = reinforcement.name {
                Logger.debug(confirmed: "Next reinforcement:\(reinforcementName)")
                _effect = (reinforcementName, [:])
                coreDataManager.delete(object: reinforcement)
            }

            addEvent(for: "appOpen")
            refresh()

        case .synthetic?:
            break

        case nil:
            break
        }
    }

}

// MARK: - For development

public extension Sesame {
    func addEvent(for actionName: String, metadata: [String: Any] = [:]) {
        guard let userId = userId else { return }

        coreDataManager.insertEvent(userId: userId, actionName: actionName, metadata: metadata)
        let eventCount = coreDataManager.countEvents(userId: userId)

        Logger.debug("Reported #\(eventCount ?? -1) events total")

        if eventCount ?? 0 >= eventUploadCount {
            sendTracks(userId: userId)
        }
    }

    func eventCount() -> Int {
        return coreDataManager.countEvents() ?? 0
    }
}

// MARK: - Private Methods

/*private*/ extension Sesame {

    func sendBoot(completion: @escaping (Bool) -> Void = {_ in}) {
        var payload = api.createPayload(for: self)
        payload["initialBoot"] = false
        payload["inProduction"] = false
        payload["currentVersion"] = config?.versionId
        payload["currentConfig"] = "\(config?.revision ?? 0)"

        api.post(endpoint: .boot, jsonObject: payload) { response in
            guard let response = response,
                response["errors"] == nil else {
                    completion(false)
                    return
            }

            print("before:\(self.config.debugDescription)")
            if let configValues = response["config"] as? [String: Any] {
                if let configId = configValues["configId"] as? String {
                    self.config?.configId = configId
                }
                if let trackingEnabled = configValues["trackingEnabled"] as? Bool {
                    self.config?.trackingEnabled = trackingEnabled
                }
                if let trackingCapabilities = configValues["trackingCapabilities"] as? [String: Any] {
                    if let applicationState = trackingCapabilities["applicationState"] as? Bool {
                        self.config?.trackingCapabilities?.applicationState = applicationState
                    }
                }
            }

            if let version = response["version"] as? [String: Any] {
                if let versionId = version["versionID"] as? String {
                    self.config?.versionId = versionId
                }
                if let mappings = version["mappings"] as? [String: [String: Any]],
                    let userId = self.userId {
                    for (actionName, effectDetails) in mappings {
                        if let cartridge = self.coreDataManager.fetchCartridge(userId: userId, actionName: actionName) {
                            cartridge.effectDetailsDictionary = effectDetails
                        } else {
                            self.coreDataManager.insertCartridge(userId: userId,
                                                                 actionName: actionName,
                                                                 effectDetails: effectDetails)
                        }
                    }
                }
            }

            self.coreDataManager.save()
            completion(true)
            }.start()
    }

    func sendTracks(userId: String, completion: @escaping (Bool) -> Void = {_ in}) {
        var payload = api.createPayload(for: self)
        payload["tracks"] = {
            var tracks = [[String: Any]]()
            if let reports = coreDataManager.fetchReports(userId: userId) {
                for case let report in reports {
                    guard let reportEvents = report.events else { continue }

                    var track = [String: Any]()
                    track["actionName"] = report.actionName
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
            self.coreDataManager.deleteReports(userId: userId)
            guard let response = response,
                response["errors"] == nil else {
                    completion(false)
                    return
            }
            completion(true)
            }.start()
    }

    func refresh() {
        if let userId = userId,
            let cartridges = coreDataManager.fetchCartridges(userId: userId) {
            for cartridge in cartridges {
                if let actionName = cartridge.actionName,
                    cartridge.reinforcements?.count == 0 {
                    sendRefresh(userId: userId, actionName: actionName)
                }
            }
        }
    }

    func sendRefresh(userId: String, actionName: String, completion: @escaping (Bool) -> Void = {_ in}) {
        var payload = api.createPayload(for: self)
        payload["actionName"] = actionName

        api.post(endpoint: .refresh, jsonObject: payload) { response in
            guard let response = response,
                let cartridgeId = response["cartridgeId"] as? String,
                let serverUtc = response["serverUtc"] as? Int64,
                let ttl = response["ttl"] as? Int64,
                let actionName = response["actionName"] as? String,
                let reinforcements = response["reinforcements"] as? [[String: String]] else {
                    completion(false)
                    return
            }

            self.coreDataManager.updateCartridge(userId: userId,
                                                 actionName: actionName,
                                                 cartridgeId: cartridgeId,
                                                 serverUtc: serverUtc,
                                                 ttl: ttl,
                                                 reinforcements: reinforcements.compactMap({$0["reinforcementName"]}))

            completion(true)
            }.start()
    }
}
