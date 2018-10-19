//
//  BMSEffectViewController.swift
//  Sesame
//
//  Created by Akash Desai on 9/19/18.
//

import UIKit

open class BMSEffectViewController: UIViewController {

    public var effectViews = [BMSVisualEffectView]()
    public var reinforcementEffects: [[String: NSObject?]]?

    open override func viewDidLoad() {
        super.viewDidLoad()
        view.isUserInteractionEnabled = false

        guard let reinforcementEffects = reinforcementEffects else { return }
        for effect in reinforcementEffects {
            let effectView: BMSVisualEffectView
            switch effect["name"] as? String {
            case "confetti":
                let confetti = BMSConfettiEffectView()
                effectView = confetti

            case "sheen":
                let sheen = BMSSheenEffectView()
                effectView = sheen

            case "emojisplosion":
                let emojisplosion = BMSEmojiplosionEffectView()
                effectView = emojisplosion

            default:
                continue
            }
            effectView.set(attributes: effect)
            effectViews.append(effectView)
        }
    }

    public func showEffect(_ completion: @escaping (Bool) -> Void = {_ in}) {
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
