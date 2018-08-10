//
//  SesameApplicationService.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation
import CoreData
import UserNotifications

final public class SesameApplicationService : NSObject {
    
    public var app: Sesame?
    fileprivate (set) public var trigger: UserTrigger? {
        didSet {
            if oldValue == nil,
                let trigger = trigger {
                switch trigger {
                default:
                    app?.open()
                }
            }
        }
    }
    
    public convenience init(args: [String: Any]) {
        self.init()
        
        if let appId = args["appId"] as? String,
            let appVersionId = args["appVersionId"] as? String,
            let auth = args["auth"] as? String {
            app = Sesame(appId: appId, appVersionId: appVersionId, auth: auth, service: self)
        }
    }
}


// MARK: - UIApplicationDelegate
extension SesameApplicationService : ApplicationService {
    
    // MARK: - Launch
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        Logger.debug("Sesame service app did launch")
        Logger.debug(confirmed: "Application state:\(UIApplication.shared.applicationState.rawValue)")
        if #available(iOS 9.0, *), launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] != nil {
            trigger = UserTrigger(type: .internal(.shortcut))
        } else if launchOptions?[UIApplicationLaunchOptionsKey.sourceApplication] != nil || launchOptions?[UIApplicationLaunchOptionsKey.url] != nil {
            // Even if you decide to return false for this method and not handle the url, the user was still triggered by a deep link and so should be marked as such
            trigger = UserTrigger(type: .external(.deepLink))
        } else if launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] != nil || launchOptions?[UIApplicationLaunchOptionsKey.localNotification] != nil {
            trigger = UserTrigger(type: .synthetic(.notification))
        }
        
        //        app.tracker.actions.append(ReportEvent.init(ReportEvent.ACTION_APP_OPEN, [String : Any]()))
        //        app.api.boot(app: app) { (success, newConfig) in
        //            guard success else {
        //                Logger.debug(error: "Boot call failed.")
        //                return
        //            }
        //            if let newConfig = newConfig {
        //                self.app.config = newConfig
        //            }
        //        }
        return true
    }
    
    
    // MARK: - App Open from Shortcut
    
    @available(iOS 9.0, *)
    public func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        if trigger == nil {
            trigger = UserTrigger(type: .internal(.shortcut))
        }
    }
    
    // MARK: - App Open from Deep Link
    
    public func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        if trigger == nil {
            trigger = UserTrigger(type: .external(.deepLink))
        }
        return true
    }
    
    // MARK: - App Open from Notifications
    
    // MARK: Notifications for iOS >= 10.0
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if trigger == nil {
            trigger = UserTrigger(type: .synthetic(.notification))
        }
    }
    
    // MARK: Notifications for iOS < 10.0
    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if trigger == nil {
            trigger = UserTrigger(type: .synthetic(.notification))
        }
    }
    
    @available(iOS, obsoleted: 10.0)
    public func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        if trigger == nil {
            trigger = UserTrigger(type: .synthetic(.notification))
        }
    }
    
    // MARK: - App Open for Default
    
    public func applicationDidBecomeActive(_ application: UIApplication) {
        // If none of the other trigger types have been set, then the user must've tapped open the app from Spotlight, Springboard, or from the App Switcher which are all internal triggers
        if trigger == nil {
            trigger = UserTrigger(type: .internal(.default))
        }
    }
    
    // MARK: - App Close
    
    public func applicationDidEnterBackground(_ application: UIApplication) {
        // Clear the trigger so a new one can be set
        trigger = nil
        
        // custom implementation
        
    }
    
}
