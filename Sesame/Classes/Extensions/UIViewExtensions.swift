//
//  UIViewExtensions.swift
//  Sesame
//
//  Created by Akash Desai on 12/1/17.
//

import Foundation

extension UIView: SesameReinforcementDelegate {
    public func app(_ app: Sesame, didReceiveReinforcement reinforcement: String, withOptions options: [String: Any]?) {
        DispatchQueue.main.async {
            var effectView: BMSEffectView
            switch reinforcement {
            case "confetti":
                effectView = BMSConfettiEffectView()

            case "sheen":
                effectView = BMSSheenEffectView()

            case "emojisplosion":
                effectView = BMSEmojiplosionEffectView()

            default:
                return
            }
            self.addSubview(effectView)
            effectView.constrainToSuperview()
            effectView.start {
                effectView.removeFromSuperview()
            }
        }
    }
}

extension UIView {
    func generateMask(color: UIColor = .clear) -> UIView {
        var image: UIImage?
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0)
        if let context = UIGraphicsGetCurrentContext() {
            self.layer.render(in: context)
            color.setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: self.bounds.size)).fill(with: .sourceAtop, alpha: 1.0)
        }
        image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return UIImageView(image: image)
    }
}
