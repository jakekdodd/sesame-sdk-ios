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
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var userId = "dev"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        Sesame.shared = .init(appId: "570ffc491b4c6e9869482fbf",
                              auth: "d388c7074d8a283bff1f01eb932c1c9e6bec3b10",
                              versionId: "sesame2",
                              userId: userId)

        return true
    }

}
