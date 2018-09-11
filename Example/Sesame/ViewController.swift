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

class ViewController: UIViewController, SesameEffectDelegate {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var button: UIButton!

    lazy var sheenView: SheenEffectView = {
        let view = button!
        let sheenView = SheenEffectView()
        sheenView.image = UIImage.init(named: "bmind")
        sheenView.opacityMask = true
        sheenView.duration = 4
        sheenView.color = UIColor.from(rgb: "FFD700")
        view.addSubview(sheenView)
        sheenView.constrainToSuperview()
        return sheenView
    }()

    lazy var confettiView: ConfettiEffectView = {
        let view = button!
        let confettiView = ConfettiEffectView()
        confettiView.duration = 5
        view.addSubview(confettiView)
        confettiView.constrainToSuperview()
        return confettiView
    }()

    var notificationCenter: UNUserNotificationCenter?
    override func viewDidLoad() {
        super.viewDidLoad()
        notificationCenter = UNUserNotificationCenter.current()
        Sesame.shared?.effectDelegate = self
    }

    func app(_ app: Sesame, didReceiveReinforcement reinforcement: String, withOptions options: [String: Any]?) {
        print("Got reinforcement:\(reinforcement)")
        DispatchQueue.main.async {
            switch reinforcement {
            case "confetti":
                self.confettiView.start()

            case "sheen":
                self.sheenView.start()

            default:
                break
            }
        }
    }

    @IBAction
    func didTapTest(_ sender: Any) {
//        confettiView.start()
        Sesame.shared?.addEvent(actionName: "buttonTap")

    }

    @IBAction
    func didTapLabel(_ sender: Any) {

    }

    @IBAction func didTapSendNotification(_ sender: Any) {
        notificationCenter?.scheduleNotification(identifier: "welcomeScreen", body: "Welcome to my App!", time: 2)
    }
}
