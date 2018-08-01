//
//  ConfettiEffectView.swift
//  BoundlessKit
//
//  Created by Akash Desai on 7/26/18.
//  Copyright © 2018 BoundlessMind. All rights reserved.
//

import Foundation
import UIKit

@objc
open class ConfettiEffectView : OverlayEffectView {
    
    @objc
    public enum ConfettiShape : Int {
        case rectangle, circle, spiral
    }
    
    @IBInspectable @objc
    public var duration:Double = 2
    @IBInspectable @objc
    public var size:CGSize = CGSize(width: 9, height: 6)
    public var shapes:[ConfettiShape] = [.rectangle, .rectangle, .circle, .spiral]
    @objc
    public var colors:[UIColor] = [UIColor.from(rgb: "4d81fb", alpha: 0.8) ?? UIColor.purple,
                                   UIColor.from(rgb: "4ac4fb", alpha: 0.8) ?? UIColor.blue,
                                   UIColor.from(rgb: "9243f9", alpha: 0.8) ?? UIColor.purple,
                                   UIColor.from(rgb: "fdc33b", alpha: 0.8) ?? UIColor.orange,
                                   UIColor.from(rgb: "f7332f", alpha: 0.8) ?? UIColor.red,]
    @IBInspectable @objc
    public var hapticFeedback: Bool = false
    @IBInspectable @objc
    public var systemSound: UInt32 = 0
    
    var burstEmitter: CAEmitterLayer?
    var showerEmitter: CAEmitterLayer?
    
    @objc(start)
    public func objc_start() {
        self.start()
    }
    
    @objc
    public func start(completion: @escaping (ConfettiEffectView) -> Void = {_ in}) {
        self.showConfetti(duration: duration, size: size, shapes: shapes, colors: colors, hapticFeedback: hapticFeedback, systemSound: systemSound, completion: completion)
    }
    
    /**
     Creates a CAEmitterLayer that drops celebration confetti from the top of the view
     
     - parameters:
        - duration: How long celebration confetti should last in seconds. Default is set to `2`.
        - size: Size of individual confetti pieces. Default is set to `CGSize(width: 9, height: 6)`.
        - shapes: This directly affects the quantity of confetti. For example, [.circle] will show half as much confetti as [.circle, .circle].
        - colors: This directly affects the quantity of confetti. For example, [.blue] will show half as much confetti as [.blue, .blue].
        - hapticFeedback: If set to true, the device will vibrate at the start of animation. Default is set to `false`.
        - systemSound: The SystemSoundId to play at the start of animation. If `0` no sound is played. Default is set to `0`.
        - completion: Completion handler performated at the end of animation.
     */
    func showConfetti(duration:TimeInterval = 2,
                             size:CGSize = CGSize(width: 9, height: 6),
                             shapes:[ConfettiShape] = [.rectangle, .rectangle, .circle, .spiral],
                             colors:[UIColor] = [UIColor.from(rgb: "4d81fb", alpha: 0.8) ?? UIColor.purple,
                                                 UIColor.from(rgb: "4ac4fb", alpha: 0.8) ?? UIColor.blue,
                                                 UIColor.from(rgb: "9243f9", alpha: 0.8) ?? UIColor.purple,
                                                 UIColor.from(rgb: "fdc33b", alpha: 0.8) ?? UIColor.orange,
                                                 UIColor.from(rgb: "f7332f", alpha: 0.8) ?? UIColor.red,],
                             hapticFeedback: Bool = false,
                             systemSound: UInt32 = 0,
                             completion: @escaping (ConfettiEffectView)->Void = {_ in}) {
        let burstDuration = 0.8
        let showerDuration = max(0, duration - burstDuration)
        self.confettiBurst(duration: burstDuration, size: size, shapes: shapes, colors: colors) {
            AudioEffect.play(systemSound, vibrate: hapticFeedback)
            self.confettiShower(duration: showerDuration, size: size, shapes: shapes, colors: colors, completion: completion)
        }
    }
    
