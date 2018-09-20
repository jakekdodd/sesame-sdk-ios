//
//  BMSEffectViewController.swift
//  Sesame
//
//  Created by Akash Desai on 9/19/18.
//

import UIKit

open class BMSEffectViewController: UIViewController {

    var effectView: BMSEffectView?

    open override func viewDidLoad() {
        super.viewDidLoad()

        view.isUserInteractionEnabled = false
    }

}

extension BMSEffectViewController: SesameReinforcementDelegate {
    public func app(_ app: Sesame, didReceiveReinforcement reinforcement: String, withOptions options: [String: Any]?) {
        DispatchQueue.main.async {
            switch reinforcement {
            case "confetti":
                if self.effectView as? BMSConfettiEffectView == nil {
                    self.effectView?.removeFromSuperview()
                    let confettiView = BMSConfettiEffectView()
                    self.view.addSubview(confettiView)
                    confettiView.constrainToSuperview()
                    self.effectView = confettiView
                }
                self.effectView?.start()

            case "sheen":
                if self.effectView as? BMSSheenEffectView == nil {
                    self.effectView?.removeFromSuperview()
                    let sheenView = BMSSheenEffectView()
                    self.view.addSubview(sheenView)
                    sheenView.constrainToSuperview()
                    self.effectView = sheenView
                }
                self.effectView?.start()

            case "emojisplosion":
                if self.effectView as? BMSEmojiplosionEffectView == nil {
                    self.effectView?.removeFromSuperview()
                    let emojiView = BMSEmojiplosionEffectView()
                    self.view.addSubview(emojiView)
                    emojiView.constrainToSuperview()
                    self.effectView = emojiView
                }
                self.effectView?.start()

            default:
                break
            }
        }
    }
}
