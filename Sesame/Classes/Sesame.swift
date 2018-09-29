//
//  Sesame.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import UIKit
import CoreData

@objc
public protocol SesameReinforcementDelegate: class {

    /// Override this method to receive reinforcements!
    /// Set this object as the delegate of the Sesame object from your AppDelegate
    ///
    /// - Parameters:
    ///   - app: The Sesame app
    ///   - reinforcement: A string representing the reinforcement effect configured on the web dashboard
    ///   - options: A dictionary with any additional options configured on the web dashboard
    func reinforce(sesame: Sesame, effectViewController: BMSEffectViewController)
}

@objc
public class Sesame: NSObject {

    @objc public static var shared: Sesame?

    /// If the delegate is not set, the reinforcement effect will affect the whole screen
    @objc public weak var reinforcementDelegate: SesameReinforcementDelegate?

    /// The effect is shown using the custom reinforcementDelegate or the top UIWindow
    fileprivate var _reinforcementEffect: ReinforcementEffect? {
        didSet {
            if let reinforcementEffect = _reinforcementEffect {
                DispatchQueue.main.async {
                    guard let delegate = self.reinforcementDelegate
                        ?? UIWindow.topWindow?.rootViewController
                        else { return }
                    let effectViewController = BMSEffectViewController()
                    effectViewController.reinforcement = reinforcementEffect
                    delegate.reinforce(sesame: self, effectViewController: effectViewController)
                }
                _reinforcementEffect = nil
            }
        }
    }

    var api: APIClient
    let coreDataManager: CoreDataManager

    var trackingOptions: BMSEventMetadataOptions
    var sessionId: BMSSessionId? {
        willSet {
            if sessionId != nil {
                addEvent(actionName: BMSEvent.SessionEndName)
            }
        }
        didSet {
            if sessionId != nil {
                addEvent(actionName: BMSEvent.SessionStartName)
            }
        }
    }

    @objc public var appLifecycleTracker: BMSAppLifecycleTracker

