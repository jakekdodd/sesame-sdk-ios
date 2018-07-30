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
    
    fileprivate var screenIsVertical: Bool = (UIScreen.main.bounds.width < UIScreen.main.bounds.height)
    open override func layoutSubviews() {
        super.layoutSubviews()
        let isVertical = UIScreen.main.bounds.width < UIScreen.main.bounds.height
        if isVertical != screenIsVertical {
            screenIsVertical = isVertical
            if opacityMask && superview != nil {
                mask = superview?.generateMask()
            }
        }
    }
    
    @objc(start)
    public func objc_start() {
        self.start()
    }
    
    @objc
    open func start(completion: @escaping (SheenEffectView) -> Void = {_ in}) {
        if sheenImageView == nil,
            let bundle = Bundle.sesame,
            var image = UIImage(named: "sheen", in: bundle, compatibleWith: nil) {
            if let color = sheenColor {
                image = image.tint(tintColor: color)
            }
            let sheenImageView = UIImageView(image: image)
            let height = bounds.height
            let width: CGFloat =  height * sheenWidth.rawValue
            sheenImageView.frame = CGRect(x: -width, y: 0, width: width, height: height)
            self.sheenImageView = sheenImageView
        }
        
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
        
        let previousTransform = sheenImageView.transform
        
        UIView.animate(withDuration: duration, animations: {
            self.addSubview(sheenImageView)
            sheenImageView.transform = sheenImageView.transform.translatedBy(x: self.bounds.width + sheenImageView.frame.width, y: 0)
            AudioEffect.play(self.systemSound, vibrate: self.hapticFeedback)
        }) { _ in
            sheenImageView.removeFromSuperview()
            sheenImageView.transform = previousTransform
            completion(self)
        }
    }
    
}
