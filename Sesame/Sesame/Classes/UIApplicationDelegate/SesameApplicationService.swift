//
//  SesameApplicationService.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation
final class SesameApplicationService : NSObject, ApplicationService {
    
    override init() {
        Sesame.createShared(appId: "570ffc491b4c6e9869482fbf", appVersionId: "rams1", auth: "d388c7074d8a283bff1f01eb932c1c9e6bec3b10")
        super.init()
        Sesame.shared?.service = self
        print("Configured Sesame")
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        print("Sesame service app did launch")
        
//        Sesame.shared?.tracker.actions.append(ReportEvent.init(ReportEvent.ACTION_APP_OPEN, [String : Any]()))
        Sesame.shared?.boot()
        return true
    }
}
