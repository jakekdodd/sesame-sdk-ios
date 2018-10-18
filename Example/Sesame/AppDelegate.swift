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
        Sesame.shared = .init(appId: "bf6bfcca-4cee-42ef-b699-59466bddedeb",
                              auth: "ghRPZc-N2qiCe-HbVLeciH43ySaBBkYABTCAaO6mGI-ZasjLd3l4cj59ouJfbYz93fUwiFtO26NtmyxgqQ2wZQ",
                              versionId: "88547a03-01c5-4ab9-b63d-effface60789",
                              userId: userId)

        return true
    }

}
