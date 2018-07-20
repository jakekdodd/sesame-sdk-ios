//
//  SesameApplicationService.swift
//  Sesame
//
//  Created by Akash Desai on 7/20/18.
//

import Foundation

final class SesameApplicationService : NSObject, ApplicationService {
    
    
    override init() {
        Sesame.configureShared(appId: "570ffc491b4c6e9869482fbf", secret: "d388c7074d8a283bff1f01eb932c1c9e6bec3b10", versionId: "rams1")
        print("Configured Sesame")
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        print("Sesame service app did launch")
        
        Sesame.shared?.tracker.actions.append(ReportEvent.init(ReportEvent.ACTION_APP_OPEN, [String : Any]()))
        return true
    }
    
}
