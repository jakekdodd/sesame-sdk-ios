//
//  SesameApplicationService.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation

public protocol SesameApplicationServiceDelegate : class {
    func app(_ app: Sesame, didReceiveReinforcement reinforcement: String, withOptions options: [String: Any]?)
}

final public class SesameApplicationService : NSObject, ApplicationService {
    
    public var app: Sesame
    public weak var delegate: SesameApplicationServiceDelegate?
    
    
    enum SesameAppState {
        case closed, opened, reopened
    }
    
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
                Logger.debug("App reopened")
            }
            
            if oldValue == .closed,
                appState == .opened {
                Logger.debug("App opening from close")
                self.lastOpened = Date()
                // TO-DO: call api for reinforcement, deliver reinforcement to delegate
                let reinforcement = app.reinforcer.cartridge.removeDecision()
                print("Removed decision reinforcement:\(reinforcement)")
                delegate?.app(app, didReceiveReinforcement: reinforcement, withOptions: app.reinforcer.options?[reinforcement])
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
        self.app = Sesame(appId: appId, appVersionId: appVersionId, auth: auth)
        self.delegate = delegate
        super.init()
    }
    
    /// MARK: protocol ApplicationService UIApplicationDelegate
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        print("Sesame service app did launch")
        
        appState = .opened
        
        app.tracker.actions.append(ReportEvent.init(ReportEvent.ACTION_APP_OPEN, [String : Any]()))
//        app.api.boot(app: app) { (success, newConfig) in
//            guard success else {
//                Logger.debug(error: "Boot call failed.")
//                return
//            }
//            if let newConfig = newConfig {
//                self.app.config = newConfig
//            }
//        }
        return true
    }
    
}
