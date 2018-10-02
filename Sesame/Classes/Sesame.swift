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

    @objc public var appLifecycleTracker: BMSAppLifecycle
    var trackingOptions: BMSEventMetadataOptions
    let appId: String

    @objc
    public init(appId: String, auth: String, versionId: String?, userId: String) {
        self.api = APIClient()
        self.coreDataManager = CoreDataManager()
        self.trackingOptions = .standard()
        self.appLifecycleTracker = BMSAppLifecycle()
        self.appId = appId

        super.init()

        let context = coreDataManager.newContext()
        context.performAndWait {
            if let appState = BMSAppState.fetch(context: context, appId: appId) ??
                BMSAppState.insert(context: context, appId: appId, auth: auth, versionId: versionId) {
                if appState.auth != auth {
                    // when switching auth keys clear app state and erase users
                    BMSAppState.delete(context: context, appId: appId)
                    BMSUser.delete(context: context)
                    _ = BMSAppState.insert(context: context, appId: appId, auth: auth, versionId: versionId)
                }
            }
            setUserId(context, userId)
        }

        appLifecycleTracker.listener = self
    }

    var eventUploadCount: Int = 20
    var eventUploadPeriod: TimeInterval = 30

    fileprivate var uploadScheduled = false
}

// MARK: - Public Methods

public extension Sesame {

    @objc
    public func setUserId(_ userId: String?) {
        setUserId(coreDataManager.newContext(), userId)
    }

    internal func setUserId( _ context: NSManagedObjectContext, _ userId: String?) {
        context.performAndWait {
            guard let appState = BMSAppState.fetch(context: context, appId: appId) else {
                BMSLog.error("setUserId without an appState")
                return
            }
            if let userId = userId {
                guard let user = BMSUser.fetch(context: context, id: userId) ??
                    BMSUser.insert(context: context, id: userId) else {
                        BMSLog.error("Could not find or insert user")
                        return
                }
                appState.user = user
            } else {
                appState.user = nil
            }
            do {
                try context.save()
                coreDataManager.save()
            } catch {
                BMSLog.error(error)
            }
            BMSLog.info("set userId:\(String(describing: userId))")
        }
    }

    @objc
    public func getUserId() -> String? {
        return getUserId(nil)
    }

    internal func getUserId(_ context: NSManagedObjectContext?) -> String? {
        var userId: String?
        let context = context ?? coreDataManager.newContext()
        context.performAndWait {
            userId = BMSAppState.fetch(context: context, appId: appId)?.user?.id
        }
        BMSLog.verbose("got userId:\(String(describing: userId))")
        return userId
    }

    public func addEvent(context: NSManagedObjectContext? = nil, actionName: String, metadata: [String: Any] = [:], reinforce: Bool = false) {
        var reinforcementName: String?
        let context = context ?? coreDataManager.newContext()
        context.performAndWait {
            guard let appState = BMSAppState.fetch(context: context, appId: appId),
                let user = appState.user
                else { return }
            var metadata = metadata
            trackingOptions.annotate(&metadata)
            metadata[BMSSessionId.TimeElapsedName] = appLifecycleTracker.sessionId?.timeElapsed()
            guard let event = BMSEvent.insert(context: context,
                                              userId: user.id,
                                              actionName: actionName,
                                              sessionId: appLifecycleTracker.sessionId as NSNumber?,
                                              metadata: metadata) else { return }
            if reinforce,
                let reinforcement = BMSCartridge.fetch(context: context,
                                                       userId: user.id,
                                                       actionName: actionName)?.first?
                    .nextReinforcement
                    ?? BMSCartridge.insert(context: context,
                                           userId: user.id,
                                           actionName: actionName,
                                           cartridgeId: BMSCartridge.NeutralCartridgeId)?
                        .nextReinforcement {
                event.reinforcement = reinforcement
                reinforcementName = reinforcement.name
            }

            let eventCount = BMSEvent.count(context: context, userId: user.id)
            BMSLog.info("Added event:\(actionName) metadata:\(metadata) for userId:\(user.id)")
            BMSLog.info("Total events for user:#\(eventCount ?? -1)")
            do {
                try context.save()
                coreDataManager.save()
            } catch {
                BMSLog.error(error)
            }
            if eventCount ?? 0 >= eventUploadCount {
                sendTracks(context: context, userId: user.id)
            }
        }

        if let reinforcementName = reinforcementName {
            BMSLog.info(confirmed: "Reinforcement:\(reinforcementName)")
            _reinforcementEffect = (reinforcementName, [:])
            self.sendRefresh(actionName: actionName)
        }
    }

