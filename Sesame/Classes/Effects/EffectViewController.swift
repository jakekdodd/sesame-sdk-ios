//
//  EffectViewController.swift
//  Sesame
//
//  Created by Akash Desai on 9/19/18.
//

import UIKit

open class EffectViewController: UIViewController {

    var overlayEffectView: EffectView?

    open override func viewDidLoad() {
        super.viewDidLoad()

        view.isUserInteractionEnabled = false
    }

}

extension EffectViewController: SesameReinforcementDelegate {
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
                if self.overlayEffectView as? EmojiplosionEffectView == nil {
                    self.overlayEffectView?.removeFromSuperview()
                    let emojiView = EmojiplosionEffectView()
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
