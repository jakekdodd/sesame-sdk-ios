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
        case closed, opened
    }
    
    var lastOpened: Date? = nil
    var appState: SesameAppState = .closed {
        didSet {
            Logger.debug("App state changed from \(oldValue) to \(appState)")
            let reinforce = {
                let reinforcement = self.app.reinforcer.cartridge.removeDecision()
                self.delegate?.app(self.app, didReceiveReinforcement: reinforcement, withOptions: self.app.reinforcer.options?[reinforcement])
            }
            
            switch (oldValue, appState) {
            case (.closed, .opened):
                self.lastOpened = Date()
                reinforce()
                
            case (.opened, .opened):
                let now = Date()
                if let lastOpened = lastOpened,
                    lastOpened.timeIntervalSince(now) > 2
                {
                    reinforce()
                    self.lastOpened = Date()
                } else {
                    Logger.debug("App reopened too soon for another reinforcement")
                }
                
            case (.opened, .closed):
                self.lastOpened = nil
                
            default:
                break
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
        Logger.debug("Sesame service app did launch")
        
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
    
    public func applicationWillEnterForeground(_ application: UIApplication) {
        Logger.debug("Sesame service app will enter foreground")
        
        appState = .opened
    }
    
    public func applicationDidEnterBackground(_ application: UIApplication) {
        Logger.debug("Sesame service app did enter background")
        
        appState = .closed
    }
    
}
