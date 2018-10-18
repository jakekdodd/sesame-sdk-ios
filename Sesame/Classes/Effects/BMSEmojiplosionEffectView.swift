//
//  BMSEmojiplosionEffectView.swift
//  Sesame
//
//  Created by Akash Desai on 9/15/18.
//

import UIKit

@objc
open class BMSEmojiplosionEffectView: BMSVisualEffectView {

    public var acceleration: (CGFloat, CGFloat) = (0, -150)
    public var angle: CGFloat = -90
    public var image: UIImage? = UIImage(text: "❤️")
    public var duration: Double = 1.0
    public var fadeout: Float = -1
    public var lifetime: Float = 3.0
    public var lifetimeNoise: Float = 0.5
    public var location: (CGFloat, CGFloat) = (0.5, 0.5)
    public var range: CGFloat = 45
    public var rate: Float = 4.0
    public var scaleMean: CGFloat = 0.6
    public var scaleNoise: CGFloat = 0.2
    public var scaleSpeed: CGFloat = 0.2
    public var speed: CGFloat = -50
    public var spin: CGFloat = 0
    public var hapticFeedback: Bool = false
    public var systemSound: UInt32 = 1007

    @objc
    public override init(frame: CGRect) {
        super.init(frame: frame)

        clipsToBounds = false
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public override func set(attributes: [String: NSObject?]) {
        guard attributes["name"] as? String == "emojisplosion" else { return }

        if let acceleration = attributes["acceleration"] as? [Double],
            acceleration.count == 2 {
            self.acceleration = (CGFloat(acceleration[0] * 1000000), CGFloat(acceleration[1] * 1000000))
            BMSLog.info("Set acceleration to:\(self.acceleration)")
        } else { BMSLog.error("Missing parameter")}

        if let angle = attributes["angle"] as? Double {
            self.angle = CGFloat(angle)
        } else { BMSLog.error("Missing parameter")}

        if let content = attributes["content"] as? String {
            self.image = UIImage(text: content)
        } else { BMSLog.error("Missing parameter")}

        if let durationString = attributes["duration"] as? String,
            let duration = Double(durationString) {
            self.duration = duration / 1000
        } else { BMSLog.error("Missing parameter")}

        if let fade = attributes["fade"] as? Double {
            self.fadeout = Float(fade) / 1000
        } else { BMSLog.error("Missing parameter")}

        if let lifetime = attributes["lifetime"] as? Double {
            self.lifetime = Float(lifetime) / 1000
        } else { BMSLog.error("Missing parameter")}

        if let lifetimeNoise = attributes["lifetimeNoise"] as? Double {
            self.lifetimeNoise = Float(lifetimeNoise) / 1000
        } else { BMSLog.error("Missing parameter")}

        if let location = attributes["location"] as? [Double],
            location.count == 2 {
            self.location = (CGFloat(location[0]), CGFloat(location[1]))
        } else { BMSLog.error("Missing parameter")}

        if let range = attributes["range"] as? Double {
            self.range = CGFloat(range)
        } else { BMSLog.error("Missing parameter")}

        if let scaleMean = attributes["scaleMean"] as? Double {
            self.scaleMean = CGFloat(scaleMean)
        } else { BMSLog.error("Missing parameter")}

        if let scaleNoise = attributes["scaleNoise"] as? Double {
            self.scaleNoise = CGFloat(scaleNoise)
        } else { BMSLog.error("Missing parameter")}

        if let scaleSpeed = attributes["scaleSpeed"] as? Double {
            self.scaleSpeed = CGFloat(scaleSpeed) * 1000
        } else { BMSLog.error("Missing parameter")}

        if let speed = attributes["speed"] as? Double {
            self.speed = CGFloat(speed) * 1000
        } else { BMSLog.error("Missing parameter")}

    }

    public override func start(completion: @escaping () -> Void = {}) {
        guard let cgImage = image?.cgImage else {
            BMSLog.warning("Image not set")
            completion()
            return
        }

        DispatchQueue.main.async {
            let emitter = CAEmitterLayer()
            emitter.emitterPosition = self.bounds.pointWithMargins(x: self.location.0, y: self.location.1)
            emitter.beginTime = CACurrentMediaTime() - 0.9

            let cell = CAEmitterCell()
            cell.contents = cgImage
            cell.birthRate = self.rate
            cell.lifetime = self.lifetime
            cell.lifetimeRange = self.lifetimeNoise
            cell.spin = self.spin.degreesToRadians()
            cell.spinRange = cell.spin / 8
            cell.velocity = self.speed
            cell.velocityRange = cell.velocity / 3
            cell.xAcceleration = self.acceleration.0
            cell.yAcceleration = self.acceleration.1
            cell.scale = self.scaleMean
            cell.scaleSpeed = self.scaleSpeed
            cell.scaleRange = self.scaleNoise
            cell.emissionLongitude = self.angle.degreesToRadians()
            cell.emissionRange = self.range.degreesToRadians()
            if self.fadeout > 0 {
                cell.alphaSpeed = -1.0 / self.fadeout
                cell.color = cell.color?.copy(alpha: CGFloat(self.lifetime / self.fadeout))
            } else if self.fadeout < 0 { // fadein
                cell.alphaSpeed = 1.0 / -self.fadeout
                cell.color = cell.color?.copy(alpha: 0)
            }
            emitter.emitterCells = [cell]

            self.layer.addSublayer(emitter)
            BMSLog.verbose("💥 Emojiplosion on <\(NSStringFromClass(type(of: self)))> at <\(emitter.emitterPosition)>!")
            BMSSoundEffect.play(self.systemSound, vibrate: self.hapticFeedback)
            DispatchQueue.main.asyncAfter(deadline: .now() + self.duration) {
                emitter.birthRate = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(self.lifetime + self.lifetimeNoise)) {
                    emitter.removeFromSuperlayer()
                    BMSLog.verbose("💥 Emojiplosion done")
                    completion()
                }
            }
        }
    }

}