    func confettiBurst(duration:TimeInterval,
                              size:CGSize,
                              shapes:[ConfettiShape],
                              colors:[UIColor],
                              startedHandler: @escaping ()->Void) {
        DispatchQueue.main.async {
            
            /* Create bursting confetti */
            let burstEmitter = CAEmitterLayer()
            self.burstEmitter  = burstEmitter
            self.setEmitterPositionAndSize(burstEmitter)
            
            var cells:[CAEmitterCell] = []
            for shape in shapes {
                let confettiImage: CGImage
                switch shape {
                case .rectangle:
                    confettiImage = ConfettiShape.rectangleConfetti(size: size)
                case .circle:
                    confettiImage = ConfettiShape.circleConfetti(size: size)
                case .spiral:
                    confettiImage = ConfettiShape.spiralConfetti(size: size)
                }
                for color in colors {
                    let cell = CAEmitterCell()
                    cell.contents = confettiImage
                    cell.color = color.cgColor
                    cell.setValuesForBurstPhase1()
                    cells.append(cell)
                }
            }
            burstEmitter.emitterCells = cells
            
            /* Start showing the confetti */
            burstEmitter.beginTime = CACurrentMediaTime()
            self.layer.addSublayer(burstEmitter)
            self.layer.setNeedsLayout()
            startedHandler()
            
            /* Remove the burst effect */
            DispatchQueue.main.asyncAfter(deadline: .now() + duration / 2.0) {
                if let cells = burstEmitter.emitterCells {
                    for cell in cells {
                        cell.setValuesForBurstPhase2()
                    }
                }
                
                /* Remove the confetti emitter */
                DispatchQueue.main.asyncAfter(deadline: .now() + duration / 2.0) {
                    burstEmitter.birthRate = 0
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(burstEmitter.emitterCells?.first?.lifetimeMax ?? 0)) {
                        burstEmitter.removeFromSuperlayer()
                        self.burstEmitter = nil
                    }
                }
            }
        }
    }
    
    func confettiShower(duration:TimeInterval,
                               size:CGSize,
                               shapes:[ConfettiShape],
                               colors:[UIColor],
                               completion: @escaping (ConfettiEffectView)->Void) {
        DispatchQueue.main.async {
            
            /* Create showering confetti */
            let showerEmitter = CAEmitterLayer()
            self.showerEmitter = showerEmitter
            self.setEmitterPositionAndSize(showerEmitter)
            
            var cells:[CAEmitterCell] = []
            for shape in shapes {
                let confettiImage: CGImage
                switch shape {
                case .rectangle:
                    confettiImage = ConfettiShape.rectangleConfetti(size: size)
                case .circle:
                    confettiImage = ConfettiShape.circleConfetti(size: size)
                case .spiral:
                    confettiImage = ConfettiShape.spiralConfetti(size: size)
                }
                for color in colors {
                    let cell = CAEmitterCell()
                    cell.contents = confettiImage
                    cell.color = color.cgColor
                    cell.setValuesForShower()
                    cells.append(cell)
                    /* Create some blurred confetti for depth perception */
                    let rand = Int(arc4random_uniform(2))
                    if rand != 0 {
                        let blurredCell = CAEmitterCell()
                        blurredCell.contents = confettiImage.blurImage(radius: rand)
                        blurredCell.color = color.cgColor
                        blurredCell.setValuesForShowerBlurred(scale: rand)
                        cells.append(blurredCell)
                    }
                }
            }
            showerEmitter.emitterCells = cells
            
            /* Start showing the confetti */
            showerEmitter.beginTime = CACurrentMediaTime()
            self.layer.addSublayer(showerEmitter)
            self.layer.setNeedsLayout()
            
            /* Remove the confetti emitter */
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                showerEmitter.birthRate = 0
                
                DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(showerEmitter.emitterCells?.first?.lifetimeMax ?? 0)) {
                    showerEmitter.removeFromSuperlayer()
                    self.showerEmitter = nil
                    completion(self)
                }
            }
        }
    }
    
    open override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        
        if let emitter = burstEmitter {
            setEmitterPositionAndSize(emitter)
        }
        if let emitter = showerEmitter {
            setEmitterPositionAndSize(emitter)
        }
    }
    
    fileprivate func setEmitterPositionAndSize(_ emitter: CAEmitterLayer) {
        emitter.emitterPosition = CGPoint(x: bounds.width / 2, y: -30)
        emitter.emitterShape = kCAEmitterLayerLine
        emitter.emitterSize = CGSize(width: bounds.width, height: 0)
    }
}

