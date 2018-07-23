//
//  ViewController.swift
//  Sesame
//
//  Created by cuddergambino on 07/19/2018.
//  Copyright (c) 2018 cuddergambino. All rights reserved.
//

import UIKit
import Sesame

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBAction
    func printEventCount() {
        print("Events:\(String(describing:Sesame.shared?.tracker.actions.count))")
    }

}

