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
        
        addEffect(view)
        
    }
    
    func addEffect(_ view: UIView, duration: TimeInterval = 3) {
       
        let confettiView = ConfettiEffectView.init(frame: CGRect.init(x: 0, y: view.bounds.height / 3, width: view.bounds.width, height: view.bounds.height / 3))
        confettiView.clipsToBounds = true
        confettiView.duration = 1
        
        view.addSubview(confettiView)
//        confettiView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([confettiView.heightAnchor.constraint(equalTo: view.heightAnchor),
//                                     confettiView.widthAnchor.constraint(equalTo: view.widthAnchor)
//            ])
        confettiView.start() {
            confettiView.removeFromSuperview()
        }
    }

}

