//
//  UIView+UIView+DopamineAnimation.swift
//  Sesame
//
//  Created by Akash Desai on 9/28/17.
//

import Foundation
import UIKit
import AudioToolbox
import AVFoundation

// call all these in main queue DispatchQueue.main
public extension UIView {
    
    @objc
    public func showEmojiSplosion(at location:CGPoint,
                                  content: CGImage? = "❤️".image().cgImage,
                                  scale: CGFloat = 0.6,
                                  scaleSpeed: CGFloat = 0.2,
                                  scaleRange: CGFloat = 0.2,
                                  lifetime: Float = 3.0,
                                  lifetimeRange: Float = 0.5,
                                  fadeout: Float = -0.2,
                                  quantity birthRate: Float = 6.0,
                                  bursts birthCycles: Double = 1.0,
                                  velocity: CGFloat = -50,
                                  xAcceleration: CGFloat = 0,
                                  yAcceleration: CGFloat = -150,
                                  angle: CGFloat = -90,
                                  range: CGFloat = 45,
                                  spin: CGFloat = 0,
                                  hapticFeedback: Bool = false,
                                  systemSound: UInt32 = 0,
                                  completion: (()->Void)? = nil
        ) {
        guard let content = content else {
            Logger.debug(error: "Received nil image content!")
            return
        }
        
        DispatchQueue.main.async {
            let emitter = CAEmitterLayer()
            emitter.emitterPosition = location
            emitter.beginTime = CACurrentMediaTime() - 0.9
            
            let cell = CAEmitterCell()
            cell.contents = content
            cell.birthRate = birthRate
            cell.lifetime = lifetime
            cell.lifetimeRange = lifetimeRange
            cell.spin = spin.degreesToRadians()
            cell.spinRange = cell.spin / 8
            cell.velocity = velocity
            cell.velocityRange = cell.velocity / 3
            cell.xAcceleration = xAcceleration
            cell.yAcceleration = yAcceleration
            cell.scale = scale
            cell.scaleSpeed = scaleSpeed
            cell.scaleRange = scaleRange
            cell.emissionLongitude = angle.degreesToRadians()
            cell.emissionRange = range.degreesToRadians()
            if fadeout > 0 {
                cell.alphaSpeed = -1.0 / fadeout
                cell.color = cell.color?.copy(alpha: CGFloat(lifetime / fadeout))
            } else if fadeout < 0 { // fadein
                cell.alphaSpeed = 1.0 / -fadeout
                cell.color = cell.color?.copy(alpha: 0)
            }
            emitter.emitterCells = [cell]
            
            self.layer.addSublayer(emitter)
//            BKLog.debug("💥 Emojisplosion on <\(NSStringFromClass(type(of: self)))> at <\(location)>!")
            AudioEffect.play(systemSound, vibrate: hapticFeedback)
            DispatchQueue.main.asyncAfter(deadline: .now() + birthCycles) {
                emitter.birthRate = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(lifetime + lifetimeRange)) {
                    emitter.removeFromSuperlayer()
//                    BKLog.debug("💥 Emojisplosion done")
                    completion?()
                }
            }
        }
    }
    
    @objc
    public func showSheen(duration: Double = 2.0, color: UIColor? = nil, heightMultiplier: CGFloat = 1, widthMultiplier: CGFloat = 1.667, hapticFeedback: Bool = false, systemSound: UInt32 = 0, completion: (()->Void)? = nil) {
        guard let bundle = Bundle.sesame,
            var image = UIImage(named: "sheen", in: bundle, compatibleWith: nil) else {
                Logger.debug(error: "Could not find sheen image asset")
                return
        }
        
        if let color = color {
            image = image.tint(tintColor: color)
        }
        let imageView = UIImageView(image: image)
        let height = self.frame.height * heightMultiplier
        let width: CGFloat =  self.frame.height * widthMultiplier
        imageView.frame = CGRect(x: -width, y: 0, width: width, height: height)
        
        let containerView = UIImageView(frame: CGRect(origin: .zero, size: self.bounds.size))
        containerView.mask = self.generateMask()
        containerView.addSubview(imageView)
        
        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.byValue = self.frame.width + width
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        
        AudioEffect.play(systemSound, vibrate: hapticFeedback)
        CoreAnimationDelegate(
            willStart: { start in
                self.addSubview(containerView)
                start()
        },
            didStart:{
//                AudioEffect.play(systemSound, vibrate: hapticFeedback)
        },
            didStop: {
                containerView.removeFromSuperview()
                completion?()
        }).start(view: imageView, animation: animation)
    }
    
}


