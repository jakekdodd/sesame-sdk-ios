//
//  SheenEffectView.swift
//  Sesame
//
//  Created by Akash Desai on 7/26/18.
//

import Foundation


@objc
open class SheenEffectView : UIView {
    
    public var imageView: UIImageView?
    public var generateMask: Bool = true
    public var duration:TimeInterval = 2
    public var color: UIColor? = nil
    public var hapticFeedback: Bool = false
    public var systemSound: UInt32 = 0
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func start(completion: @escaping () -> Void = {  }) {
        if imageView == nil,
            let bundle = Bundle.sesame,
            var image = UIImage(named: "sheen", in: bundle, compatibleWith: nil) {
            if let color = color {
                image = image.tint(tintColor: color)
            }
            let height = self.frame.height
            let width: CGFloat =  self.frame.height * 2.0 / 3.0
            imageView = UIImageView(image: image)
            imageView?.frame = CGRect(x: 0, y: 0, width: width, height: height)
        }
        
        guard let imageView = imageView else {
            Logger.debug(error: "No image set for sheen")
            completion()
            return
        }
        imageView.frame.origin = CGPoint(x: -imageView.frame.width, y: 0)
        
        if generateMask {
            mask = self.generateMask()
        }
        
        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.byValue = self.frame.width + imageView.frame.width
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        
        AudioEffect.play(systemSound, vibrate: hapticFeedback)
        CoreAnimationDelegate(
            willStart: { start in
                self.addSubview(imageView)
                start()
        },
            didStart:{
                AudioEffect.play(self.systemSound, vibrate: self.hapticFeedback)
        },
            didStop: {
                imageView.removeFromSuperview()
                completion()
        }).start(view: imageView, animation: animation)
    }
    
    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return false
    }
}