fileprivate extension CAEmitterCell {
    fileprivate func setValuesForBurstPhase1() {
        self.birthRate = 12
        self.lifetime = 5
        self.velocity = 250
        self.velocityRange = 50
        self.yAcceleration = -80
        self.emissionLongitude = .pi
        self.emissionRange = .pi/4
        self.spin = 1
        self.spinRange = 3
        self.scaleRange = 1
        self.redRange = 0.2
        self.blueRange = 0.2
        self.greenRange = 0.2
        
//        self.alphaSpeed = 1.0 / 0.2
//        self.color = self.color?.copy(alpha: 0)
    }
    
    fileprivate func setValuesForBurstPhase2() {
        self.birthRate = 0
        self.velocity = 300
        self.yAcceleration = 200
    }
    
    fileprivate func setValuesForShower() {
        self.birthRate = 20
        self.lifetime = 3
        self.velocity = 200
        self.velocityRange = 50
        self.yAcceleration = 200
        self.emissionLongitude = .pi
        self.emissionRange = .pi/4
        self.spin = 1
        self.spinRange = 3
        self.scale = 0.6
        self.scaleRange = 0.8
        self.redRange = 0.2
        self.blueRange = 0.2
        self.greenRange = 0.2
        
//        self.alphaSpeed = 1.0 / 0.2
//        self.color = self.color?.copy(alpha: 0)
    }
    
    fileprivate func setValuesForShowerBlurred(scale: Int) {
        self.birthRate = 3
        self.lifetime = 3
        self.velocity = 300
        self.velocityRange = 150
        self.yAcceleration = 200
        self.emissionLongitude = .pi
        self.spin = 1
        self.spinRange = 3
        self.scale = CGFloat(1 + scale)
        self.scaleRange = 2
        self.redRange = 0.2
        self.blueRange = 0.2
        self.greenRange = 0.2
        
//        self.alphaSpeed = 1.0 / 0.2
//        self.color = self.color?.copy(alpha: 0)
    }
    
    fileprivate var lifetimeMax: Float {
        get {
            return lifetime + lifetimeRange
        }
    }
}


fileprivate extension ConfettiEffectView.ConfettiShape {
    
    fileprivate static func rectangleConfetti(size: CGSize, color: UIColor = UIColor.white) -> CGImage {
        let offset = size.width / CGFloat((arc4random_uniform(7) + 1))
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        
        color.set()
        context.beginPath()
        context.move(to: CGPoint(x:offset, y: 0))
        context.addLine(to: CGPoint(x: size.width, y: 0))
        context.addLine(to: CGPoint(x: size.width - offset, y: size.height))
        context.addLine(to: CGPoint(x: 0, y: size.height))
        context.closePath()
        context.fillPath()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!.cgImage!
    }
    
    fileprivate static func spiralConfetti(size: CGSize, color: UIColor = UIColor.white) -> CGImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        
        color.set()
        let lineWidth:CGFloat = size.width / 8.0
        let halfLineWidth = lineWidth / 2.0
        context.beginPath()
        context.setLineWidth(lineWidth)
        context.move(to: CGPoint(x: halfLineWidth, y: halfLineWidth))
        context.addCurve(to: CGPoint(x: size.width - halfLineWidth, y: size.height - halfLineWidth), control1: CGPoint(x: 0.25*size.width, y: size.height), control2: CGPoint(x: 0.75*size.width, y: 0))
        context.strokePath()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!.cgImage!
    }
    
    fileprivate static func circleConfetti(size: CGSize, color: UIColor = UIColor.white) -> CGImage {
        let diameter = min(size.width, size.height)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        
        color.set()
        context.fillEllipse(in: CGRect(origin: .zero, size: CGSize(width: diameter, height: diameter)))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!.cgImage!
    }
}
