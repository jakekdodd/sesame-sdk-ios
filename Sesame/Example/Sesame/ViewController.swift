//
//  ViewController.swift
//  Sesame
//
//  Created by cuddergambino on 07/23/2018.
//  Copyright (c) 2018 cuddergambino. All rights reserved.
//

import UIKit
import Sesame

class ViewController: UIViewController {
    
    static var instance: ViewController?

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
        
        button.showTest()
    }

}

