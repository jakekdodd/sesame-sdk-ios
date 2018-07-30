//
//  ViewController.swift
//  Sesame
//
//  Created by cuddergambino on 07/23/2018.
//  Copyright (c) 2018 cuddergambino. All rights reserved.
//

import UIKit
import Sesame
import AudioToolbox

class ViewController: UIViewController {
    
    static var instance: ViewController?
    
    @IBOutlet weak var confettiEffectView: ConfettiEffectView!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var button: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ViewController.instance = self
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBAction
    func didTapButton(_ sender: Any) {
//        print("Did tap button")
//        print("Action count:\(String(describing: Sesame.shared?.service.app.tracker.actions.count))")
        
//        button.showSheen()
        
        addEffect(button)
        
    }
    
    func addEffect(_ view: UIView, duration: TimeInterval = 3) {
       
//        /// When view is created programitcally
//        let confettiView = ConfettiEffectView.init(frame: CGRect.init(x: 0, y: view.bounds.height / 3, width: view.bounds.width, height: view.bounds.height / 3))
//        confettiView.duration = duration
//        view.addSubview(confettiView)
//        confettiView.start() { confettiView in
//            confettiView.removeFromSuperview()
//        }
        
        /// When view is placed on storboard
        confettiEffectView.duration = duration
        confettiEffectView.start()
        
        
//        /// When view is created programitcally
//        let sheenView = SheenEffectView(frame: view.bounds)
//        sheenView.opacityMask = true
//        view.addSubview(sheenView)
//        sheenView.constrainToSuperview()
//        sheenView.start() { sheenView in
//            sheenView.removeFromSuperview()
//        }
        
//        /// When view is placed on storyboard
//        sheenEffectView.constrainToSuperview()
//        sheenEffectView.systemSound = 1001
//        sheenEffectView.start()
    }

}

