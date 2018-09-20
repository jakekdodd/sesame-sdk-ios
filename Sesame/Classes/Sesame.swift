//
//  Sesame.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation
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
    func app(_ app: Sesame, didReceiveReinforcement reinforcement: String, withOptions options: [String: Any]?)
}

@objc
public class Sesame: NSObject {

    @objc public static var shared: Sesame?

    @objc public weak var reinforcementDelegate: SesameReinforcementDelegate? {
        didSet {
            _reinforcementEffect = {_reinforcementEffect}()
        }
    }

    /// If the delegate isn't set when an effect is supposed to show, the effect is stored until the delegate is set
    fileprivate var _reinforcementEffect: (String, [String: Any])? {
        didSet {
            if let reinforcementEffect = _reinforcementEffect,
                let delegate = reinforcementDelegate {
                delegate.app(self, didReceiveReinforcement: reinforcementEffect.0, withOptions: reinforcementEffect.1)
                _reinforcementEffect = nil
            }
        }
    }

    @objc public let appId: String
    @objc public let auth: String

    var api: APIClient
    let coreDataManager: CoreDataManager

    var trackingOptions = BMSEventMetadataOptions.standard()

    @objc public var appLifecycleTracker: BMSAppLifecycleTracker? = .init()

    @objc var configId: String? {
        get {
            return UserDefaults.sesame.string(forKey: #keyPath(Sesame.configId))
        }
        set {
            UserDefaults.sesame.set(newValue, forKey: #keyPath(Sesame.configId))
        }
    }

    @objc
    public init(appId: String, appVersionId: String, auth: String, userId: String, manualBoot: Bool) {
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

        appLifecycleTracker?.sesame = self
    }

    var eventUploadCount: Int = 10
    var eventUploadPeriod: TimeInterval = 30

    fileprivate var uploadScheduled = false

}

// MARK: - Public Methods

public extension Sesame {

    @objc
    public func setUserId(_ userId: String?) {
        setUserId(userId, nil)
    }

    internal func setUserId(_ userId: String?, _ context: NSManagedObjectContext?) {
        let context = context ?? coreDataManager.newContext()
        context.performAndWait {
            var newUser: BMSUser?
            if let userId = userId {
                newUser = coreDataManager.fetchUser(context: context, id: userId)
            }
            if let appConfig = coreDataManager.fetchAppConfig(context: context, configId) {
                appConfig.user = newUser
            }
            do {
                try context.save()
            } catch {
                BMSLog.error(error)
            }
        }

        BMSLog.info("set userId:\(String(describing: userId))")
    }

    @objc
    public func getUserId() -> String? {
        return getUserId(nil)
    }

    internal func getUserId(_ context: NSManagedObjectContext?) -> String? {
        var userId: String?
        let context = context ?? coreDataManager.newContext()
        context.performAndWait {
            userId = coreDataManager.fetchAppConfig(context: context, configId)?.user?.id
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
            coreDataManager.insertEvent(context: context,
                                        userId: userId,
                                        actionName: actionName,
                                        metadata: metadata)
            let eventCount = coreDataManager.countEvents(context: context, userId: userId)

            BMSLog.info("Added event:\(actionName) metadata:\(metadata) for userId:\(userId)")
            BMSLog.info("Total events for user:#\(eventCount ?? -1)")

//            for report in coreDataManager.fetchReports(context: context, userId: userId) ?? [] {
//                BMSLog.info("Report:\(report.actionName!) events:\(report.events!.count)")
//            }

            if eventCount ?? 0 >= eventUploadCount {
                sendTracks(context: context, userId: userId)
            }
        }
    }

    @objc
    public func eventCount() -> Int {
        let context = coreDataManager.newContext()
        return coreDataManager.countEvents(context: context) ?? 0
    }

    internal func reinforce(appOpenEvent: BMSEventAppOpen) {
        switch appOpenEvent.cueCategory {
        case .internal,
             .external:
            let context = coreDataManager.newContext()
            context.performAndWait {
                if let userId = coreDataManager.fetchAppConfig(context: context, configId)?.user?.id,
                    let cartridge = coreDataManager.fetchCartridge(context: context,
                                                                   userId: userId,
                                                                   actionName: appOpenEvent.name) {
                    let reinforcementName: String
                    if let reinforcement = cartridge.reinforcements?.firstObject as? BMSReinforcement,
                        let name = reinforcement.name {
                        reinforcementName = name
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
                                    cartridge.effectDetailsAsDictionary = effectDetails
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
                        BMSLog.error(error)
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
                if let reports = appConfig.user?.reports?.allObjects as? [BMSReport] {
                    for report in reports {
                        guard let reportEvents = report.events else { continue }
                        var track = [String: Any]()
                        track["actionName"] = report.actionName
                        track["type"] = BMSReport.NonReinforceableType
                        var events = [[String: Any]]()
                        for case let reportEvent as BMSEvent in reportEvents {
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
                        BMSLog.error(error)
                    }
                }
                completion(true)
                }.start()
        }
    }
}
