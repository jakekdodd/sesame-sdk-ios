//
//  UIApplicationExtensions.swift
//  Sesame
//
//  Created by Akash Desai on 9/22/18.
//

import Foundation

extension UIApplication {
    static var sharedIfAvailable: UIApplication? {
        let sharedSelector = NSSelectorFromString("sharedApplication")
        guard UIApplication.responds(to: sharedSelector) else {
            return nil
        }
        return UIApplication.perform(sharedSelector)?.takeUnretainedValue() as? UIApplication
    }
}
