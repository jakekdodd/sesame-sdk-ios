//
//  UIWindowExtensions.swift
//  Sesame
//
//  Created by Akash Desai on 9/20/18.
//

import Foundation

extension UIWindow {
    class var topWindow: UIWindow? {
        if let window = UIApplication.shared.keyWindow {
            return window
        }
        for window in UIApplication.shared.windows.reversed() {
            if window.windowLevel == UIWindowLevelNormal && !window.isHidden && window.frame != CGRect.zero {
                return window
            }
        }
        return nil
    }
}
