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

    public let appId: String
    public let auth: String

    var api: APIClient
    let coreDataManager: CoreDataManager

    public var trackingOptions = BMSTrackingOptions.default
    public var applicationLifecycleTracker: ApplicationLifecycleTracker? = .init()

    @objc var configId: String? {
        get {
            return UserDefaults.sesame.string(forKey: #keyPath(Sesame.configId))
        }
        set {
            UserDefaults.sesame.set(newValue, forKey: #keyPath(Sesame.configId))
        }
    }

    public init(appId: String, appVersionId: String, auth: String, userId: String, manualBoot: Bool = true) {
        self.appId = appId
        self.auth = auth
        self.api = APIClient()
        self.coreDataManager = CoreDataManager()

        super.init()

        let context = coreDataManager.newContext()
        context.performAndWait {
            coreDataManager.fetchAppConfig(context: context, configId)?.versionId = appVersionId
            setUserId(userId, context)
            if !manualBoot {
                sendBoot()
            }
        }

        applicationLifecycleTracker?.sesame = self
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
                Logger.error(error)
            }
        }

        Logger.info("set userId:\(String(describing: userId))")
    }

    @objc func getUserId(_ context: NSManagedObjectContext? = nil) -> String? {
        var userId: String?
        let context = context ?? coreDataManager.newContext()
        context.performAndWait {
            userId = coreDataManager.fetchAppConfig(context: context, configId)?.user?.id
        }
        Logger.verbose("got userId:\(String(describing: userId))")
        return userId
    }
}

// MARK: - Internal Methods

extension Sesame {

    func add(appOpenEvent: AppOpenAction) {
        switch appOpenEvent.cueCategory {
        case .internal,
             .external:
            let context = coreDataManager.newContext()
            context.performAndWait {
                if let userId = coreDataManager.fetchAppConfig(context: context, configId)?.user?.id,
                    let cartridge = coreDataManager.fetchCartridge(context: context,
                                                                   userId: userId,
                                                                   actionName: SesameConstants.AppOpenAction) {
                    let reinforcementName: String
                    if let reinforcement = cartridge.reinforcements?.firstObject as? Reinforcement,
                        let name = reinforcement.name {
                        reinforcementName = name
                        context.delete(reinforcement)
                    } else {
                        reinforcementName = "neutral"
                    }

                    Logger.info(confirmed: "Next reinforcement:\(reinforcementName)")
                    _effect = (reinforcementName, [:])

                    addEvent(context: context,
                             actionName: SesameConstants.AppOpenAction,
                             metadata: appOpenEvent.metadata)
                    sendRefresh(context: context, userId: userId, actionName: SesameConstants.AppOpenAction)
                }
            }
        case .synthetic:
            break
        }
    }

}

// MARK: - For development

public extension Sesame {

    func addEvent(context: NSManagedObjectContext? = nil, actionName: String, metadata: [String: Any] = [:]) {
        let context = context ?? coreDataManager.newContext()
        var metadata = metadata
        context.performAndWait {
            guard let userId = getUserId(context) else { return }
            trackingOptions.annotate(&metadata)
            coreDataManager.insertEvent(context: context,
                                        userId: userId,
                                        actionName: actionName,
                                        metadata: metadata)
            let eventCount = coreDataManager.countEvents(context: context, userId: userId)

            Logger.info("Added event:\(actionName) metadata:\(metadata) for userId:\(userId)")
            Logger.info("Total events for user:#\(eventCount ?? -1)")

//            for report in coreDataManager.fetchReports(context: context, userId: userId) ?? [] {
//                Logger.info("Report:\(report.actionName!) events:\(report.events!.count)")
//            }

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

    //swiftlint:disable:next cyclomatic_complexity function_body_length
    public func sendBoot(completion: @escaping (Bool) -> Void = {_ in}) {
        let context = coreDataManager.newContext()
        context.performAndWait {
            guard let appConfig = coreDataManager.fetchAppConfig(context: context, configId) else { return }
            var payload = api.createPayload(appId: appId,
                                            versionId: appConfig.versionId,
                                            secret: auth,
                                            primaryIdentity: appConfig.user?.id)
            payload["initialBoot"] = false
            payload["inProduction"] = false
            payload["currentVersion"] = appConfig.versionId
            payload["currentConfig"] = "\(appConfig.revision)"

            api.post(endpoint: .boot, jsonObject: payload) { response in
                guard let response = response,
                    response["errors"] == nil else {
                        completion(false)
                        return
                }
                let context = self.coreDataManager.newContext()
                guard let appConfig = self.coreDataManager.fetchAppConfig(context: context, self.configId) else {
                    return
                }
                context.performAndWait {
                    if let configValues = response["config"] as? [String: Any] {
                        if let configId = configValues["configId"] as? String {
                            appConfig.configId = configId
                        }
                        if let trackingEnabled = configValues["trackingEnabled"] as? Bool {
                            appConfig.trackingEnabled = trackingEnabled
                        }
                    }

                    if let version = response["version"] as? [String: Any] {
                        if let versionId = version["versionID"] as? String {
                            appConfig.versionId = versionId
                        }
                        if let userId = appConfig.user?.id,
                            let mappings = version["mappings"] as? [String: [String: Any]] {
                            for (actionName, effectDetails) in mappings {
                                if let cartridge = self.coreDataManager.fetchCartridge(context: context,
                                                                                       userId: userId,
                                                                                       actionName: actionName) {
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
                        if context.hasChanges {
                            try context.save()
                        }
                    } catch {
                        Logger.error(error)
                    }
                }
                completion(true)
                }.start()
        }
    }

    func sendTracks(context: NSManagedObjectContext, userId: String, completion: @escaping (Bool) -> Void = {_ in}) {
        context.performAndWait {
            guard let appConfig = coreDataManager.fetchAppConfig(context: context, configId) else {
                    return
            }
            var payload = api.createPayload(appId: appId,
                                            versionId: appConfig.versionId,
                                            secret: auth,
                                            primaryIdentity: userId)
            payload["tracks"] = {
                var tracks = [[String: Any]]()
                if let reports = appConfig.user?.reports?.allObjects as? [Report] {
                    for report in reports {
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
                do {
                    try context.save()
                } catch {
                    Logger.error(error)
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

    func sendRefresh(context: NSManagedObjectContext? = nil, userId: String, actionName: String, force: Bool = false, completion: @escaping (Bool) -> Void = {_ in}) {
        let context = context ?? coreDataManager.newContext()
        context.performAndWait {
            guard let appConfig = coreDataManager.fetchAppConfig(context: context, configId) else { return }
            guard let reinforcementCount = coreDataManager.fetchCartridge(context: context,
                                                                          userId: userId,
                                                                          actionName: actionName)?
                .reinforcements?.count,
                reinforcementCount == 0
                else { return }
            var payload = api.createPayload(appId: appId,
                                            versionId: appConfig.versionId,
                                            secret: auth,
                                            primaryIdentity: appConfig.user?.id)
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
                let reinforcementNames = reinforcements.compactMap({$0["reinforcementName"]})
                let context = self.coreDataManager.newContext()
                context.performAndWait {
                    self.coreDataManager.updateCartridge(context: context,
                                                         userId: userId,
                                                         actionName: actionName,
                                                         cartridgeId: cartridgeId,
                                                         serverUtc: serverUtc,
                                                         ttl: ttl,
                                                         reinforcements: reinforcementNames)
                    do {
                        try context.save()
                    } catch {
                        Logger.error(error)
                    }
                }
                completion(true)
                }.start()
        }
    }
}
