//
//  SesameApplicationService.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation

open class SesameApplicationDelegate: PluggableApplicationDelegate {
    
    open var SesameCredentials: [String: Any] { get { return [:] } }
    
    open override var services: [ApplicationService] {
        var s = super.services
        if let sesameService = SesameApplicationService(args: SesameCredentials) {
            s.append(sesameService)
        }
        return s
    }
    
}

final public class SesameApplicationService : NSObject, ApplicationService {
    
    public convenience init?(args: [String: Any]) {
        guard let appId = args["appId"] as? String,
            let appVersionId = args["appVersionId"] as? String,
            let auth = args["auth"] as? String else {
                return nil
        }
        self.init(appId: appId, appVersionId: appVersionId, auth: auth)
    }
    
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
