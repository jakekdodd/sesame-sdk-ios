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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]? = nil) -> Bool {
        Sesame.setShared(.init(appId: "570ffc491b4c6e9869482fbf",
                               appVersionId: "rams1",
                               auth: "d388c7074d8a283bff1f01eb932c1c9e6bec3b10"))
        Sesame.UIApplicationDelegate?.application(application, didFinishLaunchingWithOptions: launchOptions)

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        Sesame.UIApplicationDelegate?.applicationDidBecomeActive(application)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        Sesame.UIApplicationDelegate?.applicationDidEnterBackground(application)
    }

}
