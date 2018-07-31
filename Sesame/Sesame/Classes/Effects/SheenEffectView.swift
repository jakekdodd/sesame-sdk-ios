//
//  SheenEffectView.swift
//  Sesame
//
//  Created by Akash Desai on 7/26/18.
//

import Foundation

@objc
open class SheenEffectView : OverlayEffectView {
    
    public enum SheenWidth : CGFloat {
        case short = 0.333, medium = 1, long = 1.667
    }
    
    @IBInspectable @objc
    public var duration:Double = 2
    @IBInspectable @objc
    public var sheenImageView: UIImageView?
    public var sheenWidth: SheenWidth = .medium
    @IBInspectable @objc
    public var sheenColor: UIColor? = nil
    @IBInspectable @objc
    public var opacityMask: Bool = false
    @IBInspectable @objc
    public var hapticFeedback: Bool = false
    @IBInspectable @objc
    public var systemSound: UInt32 = 0
    
    override open func didRotate() {
        if opacityMask && superview != nil {
            mask = superview?.generateMask()
            guard let sheenImageView = sheenImageView else { return }
            sheenImageView.frame = CGRect(origin: sheenImageView.frame.origin, size: bounds.size.applying(CGAffineTransform.init(scaleX: 1, y: sheenWidth.rawValue)))
        }
    }
    
    @objc(start)
    public func objc_start() {
        self.start()
    }
    
    @objc
    open func start(completion: @escaping (SheenEffectView) -> Void = {_ in}) {
        resetSheen()
        
        guard let sheenImageView = sheenImageView else {
            Logger.debug(error: "No image set for sheen")
            completion(self)
            return
        }
        
        guard sheenImageView.superview == nil else {
            return
        }
        
        if opacityMask {
            mask = superview?.generateMask()
        }
        
        UIView.animate(withDuration: duration, animations: {
            self.addSubview(sheenImageView)
            sheenImageView.transform = sheenImageView.transform.translatedBy(x: self.bounds.width + sheenImageView.frame.width, y: 0)
            AudioEffect.play(self.systemSound, vibrate: self.hapticFeedback)
        }) { _ in
            sheenImageView.removeFromSuperview()
            completion(self)
        }
    }
    
    func resetSheen() {
        if sheenImageView == nil,
            let bundle = Bundle.sesame,
            var image = UIImage(named: "sheen", in: bundle, compatibleWith: nil) {
            if let color = sheenColor {
                image = image.tint(tintColor: color)
            }
            self.sheenImageView = UIImageView(image: image)
        }
        
        if let sheenImageView = sheenImageView {
            sheenImageView.frame = CGRect(origin: CGPoint(x: -bounds.size.width, y: 0), size: bounds.size.applying(CGAffineTransform.init(scaleX: 1, y: sheenWidth.rawValue)))
        }
    }
}