    @objc var configId: String? {
        get {
            return UserDefaults.sesame.string(forKey: #keyPath(Sesame.configId))
        }
        set {
            UserDefaults.sesame.set(newValue, forKey: #keyPath(Sesame.configId))
        }
    }

    @objc
    public convenience init(appId: String, appVersionId: String, auth: String, userId: String) {
        self.init(appId: appId, appVersionId: appVersionId, auth: auth, userId: userId, manualBoot: false)
    }

    @objc
    public init(appId: String, appVersionId: String, auth: String, userId: String, manualBoot: Bool) {
        self.api = APIClient()
        self.coreDataManager = CoreDataManager()
        self.trackingOptions = .standard()
        self.appLifecycleTracker = BMSAppLifecycleTracker()

        super.init()

        let context = coreDataManager.newContext()
        context.performAndWait {
            let appState = BMSAppState.fetch(context: context, configId: configId, appId: appId, auth: auth)
            appState?.versionId = appVersionId
            setUserId(context, userId)
            if !manualBoot {
                sendBoot()
            }
        }

        appLifecycleTracker.sesame = self
        appLifecycleTracker.isRegisteredForNotification = true
    }

    var eventUploadCount: Int = 10
    var eventUploadPeriod: TimeInterval = 30

    fileprivate var uploadScheduled = false

    // let text = UIApplication.shared
}

// MARK: - Public Methods

public extension Sesame {

    @objc
    public func setUserId(_ userId: String?) {
        setUserId(nil, userId)
    }

    internal func setUserId( _ context: NSManagedObjectContext?, _ userId: String?) {
        let context = context ?? coreDataManager.newContext()
        context.performAndWait {
            var newUser: BMSUser?
            if let userId = userId {
                newUser = BMSUser.fetch(context: context, id: userId)
            }
//            var oldUserId: String?
            if let appState = BMSAppState.fetch(context: context, configId: configId) {
//                oldUserId = appState.user?.id
                appState.user = newUser
            }

            do {
                try context.save()
                coreDataManager.save()
            } catch {
                BMSLog.error(error)
            }
        }

        BMSLog.info("set userId:\(String(describing: userId))")
        coreDataManager.save()
    }

    @objc
    public func getUserId() -> String? {
        return getUserId(nil)
    }

    internal func getUserId(_ context: NSManagedObjectContext?) -> String? {
        var userId: String?
        let context = context ?? coreDataManager.newContext()
        context.performAndWait {
            userId = BMSAppState.fetch(context: context, configId: configId)?.user?.id
        }
        BMSLog.verbose("got userId:\(String(describing: userId))")
        return userId
    }

    @objc
    public func addEvent(actionName: String) {
        addEvent(context: nil, actionName: actionName, metadata: [:])
    }

    @objc
    public func addEvent(actionName: String, metadata: [String: Any]) {
        addEvent(context: nil, actionName: actionName, metadata: metadata)
    }

    internal func addEvent(context: NSManagedObjectContext?, actionName: String, metadata: [String: Any]) {
        let context = context ?? coreDataManager.newContext()
        var metadata = metadata
        context.performAndWait {
            guard let userId = getUserId(context) else { return }
            trackingOptions.annotate(&metadata)
            metadata["sessionTimeElapsed"] = sessionId?.elapsedTime()
            BMSEvent.insert(context: context,
                            userId: userId,
                            actionName: actionName,
                            sessionId: sessionId as NSNumber?,
                            metadata: metadata)
            let eventCount = BMSEvent.count(context: context, userId: userId)

            BMSLog.info("Added event:\(actionName) metadata:\(metadata) for userId:\(userId)")
            BMSLog.info("Total events for user:#\(eventCount ?? -1)")

//            for report in coreDataManager.fetchReports(context: context, userId: userId) ?? [] {
//                BMSLog.info("Report:\(report.actionName!) events:\(report.events!.count)")
//            }
            coreDataManager.save()
            if eventCount ?? 0 >= eventUploadCount {
                sendTracks(context: context, userId: userId)
            }
        }
    }

    @objc
    public func eventCount() -> Int {
        let context = coreDataManager.newContext()
        return BMSEvent.count(context: context) ?? 0
    }

    internal func reinforce(appOpenEvent: BMSEventAppOpen) {
        switch appOpenEvent.cueCategory {
        case .internal,
             .external:
            let context = coreDataManager.newContext()
            context.performAndWait {
                if let userId = BMSAppState.fetch(context: context, configId: configId)?.user?.id,
                    let cartridge = BMSCartridge.fetch(context: context,
                                                       userId: userId,
                                                       actionName: appOpenEvent.name) {
                    let reinforcementName: String
                    if let reinforcement = cartridge.reinforcements.firstObject as? BMSReinforcement {
                        reinforcementName = reinforcement.name
                        context.delete(reinforcement)
                    } else {
                        reinforcementName = BMSReinforcement.NeutralName
                        BMSLog.warning("Cartridge is empty. Delivering default reinforcement.")
                    }

                    BMSLog.info(confirmed: "Next reinforcement:\(reinforcementName)")
                    _reinforcementEffect = (reinforcementName, [:])

                    addEvent(context: context, actionName: appOpenEvent.name, metadata: appOpenEvent.metadata)
                    sendRefresh(context: context, userId: userId, actionName: appOpenEvent.name)
                }
            }
        case .synthetic:
            break
        }
    }

    @objc
    public func tracking(option: BMSEventMetadataOption, disabled: Bool) {
        tracking(option: option, enabled: !disabled)
    }

    @objc
    public func tracking(option: BMSEventMetadataOption, enabled: Bool) {
        enabled ? trackingOptions.enable(option) : trackingOptions.disable(option)
    }
}

// MARK: - HTTP Methods

/*private*/ extension Sesame {

    //swiftlint:disable:next cyclomatic_complexity function_body_length
    public func sendBoot(completion: @escaping (Bool) -> Void = {_ in}) {
        let context = coreDataManager.newContext()
        context.performAndWait {
            guard let appState = BMSAppState.fetch(context: context, configId: configId),
            let appId = appState.appId,
            let auth = appState.auth
                else { return }
            var payload = api.createPayload(appId: appId,
                                            versionId: appState.versionId,
                                            secret: auth,
                                            primaryIdentity: appState.user?.id)
            payload["initialBoot"] = false
            payload["inProduction"] = false
            payload["currentVersion"] = appState.versionId
            payload["currentConfig"] = "\(appState.revision)"

            api.post(endpoint: .boot, jsonObject: payload) { response in
                guard let response = response,
                    response["errors"] == nil else {
                        completion(false)
                        return
                }
                let context = self.coreDataManager.newContext()
                guard let appState = BMSAppState.fetch(context: context, configId: self.configId) else {
                    return
                }
                context.performAndWait {
                    if let configValues = response["config"] as? [String: Any] {
                        if let configId = configValues["configId"] as? String {
                            appState.configId = configId
                        }
                        if let trackingEnabled = configValues["trackingEnabled"] as? Bool {
                            appState.trackingEnabled = trackingEnabled
                        }
                    }

                    if let version = response["version"] as? [String: Any] {
                        if let versionId = version["versionID"] as? String {
                            appState.versionId = versionId
                        }
                        if let userId = appState.user?.id,
                            let mappings = version["mappings"] as? [String: [String: Any]] {
                            for (actionName, effectDetails) in mappings {
                                if let cartridge = BMSCartridge.fetch(context: context,
                                                                      userId: userId,
                                                                      actionName: actionName) {
                                    cartridge.effectDetailsAsDictionary = effectDetails
                                } else {
                                    BMSCartridge.insert(context: context,
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
                            self.coreDataManager.save()
                        }
                    } catch {
                        BMSLog.error(error)
                    }
                }
                completion(true)
            }
        }
    }

    func sendTracks(context: NSManagedObjectContext, userId: String, completion: @escaping (Bool) -> Void = {_ in}) {
        context.performAndWait {
            guard let appState = BMSAppState.fetch(context: context, configId: configId),
                let appId = appState.appId,
                let auth = appState.auth
                else { return }
            var payload = api.createPayload(appId: appId,
                                            versionId: appState.versionId,
                                            secret: auth,
                                            primaryIdentity: userId)
            payload["tracks"] = {
                var tracks = [[String: Any]]()
                if let reports = appState.user?.reports.allObjects as? [BMSReport] {
                    for report in reports {
                        var track = [String: Any]()
                        track["actionName"] = report.actionName
                        track["type"] = BMSReport.NonReinforceableType
                        var events = [[String: Any]]()
                        for case let reportEvent as BMSEvent in report.events {
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
                    BMSLog.error(error)
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
            }
        }
    }

    func sendRefresh(context: NSManagedObjectContext? = nil, userId: String, actionName: String, force: Bool = false, completion: @escaping (Bool) -> Void = {_ in}) {
        let context = context ?? coreDataManager.newContext()
        context.performAndWait {
            guard let appState = BMSAppState.fetch(context: context, configId: configId),
                let appId = appState.appId,
                let auth = appState.auth
                else { return }
            guard let reinforcementCount = BMSCartridge.fetch(context: context,
                                                              userId: userId,
                                                              actionName: actionName)?
                .reinforcements.count,
                reinforcementCount == 0
                else { return }
            var payload = api.createPayload(appId: appId,
                                            versionId: appState.versionId,
                                            secret: auth,
                                            primaryIdentity: appState.user?.id)
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
                context.performAndWait {
                    BMSCartridge.update(context: context,
                                        userId: userId,
                                        actionName: actionName,
                                        cartridgeId: cartridgeId,
                                        serverUtc: serverUtc,
                                        ttl: ttl,
                                        reinforcements: reinforcementNames)
                    do {
                        try context.save()
                        self.coreDataManager.save()
                    } catch {
                        BMSLog.error(error)
                    }
                }
                completion(true)
            }
        }
    }
}
