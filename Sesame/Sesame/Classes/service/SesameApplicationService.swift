//
//  SesameApplicationService.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation
import CoreData

final public class SesameApplicationService : NSObject {
    enum SesameAppState {
        case closed, opened
    }
    
    fileprivate (set) var lastAppOpen: Date? = nil
    fileprivate (set) var appState: SesameAppState = .closed {
        didSet {
            didSet(oldValue: oldValue, appState: appState)
        }
    }
    public var app: Sesame?
    
    public convenience init(args: [String: Any]) {
        self.init()
        
        if let appId = args["appId"] as? String,
            let appVersionId = args["appVersionId"] as? String,
            let auth = args["auth"] as? String {
            app = Sesame(appId: appId, appVersionId: appVersionId, auth: auth, service: self)
        }
    }
    
}


// MARK: - UIApplicationDelegate
extension SesameApplicationService : ApplicationService {
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        Logger.debug("Sesame service app did launch")
        
        appState = .opened
        
        //        app.tracker.actions.append(ReportEvent.init(ReportEvent.ACTION_APP_OPEN, [String : Any]()))
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
    
    fileprivate func didSet(oldValue: SesameAppState, appState: SesameAppState) {
        Logger.debug("App state changed from \(oldValue) to \(appState)")
        
        switch (oldValue, appState) {
        case (.closed, .opened):
            self.lastAppOpen = Date()
            app?.open()
            
        case (.opened, .opened):
            let now = Date()
            if let lastOpened = lastAppOpen,
                lastOpened.timeIntervalSince(now) > 2
            {
                self.lastAppOpen = Date()
                app?.open()
            } else {
                Logger.debug("App reopened too soon for another reinforcement")
            }
            
        case (.opened, .closed):
            self.lastAppOpen = nil
            
        case (.closed, .closed):
            break
        }
    }
}
