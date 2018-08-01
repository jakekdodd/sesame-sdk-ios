//
//  ViewController.swift
//  Sesame
//
//  Created by cuddergambino on 07/23/2018.
//  Copyright (c) 2018 cuddergambino. All rights reserved.
//

import UIKit
import Sesame

class ViewController: UIViewController, SesameEffectDelegate {
    
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var button: UIButton!
    
    lazy var sheenView: SheenEffectView = {
        let view = button!
        let sheenView = SheenEffectView()
        sheenView.sheenImage = UIImage.init(named: "bmind")
        sheenView.opacityMask = true
        sheenView.duration = 4
        sheenView.sheenColor = UIColor.from(rgb: "FFD700")
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.sesame?.effectDelegate = self
        }
    }
    
    func app(_ app: Sesame, didReceiveReinforcement reinforcement: String, withOptions options: [String : Any]?) {
        print("Got reinforcement:\(reinforcement)")
        
        switch reinforcement {
        case "confetti":
            confettiView.start()
            
        case "sheen":
            sheenView.start()

        default:
            break
        }
    }
    
    @IBAction
    func didTapButton(_ sender: Any) {
        confettiView.start()

    }

}

