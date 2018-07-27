//
//  SheenEffectView.swift
//  Sesame
//
//  Created by Akash Desai on 7/26/18.
//

import Foundation

@objc
open class SheenEffectView : UIView {
    
    public enum SheenWidth : CGFloat {
        case short = 0.333, medium = 1, long = 1.667
    }
    
    public var duration:TimeInterval = 2
    public var sheenImageView: UIImageView?
    public var sheenWidth: SheenWidth = .medium
    public var sheenColor: UIColor? = nil
    public var opacityMask: Bool = false
    public var hapticFeedback: Bool = false
    public var systemSound: UInt32 = 0
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    fileprivate func setup() {
        clipsToBounds = true
        isUserInteractionEnabled = false
    }
    
    open func constrainToSuperview() {
        guard let superview = superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([topAnchor.constraint(equalTo: superview.topAnchor),
                                     leftAnchor.constraint(equalTo: superview.leftAnchor),
                                     widthAnchor.constraint(equalTo: superview.widthAnchor),
                                     heightAnchor.constraint(equalTo: superview.heightAnchor),
                                     ])
    }
    
    public func start(completion: @escaping (SheenEffectView) -> Void = {view in view.removeFromSuperview()}) {
        if sheenImageView == nil,
            let bundle = Bundle.sesame,
            var image = UIImage(named: "sheen", in: bundle, compatibleWith: nil) {
            if let color = sheenColor {
                image = image.tint(tintColor: color)
            }
            sheenImageView = UIImageView(image: image)
            let height = bounds.height
            let width: CGFloat =  height * sheenWidth.rawValue
            sheenImageView?.frame = CGRect(x: 0, y: 0, width: width, height: height)
        }
        
        guard let imageView = sheenImageView else {
            Logger.debug(error: "No image set for sheen")
            completion(self)
            return
        }
        
        if opacityMask {
            mask = superview?.generateMask()
        }
        
        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.byValue = self.frame.width + imageView.frame.width
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        
        CoreAnimationDelegate(
            willStart: { start in
                imageView.frame.origin = CGPoint(x: -imageView.frame.width, y: 0)
                self.addSubview(imageView)
                start()
        },
            didStart:{
                AudioEffect.play(self.systemSound, vibrate: self.hapticFeedback)
        },
            didStop: {
                imageView.removeFromSuperview()
                completion(self)
        }).start(view: imageView, animation: animation)
    }
}
