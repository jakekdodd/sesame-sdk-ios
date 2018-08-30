//
//  UIWindowExtensions.swift
//  BoundlessKit
//
//  Created by Akash Desai on 12/1/17.
//

import Foundation

internal extension UIWindow {

    class var topWindow: UIWindow? {
        if let window = UIApplication.shared.keyWindow {
            return window
        }
        for window in UIApplication.shared.windows.reversed()
            where window.windowLevel == UIWindowLevelNormal &&
                !window.isHidden &&
                window.frame != CGRect.zero {
                return window
            }
        return nil
    }

    static func presentTopLevelAlert(alertController: UIAlertController, completion:(() -> Void)? = nil) {
        DispatchQueue.main.async {
            let alertWindow = UIWindow(frame: UIScreen.main.bounds)
            alertWindow.rootViewController = UIViewController()
            alertWindow.windowLevel = UIWindowLevelAlert + 1
            alertWindow.makeKeyAndVisible()
            alertWindow.rootViewController?.present(alertController, animated: true, completion: completion)
        }
    }

}
