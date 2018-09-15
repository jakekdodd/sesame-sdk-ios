//
//  OverlayEffectView.swift
//  Sesame
//
//  Created by Akash Desai on 7/29/18.
//

import Foundation

open class OverlayEffectView: UIView {

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    convenience init() {
        self.init(frame: .zero)
    }

    fileprivate func setup() {
        clipsToBounds = true
        isUserInteractionEnabled = false
    }

    @objc
    open func constrainToSuperview() {
        // Adjusts to cover the superview
        guard let superview = superview else {
            print("`superview` was nil – call `addSubview(_ view: UIView)` before calling `\(#function)` to fix this.")
            return
        }
        translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 9.0, *) {
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview.topAnchor),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor),
            leadingAnchor.constraint(equalTo: superview.leadingAnchor)
            ])
        } else {
            frame = superview.bounds
        }
        layoutIfNeeded()
    }

    open func didRotate() {}

    fileprivate var screenIsVertical: Bool = (UIScreen.main.bounds.width < UIScreen.main.bounds.height)
    open override func layoutSubviews() {
        super.layoutSubviews()
        let isVertical = UIScreen.main.bounds.width < UIScreen.main.bounds.height
        if isVertical != screenIsVertical {
            screenIsVertical = isVertical
            didRotate()
         }
    }

    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return false
    }

}
