//
//  EffectViewContainerViewController.swift
//  Sesame
//
//  Created by Akash Desai on 9/19/18.
//

import UIKit

open class EffectViewContainerViewController: UIViewController {

    var overlayEffectView: EffectView?

}

extension EffectViewContainerViewController: SesameEffectDelegate {
    public func app(_ app: Sesame, didReceiveReinforcement reinforcement: String, withOptions options: [String: Any]?) {
        DispatchQueue.main.async {
            switch reinforcement {
            case "confetti":
                if self.overlayEffectView as? ConfettiEffectView == nil {
                    self.overlayEffectView?.removeFromSuperview()
                    let confettiView = ConfettiEffectView()
                    self.view.addSubview(confettiView)
                    confettiView.constrainToSuperview()
                    self.overlayEffectView = confettiView
                }
                self.overlayEffectView?.start()

            case "sheen":
                if self.overlayEffectView as? SheenEffectView == nil {
                    self.overlayEffectView?.removeFromSuperview()
                    let sheenView = SheenEffectView()
                    self.view.addSubview(sheenView)
                    sheenView.constrainToSuperview()
                    self.overlayEffectView = sheenView
                }
                self.overlayEffectView?.start()

            case "emojisplosion":
                if self.overlayEffectView as? ExplosionEffectView == nil {
                    self.overlayEffectView?.removeFromSuperview()
                    let emojiView = ExplosionEffectView()
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
