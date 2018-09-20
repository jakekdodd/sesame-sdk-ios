//
//  BMSEffectViewController.swift
//  Sesame
//
//  Created by Akash Desai on 9/19/18.
//

import UIKit

open class BMSEffectViewController: UIViewController {

    var overlayEffectView: BMSEffectView?

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
                if self.overlayEffectView as? BMSConfettiEffectView == nil {
                    self.overlayEffectView?.removeFromSuperview()
                    let confettiView = BMSConfettiEffectView()
                    self.view.addSubview(confettiView)
                    confettiView.constrainToSuperview()
                    self.overlayEffectView = confettiView
                }
                self.overlayEffectView?.start()

            case "sheen":
                if self.overlayEffectView as? BMSSheenEffectView == nil {
                    self.overlayEffectView?.removeFromSuperview()
                    let sheenView = BMSSheenEffectView()
                    self.view.addSubview(sheenView)
                    sheenView.constrainToSuperview()
                    self.overlayEffectView = sheenView
                }
                self.overlayEffectView?.start()

            case "emojisplosion":
                if self.overlayEffectView as? BMSEmojiplosionEffectView == nil {
                    self.overlayEffectView?.removeFromSuperview()
                    let emojiView = BMSEmojiplosionEffectView()
                    self.view.addSubview(emojiView)
                    emojiView.constrainToSuperview()
                    self.overlayEffectView = emojiView
                }
                self.overlayEffectView?.start()

            default:
                break
            }
        }
    }
}
