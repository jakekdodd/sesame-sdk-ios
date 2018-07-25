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
class AppDelegate : SesameApplicationDelegate {
    
    override var SesameCredentials: [String : Any] {
        return ["appId": "570ffc491b4c6e9869482fbf",
                "appVersionId": "rams1",
                "auth": "d388c7074d8a283bff1f01eb932c1c9e6bec3b10"]
    }
    
    override func app(_ app: Sesame, didReceiveReinforcement reinforcement: String, withOptions options: [String : Any]?) {
        
        Logger.print("Got reinforcement:\(reinforcement) with options:\(options as AnyObject)")
        
        if reinforcement == "nuetral" {
            window?.showConfetti()
        }
        
    }
    
}