    @objc
    public func eventCount() -> Int {
        let context = coreDataManager.newContext()
        return BMSEvent.count(context: context) ?? 0
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

// MARK: - App Open Reinforcement

extension Sesame: BMSAppLifecycleListener {

    func appLifecycleSessionDidStart(_ appLifecycle: BMSAppLifecycle, lastSession: BMSSessionId?) {
        addEvent(actionName: BMSSessionId.StartName)
    }

    func appLifecycleSessionAppDidOpen(_ appLifecycle: BMSAppLifecycle, reinforceable: Bool) {
        guard let appOpenAction = appLifecycle.appOpenAction else { return }
        addEvent(actionName: BMSSessionId.AppOpenName)
        addEvent(actionName: BMSEvent.AppOpenName,
                 metadata: appOpenAction.metadata,
                 reinforce: reinforceable)
    }

    func appLifecycleSessionInterrupetionWillStart(_ appLifecycle: BMSAppLifecycle) {
        addEvent(actionName: BMSSessionId.InterruptionStartName)
    }

    func appLifecycleSessionInterrupetionDidEnd(_ appLifecycle: BMSAppLifecycle) {
        addEvent(actionName: BMSSessionId.InterruptionEndName)
    }

    func appLifecycleSessionAppWillClose(_ appLifecycle: BMSAppLifecycle) {
        addEvent(actionName: BMSSessionId.AppCloseName)
    }

    func appLifecycleSessionWillEnd(_ appLifecycle: BMSAppLifecycle) {
        addEvent(actionName: BMSSessionId.EndName)
    }

}

// MARK: - HTTP Methods

extension Sesame {

    public func sendBoot(completion: @escaping (Bool) -> Void = {_ in}) {
        let context = coreDataManager.newContext()
        context.performAndWait {
            guard let appState = BMSAppState.fetch(context: context, appId: appId)
                else { return }
            var payload = api.createPayload(appId: appId,
                                            versionId: appState.versionId,
                                            secret: appState.auth,
                                            primaryIdentity: appState.user?.id)
            payload["initialBoot"] = (UserDefaults.sesame.initialBootDate == nil)
            payload["inProduction"] = false
            payload["currentVersion"] = appState.versionId ?? "nil"
            payload["currentConfig"] = "\(appState.revision)"

            api.post(endpoint: .boot, jsonObject: payload) { response in
                guard let response = response,
                    response["errors"] == nil else {
                        completion(false)
                        return
                }
                let context = self.coreDataManager.newContext()
                context.performAndWait {
                    guard let appState = BMSAppState.fetch(context: context, appId: self.appId) else {
                        return
                    }
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
                        if let mappings = version["mappings"] as? [String: [String: Any]] {
                            appState.effectDetailsAsDictionary = mappings
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
            guard !uploadScheduled else { return }
            uploadScheduled = true
            guard let appState = BMSAppState.fetch(context: context, appId: appId)
                else { return }
            var payload = api.createPayload(appId: appState.appId,
                                            versionId: appState.versionId,
                                            secret: appState.auth,
                                            primaryIdentity: userId)
            payload["tracks"] = {
                var tracks = [[String: Any]]()
                if let reports = appState.user?.reports.allObjects as? [BMSReport] {
                    for report in reports {
                        var track = [String: Any]()
                        track["actionName"] = report.actionName
                        track["type"] = report.type.stringValue
                        var events = [[String: Any]]()
                        for case let reportEvent as BMSEvent in report.events {
                            var event = [String: Any]()
                            event["utc"] = reportEvent.utc
                            event["timezoneOffset"] = reportEvent.timezoneOffset
                            event["metadata"] = reportEvent.metadataAsDictionary
                            events.append(event)
                            context.delete(reportEvent)
                        }
                        track["events"] = events

                        tracks.append(track)
                    }
                    // delete empty cartridges after reinforcements are deleted with events
                    _ = BMSCartridge.fetch(context: context, userId: userId)?
                        .filter({$0.reinforcements.count == 0})
                        .map({context.delete($0)})

                    do {
                        try context.save()
                    } catch {
                        BMSLog.error(error)
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
                self.uploadScheduled = false
            }
        }
    }

    func sendRefresh(context: NSManagedObjectContext? = nil, actionName: String, force: Bool = false, completion: @escaping (Bool) -> Void = {_ in}) {
        let context = context ?? coreDataManager.newContext()
        context.performAndWait {
            guard let appState = BMSAppState.fetch(context: context, appId: appId),
                let userId = appState.user?.id,
                BMSCartridge.fetch(context: context,
                                   userId: userId,
                                   actionName: actionName)?.first?.needsRefresh ?? true
                else { return }

            var payload = api.createPayload(appId: appState.appId,
                                            versionId: appState.versionId,
                                            secret: appState.auth,
                                            primaryIdentity: userId)
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
                    BMSCartridge.insert(context: context,
                                        userId: userId,
                                        actionName: actionName,
                                        cartridgeId: cartridgeId,
                                        utc: serverUtc,
                                        ttl: ttl,
                                        reinforcementNames: reinforcementNames)
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
