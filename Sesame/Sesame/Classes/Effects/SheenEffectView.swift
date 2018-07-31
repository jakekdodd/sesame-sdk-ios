//
//  SheenEffectView.swift
//  Sesame
//
//  Created by Akash Desai on 7/26/18.
//

import Foundation

@objc
open class SheenEffectView : OverlayEffectView {
    
    public enum SheenWidthToHeightRatio : CGFloat {
        case narrow = 0.333, equal = 1, wide = 1.667
    }
    
    @IBInspectable @objc
    public var duration:Double = 2
    @IBInspectable @objc
    public var delay:Double = 0
    @IBInspectable @objc
    public var sheenImage: UIImage?
    @IBInspectable @objc
    public var sheenWidthToHeightRatio: CGFloat = SheenWidthToHeightRatio.equal.rawValue {
        didSet {
            if sheenImageViewWidthConstraint != nil {
                sheenImageViewWidthConstraint?.isActive = false
                sheenImageViewWidthConstraint = sheenImageView?.widthAnchor.constraint(equalTo: self.heightAnchor, multiplier: sheenWidthToHeightRatio)
                sheenImageViewWidthConstraint?.isActive = true
                setNeedsLayout()
            }
        }
    }
    @IBInspectable @objc
    public var sheenColor: UIColor? = nil
    @IBInspectable @objc
    public var opacityMask: Bool = false
    @IBInspectable @objc
    public var hapticFeedback: Bool = false
    @IBInspectable @objc
    public var systemSound: UInt32 = 0
    
    public var animationOptions: UIViewAnimationOptions = []
    
    fileprivate var sheenImageViewAnimationStartConstraint: NSLayoutConstraint?
    fileprivate var sheenImageViewAnimationEndConstraint: NSLayoutConstraint?
    fileprivate var sheenImageViewWidthConstraint: NSLayoutConstraint?
    fileprivate var sheenImageView: UIImageView?
    
    override open func didRotate() {
        if opacityMask && superview != nil {
            mask = superview?.generateMask()
        }
    }
    
    @objc(start)
    public func objc_start() {
        self.start()
    }
    
    @objc
    open func start(completion: @escaping (Bool) -> Void = {_ in}) {
        if sheenImage == nil,
            let bundle = Bundle.sesame,
            let image = UIImage(named: "sheen", in: bundle, compatibleWith: nil) {
            sheenImage = image
        }
        if sheenImageView == nil && sheenImage != nil {
            if let color = sheenColor {
                sheenImage = sheenImage?.tint(tintColor: color)
            }
            let sheenImageView = UIImageView(image: sheenImage)
            self.sheenImageView = sheenImageView
            
            sheenImageView.isHidden = true
            self.addSubview(sheenImageView)
            
            sheenImageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                sheenImageView.topAnchor.constraint(equalTo: self.topAnchor),
                sheenImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
                ])
            sheenImageViewWidthConstraint = sheenImageView.widthAnchor.constraint(equalTo: self.heightAnchor, multiplier: sheenWidthToHeightRatio)
            sheenImageViewAnimationStartConstraint = sheenImageView.trailingAnchor.constraint(equalTo: leadingAnchor)
            sheenImageViewAnimationEndConstraint = sheenImageView.leadingAnchor.constraint(equalTo: trailingAnchor)
            sheenImageViewWidthConstraint?.isActive = true
            sheenImageViewAnimationEndConstraint?.isActive = false
            sheenImageViewAnimationStartConstraint?.isActive = true
            layoutIfNeeded()
        }
        
        guard let sheenImageView = sheenImageView else {
            Logger.debug(error: "No image set for sheen")
            completion(false)
            return
        }
        guard sheenImageView.isHidden else {
            Logger.debug(error: "Sheen is already animating")
            completion(false)
            return
        }
        
        if opacityMask {
            mask = superview?.generateMask()
        }
        
        setNeedsLayout()
        UIView.animate(withDuration: duration, delay: delay, options: animationOptions, animations: {
            sheenImageView.isHidden = false
            self.sheenImageViewAnimationStartConstraint?.isActive = false
            self.sheenImageViewAnimationEndConstraint?.isActive = true
            self.layoutIfNeeded()
            AudioEffect.play(self.systemSound, vibrate: self.hapticFeedback)
        }) { _ in
            sheenImageView.isHidden = true
            self.sheenImageViewAnimationEndConstraint?.isActive = false
            self.sheenImageViewAnimationStartConstraint?.isActive = true
            self.layoutIfNeeded()
            completion(true)
        }
    }
    
}
