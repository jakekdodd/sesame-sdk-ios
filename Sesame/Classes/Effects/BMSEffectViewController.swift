//
//  BMSEffectViewController.swift
//  Sesame
//
//  Created by Akash Desai on 9/19/18.
//

import UIKit

open class BMSEffectViewController: UIViewController {

    var effectViews = [BMSVisualEffectView]()
    var reinforcementEffects: [EffectAttributes]?

    open override func viewDidLoad() {
        super.viewDidLoad()
        view.isUserInteractionEnabled = false

        guard let reinforcementEffects = reinforcementEffects else { return }
        for effect in reinforcementEffects {
            switch effect["name"] as? String {
            case "confetti":
                effectViews.append(BMSConfettiEffectView())
                BMSLog.error("Got attributes:\(effect as AnyObject)")

            case "sheen":
                effectViews.append(BMSSheenEffectView())

            case "emojisplosion":
                effectViews.append(BMSEmojiplosionEffectView())

            default:
                break
            }
        }
    }

    func showEffect(_ completion: @escaping (Bool) -> Void = {_ in}) {
        DispatchQueue.main.async {
            for effectView in self.effectViews {
                guard effectView.superview == nil else {
                        completion(false)
                        return
                }
                self.view.addSubview(effectView)
                effectView.constrainToSuperview()
                effectView.start {
                    DispatchQueue.main.async {
                        effectView.removeFromSuperview()
                        completion(true)
                    }
                }
            }
        }
    }
}
