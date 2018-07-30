//
//  SesameApplicationService.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation
import CoreData

final public class SesameApplicationService : NSObject {
    
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
        
        app?.appState = .opened
        
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
        
        app?.appState = .opened
    }
    
    public func applicationDidEnterBackground(_ application: UIApplication) {
        Logger.debug("Sesame service app did enter background")
        
        app?.appState = .closed
    }
    
}
