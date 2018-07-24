//
//  SesameApplicationService.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation

final public class SesameApplicationService : UIResponder, UIApplicationDelegate {
    
    public init(appId: String, appVersionId: String, auth: String) {
        Sesame.createShared(appId: appId, appVersionId: appVersionId, auth: auth)
        super.init()
        Sesame.shared?.service = self
        print("Configured Sesame")
    }
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        print("Sesame service app did launch")
        
//        Sesame.shared?.tracker.actions.append(ReportEvent.init(ReportEvent.ACTION_APP_OPEN, [String : Any]()))
//        Sesame.shared?.boot()
        return true
    }
    
}
