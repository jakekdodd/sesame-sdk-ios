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
        
        addEffect(backgroundImage)
        
    }
    
    func addEffect(_ view: UIView, duration: TimeInterval = 3) {
        let effect = UIBlurEffect(style: UIBlurEffectStyle.prominent)
        
        let effectView = UIVisualEffectView()
        effectView.effect = effect
        
        effectView.alpha = 0
        view.addSubview(effectView)
        effectView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([effectView.heightAnchor.constraint(equalTo: view.heightAnchor),
                                     effectView.widthAnchor.constraint(equalTo: view.widthAnchor)
            ])
        UIView.animate(withDuration: 0.3, animations: {
            effectView.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: duration, animations: {
                effectView.alpha = 0
            }) { _ in
                effectView.removeFromSuperview()
            }
        }
    }

}

