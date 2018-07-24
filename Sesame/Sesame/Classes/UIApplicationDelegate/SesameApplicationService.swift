//
//  SesameApplicationService.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation

/* Extend this class to seamlessly plug-in Sesame to your product.
 *
 * Copy and paste your credentials as a swift dictionary.
 * Reinforcements will invoke func application(_:didReceiveReinforcement:withOptions:)
 *
 */
open class SesameApplicationDelegate: PluggableApplicationDelegate, SesameApplicationServiceDelegate {
    
    open var SesameCredentials: [String: Any] {
        get { fatalError("Need to override `SesameCredentials` in SesameApplicationDelegate with your credentials") }
    }
    
    open override var services: [ApplicationService] {
        var services = super.services
        if let sesameService = SesameApplicationService(args: SesameCredentials, delegate: self) {
            services.append(sesameService)
        }
        return services
    }
    
    /// MARK: SesameApplicationServiceDelegate
    public func application(_ application: SesameAppVersion, didReceiveReinforcement reinforcement: String, withOptions options: [String : Any]?) {
        Logger.debug(confirmed: "Received reinforcement:\(reinforcement) with options:\(options as AnyObject)")
        Logger.debug(error: "This method should be overriden.")
    }
    
}




public protocol SesameApplicationServiceDelegate : class {
    func application(_ application: SesameAppVersion, didReceiveReinforcement reinforcement: String, withOptions options: [String: Any]?)
}

final public class SesameApplicationService : NSObject, ApplicationService {
    
    public var app: SesameAppVersion
    public weak var delegate: SesameApplicationServiceDelegate?
    
    
    var lastOpened: Date? = nil
    var appState: SesameAppState = .closed {
        didSet {
            guard appState != .closed else { return }
            
            if oldValue == .opened,
                appState == .opened,
                let lastOpened = lastOpened,
                lastOpened.timeIntervalSince(Date()) > 0.5
            {
                appState = .reopened
                self.lastOpened = Date()
            }
            
            if oldValue == .closed,
                appState == .opened {
                self.lastOpened = Date()
                // TO-DO: call api for reinforcement, deliver reinforcement to delegate
                let reinforcement = app.reinforcer.cartridge.removeDecision()
                print("Removed decision reinforcement:\(reinforcement)")
                delegate?.application(app, didReceiveReinforcement: reinforcement, withOptions: app.reinforcer.options?[reinforcement])
            }
        }
    }
    
    public convenience init?(args: [String: Any], delegate: SesameApplicationServiceDelegate? = nil) {
        guard let appId = args["appId"] as? String,
            let appVersionId = args["appVersionId"] as? String,
            let auth = args["auth"] as? String else {
                return nil
        }
        self.init(appId: appId, appVersionId: appVersionId, auth: auth, delegate: delegate)
    }
    
    init(appId: String, appVersionId: String, auth: String, delegate: SesameApplicationServiceDelegate?) {
        self.app = SesameAppVersion(appId: appId, appVersionId: appVersionId, auth: auth)
        self.delegate = delegate
        super.init()
    }
    
    /// MARK: protocol ApplicationService UIApplicationDelegate
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        print("Sesame service app did launch")
        
        appState = .opened
        
        app.tracker.actions.append(ReportEvent.init(ReportEvent.ACTION_APP_OPEN, [String : Any]()))
        app.api.boot(app: app) { (success, newConfig) in
            guard success else {
                Logger.debug(error: "Boot call failed.")
                return
            }
            if let newConfig = newConfig {
                self.app.config = newConfig
            }
        }
        return true
    }
    
}
