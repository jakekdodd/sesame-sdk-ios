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
    
    public enum AppOpenSource {
        case homescreen
        case background
        case deeplink
        case notification
        case spotlight
    }
    public var appOpenSource: AppOpenSource?
    
    enum SesameAppState {
        case closed, opened
    }
    
    var refractoryDuration: TimeInterval = 2
    fileprivate (set) var lastAppOpen: Date? = nil
    fileprivate (set) var appState: SesameAppState = .closed {
        didSet {
            didSet(oldValue: oldValue, appState: appState)
        }
    }
    public var app: Sesame?
    
    public convenience init(args: [String: Any]) {
        self.init()
        
        if let appId = args["appId"] as? String,
            let appVersionId = args["appVersionId"] as? String,
            let auth = args["auth"] as? String {
            app = Sesame(appId: appId, appVersionId: appVersionId, auth: auth, service: self)
        }
    }
    
    
    var didAskPermission = false
}


// MARK: - UIApplicationDelegate
extension SesameApplicationService : ApplicationService {
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        Logger.debug("Sesame service app did launch")
        Logger.debug(confirmed: "Application state:\(UIApplication.shared.applicationState.rawValue)")
        testRegister()
        
        appState = .opened
        
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
    
    // MARK: - Notifications
    
    public func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        
    }
    
    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        appOpenSource = .notification
    }
    
    // MARK: - Deep Links
    
//    public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
//        Logger.debug("Sesame service app open url for universal link")
//        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
//            let url = userActivity.webpageURL {
//            print("User activity webpage:\(url.absoluteString)")
//        }
//        return false
//    }
    
    public func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        Logger.debug("Sesame service app open url for deep link")
        appOpenSource = .deeplink
        return true
    }
    
    
    public func applicationDidBecomeActive(_ application: UIApplication) {
        Logger.debug("Sesame service app did become active")
        Logger.debug(confirmed: "Application state:\(UIApplication.shared.applicationState.rawValue)")


        if !didAskPermission {
              UNUserNotificationCenter.current().askPermission()
        }
    }
//
//    public func applicationWillResignActive(_ application: UIApplication) {
//        Logger.debug("Sesame service app will resign active")
//        Logger.debug(confirmed: "Application state:\(UIApplication.shared.applicationState.rawValue)")
//    }
    
    
    
    
    public func applicationWillEnterForeground(_ application: UIApplication) {
        Logger.debug("Sesame service app will enter foreground")
        Logger.debug(confirmed: "Application state:\(UIApplication.shared.applicationState.rawValue)")
        
        appState = .opened
    }
    
    public func applicationDidEnterBackground(_ application: UIApplication) {
        Logger.debug("Sesame service app did enter background")
        Logger.debug(confirmed: "Application state:\(UIApplication.shared.applicationState.rawValue)")
        
        appState = .closed
    }
    
    fileprivate func didSet(oldValue: SesameAppState, appState: SesameAppState) {
        Logger.debug("App state changed from \(oldValue) to \(appState)")
        
        switch (oldValue, appState) {
        case (.closed, .opened):
            self.lastAppOpen = Date()
            app?.open()
            
        case (.opened, .opened):
            let now = Date()
            if let lastOpened = lastAppOpen,
                lastOpened.timeIntervalSince(now) > refractoryDuration
            {
                self.lastAppOpen = Date()
                app?.open()
            } else {
                Logger.debug("App reopened too soon for another reinforcement")
            }
            
        case (.opened, .closed):
            self.lastAppOpen = nil
            self.appOpenSource = nil
            
        case (.closed, .closed):
            break
        }
    }
    
    public func applicationWillTerminate(_ application: UIApplication) {
        Logger.debug("Sesame service app will terminate")
        Logger.debug(confirmed: "Application state:\(UIApplication.shared.applicationState.rawValue)")
    }
}

extension SesameApplicationService {
    func testRegister() {
        let activityIcon = UIApplicationShortcutIcon(templateImageName: "Alert Icon")
        let activityShortcutItem = UIApplicationShortcutItem(type: "alert", localizedTitle: "Recent Activity", localizedSubtitle: nil, icon: activityIcon, userInfo: nil)
        let messageIcon = UIApplicationShortcutIcon(templateImageName: "Messenger Icon")
        let messageShortcutItem = UIApplicationShortcutItem(type: "messages", localizedTitle: "Messages", localizedSubtitle: nil, icon: messageIcon, userInfo: nil)
        UIApplication.shared.shortcutItems = [activityShortcutItem, messageShortcutItem]
    }
}

public extension UNUserNotificationCenter {
    
    func scheduleNotification(identifier: String, body: String, time: Double) {
        let content =  UNMutableNotificationContent()
        content.body = body
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: time, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { (error) in
            if (error != nil) {
                print(error!)
            } else {
                print("Success! ID:\(identifier), Message:\(body), Time:\(trigger.timeInterval.magnitude) seconds")
            }
        }
    }
    
    func askPermission(completionHandler: @escaping (Bool, Error?) -> Void = {_, _ in}) {
        requestAuthorization(options: [.alert, .sound], completionHandler: completionHandler)
    }
}
