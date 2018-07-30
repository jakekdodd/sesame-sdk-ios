//
//  AppDelegate.swift
//  Sesame
//
//  Created by cuddergambino on 07/23/2018.
//  Copyright (c) 2018 cuddergambino. All rights reserved.
//

import UIKit
import Sesame

@UIApplicationMain
class AppDelegate : AppDelegateWithSesame{
    
    override var SesameCredentials: [String : Any] {
        return ["appId": "570ffc491b4c6e9869482fbf",
                "appVersionId": "rams1",
                "auth": "d388c7074d8a283bff1f01eb932c1c9e6bec3b10"]
    }
    
}

//extension AppDelegate : SesameEffectDelegate {
//    
//    func app(_ app: Sesame, didReceiveReinforcement reinforcement: String, withOptions options: [String : Any]?) {
//        print("Got reinfrocement:\(reinforcement)")
//    }
//    
//}
