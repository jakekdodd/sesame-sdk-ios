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

    var api: APIClient
    let coreDataManager: CoreDataManager

    @objc var configId: String? {
        get {
            return UserDefaults.sesame.string(forKey: #keyPath(Sesame.configId))
        }
        set {
            UserDefaults.sesame.set(newValue, forKey: #keyPath(Sesame.configId))
        }
    }

    public init(appId: String, appVersionId: String, auth: String, userId: String, manualBoot: Bool = true) {
        self.UIApplicationDelegate = SesameUIApplicationDelegate()
        self.appId = appId
        self.auth = auth
        self.api = APIClient()
        self.coreDataManager = CoreDataManager()

        super.init()

        self.UIApplicationDelegate.app = self
        let context = coreDataManager.newContext()
        context.performAndWait {
            coreDataManager.fetchAppConfig(context: context, configId)?.versionId = appVersionId
            setUserId(userId, context)
            if !manualBoot {
                sendBoot()
            }
        }
    }

    var eventUploadCount: Int = 10
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
    public func setUserId(_ userId: String?, _ context: NSManagedObjectContext? = nil) {
        let context = context ?? coreDataManager.newContext()
        context.performAndWait {
            var newUser: User?
            if let userId = userId {
                newUser = coreDataManager.fetchUser(context: context, id: userId)
            }
            if let appConfig = coreDataManager.fetchAppConfig(context: context, configId) {
                appConfig.user = newUser
            }
            do {
                try context.save()
            } catch {
                Logger.debug(error: error.localizedDescription)
            }
        }
        Logger.debug("set userId:\(String(describing: userId))")

        let newContext = coreDataManager.newContext()
        newContext.performAndWait {
            assert(coreDataManager.fetchAppConfig(context: newContext, configId)?.user?.id == userId)
        }
        assert(getUserId(nil) == userId)
    }

    @objc func getUserId(_ context: NSManagedObjectContext? = nil) -> String? {
        var userId: String?
        let context = context ?? coreDataManager.newContext()
        context.performAndWait {
            userId = coreDataManager.fetchAppConfig(context: context, configId)?.user?.id
        }
        Logger.debug("got userId:\(String(describing: userId))")
        return userId
    }
}

// MARK: - Internal Methods

extension Sesame {

    func receive(appOpenAction: AppOpenAction?) {
        switch appOpenAction?.cueCategory {
        case .internal?,
             .external?:
            let context = coreDataManager.newContext()
            context.performAndWait {
                guard let userId = getUserId(context) else { return }
                let cartridge = coreDataManager.fetchCartridge(context: context, userId: userId, actionName: "appOpen")
                if let cartridge = cartridge,
                    let reinforcement = cartridge.reinforcements?.firstObject as? Reinforcement,
                    let reinforcementName = reinforcement.name {
                    Logger.debug(confirmed: "Next reinforcement:\(reinforcementName)")
                    _effect = (reinforcementName, [:])
                    context.delete(reinforcement)
                }

                addEvent(context: context, actionName: "appOpen")
                refresh()
            }

        case .synthetic?:
            break

        case nil:
            break
        }
    }

}

// MARK: - For development

public extension Sesame {
    func addEvent(context: NSManagedObjectContext? = nil, actionName: String, metadata: [String: Any] = [:]) {
        let context = context ?? coreDataManager.newContext()
        context.performAndWait {
            guard let userId = getUserId(context) else { return }
            coreDataManager.insertEvent(context: context, userId: userId, actionName: actionName, metadata: metadata)
            let eventCount = coreDataManager.countEvents(context: context, userId: userId)

            Logger.debug("Reported #\(eventCount ?? -1) events total for userId:\(userId)")

            if eventCount ?? 0 >= eventUploadCount {
                sendTracks(context: context, userId: userId)
            }
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
        let context = coreDataManager.newContext()
        context.performAndWait {
            guard let appConfig = coreDataManager.fetchAppConfig(context: context, configId) else { return }
            var payload = api.createPayload(appId: appId, versionId: appConfig.versionId, secret: auth, primaryIdentity: appConfig.user?.id)
            payload["initialBoot"] = false
            payload["inProduction"] = false
            payload["currentVersion"] = appConfig.versionId
            payload["currentConfig"] = "0"// "\(config?.revision ?? 0)"

            api.post(endpoint: .boot, jsonObject: payload) { response in
                guard let response = response,
                    response["errors"] == nil else {
                        completion(false)
                        return
                }
                let context = self.coreDataManager.newContext()
                guard let appConfig = self.coreDataManager.fetchAppConfig(context: context, self.configId) else { return }
                context.performAndWait {
                    if let configValues = response["config"] as? [String: Any] {
                        if let configId = configValues["configId"] as? String {
                            appConfig.configId = configId
                        }
                        if let trackingEnabled = configValues["trackingEnabled"] as? Bool {
                            appConfig.trackingEnabled = trackingEnabled
                        }
                        if let trackingCapabilities = configValues["trackingCapabilities"] as? [String: Any] {
                            if let applicationState = trackingCapabilities["applicationState"] as? Bool {
                                appConfig.trackingCapabilities?.applicationState = applicationState
                            }
                        }
                    }

                    if let version = response["version"] as? [String: Any] {
                        if let versionId = version["versionID"] as? String {
                            appConfig.versionId = versionId
                        }
                        if let userId = appConfig.user?.id,
                            let mappings = version["mappings"] as? [String: [String: Any]] {
                            for (actionName, effectDetails) in mappings {
                                if let cartridge = self.coreDataManager.fetchCartridge(context: context, userId: userId, actionName: actionName) {
                                    cartridge.effectDetailsDictionary = effectDetails
                                } else {
                                    self.coreDataManager.insertCartridge(context: context,
                                                                         userId: userId,
                                                                         actionName: actionName,
                                                                         effectDetails: effectDetails)
                                }
                            }
                        }
                    }
                    do {
                        try context.save()
                    } catch {
                        Logger.debug(error: error.localizedDescription)
                    }
                }
                completion(true)
                }.start()
        }
    }

    func sendTracks(context: NSManagedObjectContext, userId: String, completion: @escaping (Bool) -> Void = {_ in}) {
        context.performAndWait {
            guard let appConfig = coreDataManager.fetchAppConfig(context: context, configId) else { return }
            var payload = api.createPayload(appId: appId, versionId: appConfig.versionId, secret: auth, primaryIdentity: appConfig.user?.id)
            payload["tracks"] = {
                var tracks = [[String: Any]]()
                if let reports = appConfig.user?.reports?.allObjects as? [Report] {
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
                        context.delete(report)
                    }
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
    }

    func refresh(context: NSManagedObjectContext? = nil) {
        let context = context ?? coreDataManager.newContext()
        context.performAndWait {
            if let userId = getUserId(context),
                let cartridges = coreDataManager.fetchCartridges(context: context, userId: userId) {
                for cartridge in cartridges {
                    if let actionName = cartridge.actionName,
                        cartridge.reinforcements?.count == 0 {
                        sendRefresh(userId: userId, actionName: actionName)
                    }
                }
            }
        }
    }

    func sendRefresh(context: NSManagedObjectContext? = nil, userId: String, actionName: String, completion: @escaping (Bool) -> Void = {_ in}) {
        let context = context ?? coreDataManager.newContext()
        context.performAndWait {
            guard let appConfig = coreDataManager.fetchAppConfig(context: context, configId) else { return }
            var payload = api.createPayload(appId: appId, versionId: appConfig.versionId, secret: auth, primaryIdentity: appConfig.user?.id)
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
                context.performAndWait {
                    self.coreDataManager.updateCartridge(context: context,
                                                         userId: userId,
                                                         actionName: actionName,
                                                         cartridgeId: cartridgeId,
                                                         serverUtc: serverUtc,
                                                         ttl: ttl,
                                                         reinforcements: reinforcements.compactMap({$0["reinforcementName"]}))
                    do {
                        try context.save()
                    } catch {
                        Logger.debug(error: error.localizedDescription)
                    }
                }
                completion(true)
                }.start()
        }
    }
}
