//
//  ViewController.swift
//  Sesame
//
//  Created by cuddergambino on 07/23/2018.
//  Copyright (c) 2018 cuddergambino. All rights reserved.
//

import UIKit
import Sesame
import UserNotifications

class ViewController: UIViewController {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var button: UIButton!

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .all }

    @IBAction
    func didTapTest(_ sender: Any) {
        Sesame.shared?.addEvent(actionName: "buttonTap")
    }

    @IBAction
    func didTapLabel(_ sender: Any) {
        Sesame.shared?.appLifecycleTracker.didEnterBackground()
        Sesame.shared?.appLifecycleTracker.didBecomeActive()
    }

    @IBAction func didTapSendNotification(_ sender: Any) {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestPermission(remoteRegistration: false) { success in
                guard success == true else {
                    print("Notification permission denied")
                    return
                }
                UIApplication.shared.sendToBackground()
                UNUserNotificationCenter.current().scheduleNotification(
                    identifier: "welcomeScreen",
                    body: "Welcome to my App!",
                    time: 2
                )
            }
        } else {
            // Fallback on earlier versions
        }
    }
}
