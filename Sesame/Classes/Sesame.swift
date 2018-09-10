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
    var contextConfigUser: (NSManagedObjectContext, AppConfig?, User?) {
        let context = coreDataManager.newContext()
        var config: AppConfig?
        var user: User?
        config = coreDataManager.fetchAppConfig(context: context, configId)
        context.performAndWait {
            user = config?.user
        }
        return (context, config, user)
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

    public init(appId: String, appVersionId: String, auth: String, userId: String) {
        self.UIApplicationDelegate = SesameUIApplicationDelegate()
        self.appId = appId
        self.auth = auth
        self.api = APIClient()
        self.coreDataManager = CoreDataManager()

        super.init()

        self.UIApplicationDelegate.app = self

        let context = coreDataManager.newContext()
        let config = coreDataManager.fetchAppConfig(context: context, configId)
        let user = coreDataManager.fetchUser(context: context, for: userId)
        assert(config?.managedObjectContext != nil)
        context.performAndWait {
            config?.user = user
            if config?.versionId == nil {
                config?.versionId = appVersionId
            }
            do {
                try config?.managedObjectContext?.save()
            } catch {
                Logger.debug(error: error.localizedDescription)
            }
            coreDataManager.save()
        }

        sendBoot()
    }

    var eventUploadCount: Int = 5
    var eventUploadPeriod: TimeInterval = 30

    fileprivate var uploadScheduled = false

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

    @objc
    public func setUserId(_ userId: String?) {
        let (context, config, _) = contextConfigUser
        var newUser: User?
        if let userId = userId {
            newUser = coreDataManager.fetchUser(context: context, for: userId)
        }
        context.performAndWait {
            config?.user = newUser
            do {
                try context.save()
            } catch {
                Logger.debug(error: error.localizedDescription)
            }
        }
    }

    @objc func getUserId() -> String? {
        let (context, _, user) = contextConfigUser
        var userId: String?
        context.performAndWait {
            userId = user?.id
        }
        return userId
    }
}

// MARK: - Internal Methods

extension Sesame {

    func receive(appOpenAction: AppOpenAction?) {
        guard let (context, _, user) = contextConfigUser as? (NSManagedObjectContext, AppConfig?, User) else { return }
        var userid: String?
        context.performAndWait {
            userid = user.id
        }
        guard let userId = userid else { return }

        switch appOpenAction?.cueCategory {
        case .internal?,
             .external?:
            let cartridge = coreDataManager.fetchCartridge(context: context, userId: userId, actionName: "appOpen")
            context.performAndWait {
                if let cartridge = cartridge,
                    let reinforcement = cartridge.reinforcements?.firstObject as? Reinforcement,
                    let reinforcementName = reinforcement.name {
                    Logger.debug(confirmed: "Next reinforcement:\(reinforcementName)")
                    _effect = (reinforcementName, [:])
                    context.delete(reinforcement)
                }
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
        guard let (context, _, user) = contextConfigUser as? (NSManagedObjectContext, AppConfig?, User) else { return }
        var userid: String?
        context.performAndWait {
            userid = user.id
        }
        guard let userId = userid else { return }
        coreDataManager.insertEvent(context: context, userId: userId, actionName: actionName, metadata: metadata)
        let eventCount = coreDataManager.countEvents(context: context, userId: userId)

        Logger.debug("Reported #\(eventCount ?? -1) events total")

        if eventCount ?? 0 >= eventUploadCount {
            sendTracks(userId: userId)
        }
    }

    func eventCount() -> Int {
        let context = coreDataManager.newContext()
        return coreDataManager.countEvents(context: context) ?? 0
    }
}

// MARK: - Private Methods

/*private*/ extension Sesame {

    public func sendBoot(completion: @escaping (Bool) -> Void = {_ in}) {
        var payload = api.createPayload(for: self)
        payload["initialBoot"] = false
        payload["inProduction"] = false
        let (context, config, _) = contextConfigUser
        context.performAndWait {
            payload["currentVersion"] = config?.versionId
            payload["currentConfig"] = "\(config?.revision ?? 0)"
        }

        api.post(endpoint: .boot, jsonObject: payload) { response in
            guard let response = response,
                response["errors"] == nil else {
                    completion(false)
                    return
            }
            let (context, config, _) = self.contextConfigUser
            if let configValues = response["config"] as? [String: Any] {
                context.performAndWait {
                    if let configId = configValues["configId"] as? String {
                        config?.configId = configId
                    }
                    if let trackingEnabled = configValues["trackingEnabled"] as? Bool {
                        config?.trackingEnabled = trackingEnabled
                    }
                    if let trackingCapabilities = configValues["trackingCapabilities"] as? [String: Any] {
                        if let applicationState = trackingCapabilities["applicationState"] as? Bool {
                            config?.trackingCapabilities?.applicationState = applicationState
                        }
                    }
                }
            }

            if let version = response["version"] as? [String: Any] {
                if let versionId = version["versionID"] as? String {
                    context.performAndWait {
                        config?.versionId = versionId
                    }
                }
                var userId: String?
                context.performAndWait {
                    userId = config?.user?.id
                }
                if let userId = userId,
                    let mappings = version["mappings"] as? [String: [String: Any]] {
                    for (actionName, effectDetails) in mappings {
                        if let cartridge = self.coreDataManager.fetchCartridge(context: context, userId: userId, actionName: actionName) {
                            context.performAndWait {
                                cartridge.effectDetailsDictionary = effectDetails
                            }
                        } else {
                            self.coreDataManager.insertCartridge(context: context,
                                                                 userId: userId,
                                                                 actionName: actionName,
                                                                 effectDetails: effectDetails)
                        }
                    }
                }
            }
            context.performAndWait {
                do {
                    try context.save()
                    self.coreDataManager.save()
                } catch {
                    Logger.debug(error: error.localizedDescription)
                }
            }
            completion(true)
            }.start()
    }

    func sendTracks(userId: String, completion: @escaping (Bool) -> Void = {_ in}) {
        var payload = api.createPayload(for: self)
        payload["tracks"] = {
            var tracks = [[String: Any]]()
            let context = coreDataManager.newContext()
            if let reports = coreDataManager.fetchReports(context: context, userId: userId) {
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
                coreDataManager.deleteReports(context: context, userId: userId)
            }
            return tracks
        }()

        api.post(endpoint: .track, jsonObject: payload) { response in
            guard let response = response,
                response["errors"] == nil else {
                    completion(false)
                    return
            }
            completion(true)
            }.start()
    }

    func refresh() {
        let (context, _, user) = contextConfigUser
        var userId: String?
        context.performAndWait {
            userId = user?.id
        }
        if let userId = userId,
            let cartridges = coreDataManager.fetchCartridges(context: context, userId: userId) {
            context.performAndWait {
                for cartridge in cartridges {
                    if let actionName = cartridge.actionName,
                        cartridge.reinforcements?.count == 0 {
                        sendRefresh(userId: userId, actionName: actionName)
                    }
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
            let context = self.coreDataManager.newContext()
            self.coreDataManager.updateCartridge(context: context,
                                                 userId: userId,
                                                 actionName: actionName,
                                                 cartridgeId: cartridgeId,
                                                 serverUtc: serverUtc,
                                                 ttl: ttl,
                                                 reinforcements: reinforcements.compactMap({$0["reinforcementName"]}))
            do {
                try context.save()
                self.coreDataManager.save()
            } catch {
                Logger.debug(error: error.localizedDescription)
            }
            completion(true)
            }.start()
    }
}
