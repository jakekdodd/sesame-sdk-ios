//
//  CoreAnimationDelegate.swift
//  Sesame
//
//  Created by Akash Desai on 7/26/18.
//

import Foundation

internal class CoreAnimationDelegate: NSObject, CAAnimationDelegate {
    let willStart: (@escaping()->Void)->Void
    let didStart: (() -> Void)?
    let didStop: (() -> Void)?

    init(willStart: @escaping (@escaping()->Void)->Void = {startAnimation in startAnimation()}, didStart: (() -> Void)? = nil, didStop: (() -> Void)? = nil) {
        self.willStart = willStart
        self.didStart = didStart
        self.didStop = didStop
    }

    func start(view: UIView, animation: CAAnimation) {
        willStart {
            animation.delegate = self
            view.layer.add(animation, forKey: nil)
        }
    }

    func animationDidStart(_ anim: CAAnimation) {
        didStart?()
    }

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            didStop?()
        }
    }
}
