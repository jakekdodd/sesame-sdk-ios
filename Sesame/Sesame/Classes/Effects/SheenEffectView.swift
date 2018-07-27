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
    
    @objc
    open func constrainToSuperview() {
        guard let superview = superview else {
            Logger.debug(error: "`superview` was nil – call `addSubview(_ view: UIView)` before calling `\(#function)` to fix this.")
            return
        }
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview.topAnchor),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor),
            leadingAnchor.constraint(equalTo: superview.leadingAnchor),
                                     ])
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
    
    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return false
    }
}

public extension SheenEffectView {
    @objc(start)
    public func objc_start() {
        self.start()
    }
}
