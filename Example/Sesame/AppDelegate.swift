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
        Sesame.shared = .init(appId: "ca604297-0150-4bf7-a973-669fecef4ce0",
                              auth: "4f5b1b6f54724a2baed4f344af83c7113b0d72d71efc4b70bbc1a77f2b0dc92f",
                              versionId: "c8372963-752d-4ab3-b885-58a670828be7",
                              userId: userId)

        return true
    }

}
