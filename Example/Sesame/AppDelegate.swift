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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        guard NSClassFromString("XCTest") == nil else { return true }

        Sesame.shared = .init(appId: Sesame.PropertyList.file.appId,
                              auth: Sesame.PropertyList.file.auth,
                              versionId: Sesame.PropertyList.file.versionId,
                              userId: Sesame.PropertyList.file.userId)

        return true
    }

}
