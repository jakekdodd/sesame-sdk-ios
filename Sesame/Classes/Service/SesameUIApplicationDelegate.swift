//
//  SesameUIApplicationDelegate.swift
//
//  Created by Akash Desai on 8/20/18.
//

import UIKit
import UserNotifications

open class SesameUIApplicationDelegate: NSObject {

    /// A reference to the Sesame object to send updates. Not to confuse with UIApplication app.
    weak var app: Sesame?

    fileprivate(set) var appOpenAction: AppOpenAction? {
        didSet {
            app?.receive(appOpenAction: appOpenAction)
        }
    }

    public override init() {
        super.init()
    }

}

// MARK: - UIApplicationDelegate

extension SesameUIApplicationDelegate: UIApplicationDelegate {

    // MARK: - Initial App Open

    @discardableResult
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]? = nil) -> Bool {
        // The user could have launched the app for many reasons.
        // We catch what we can here, and the rest in other methods related to the UIApplication lifecycle
        if launchOptions?[.sourceApplication] != nil ||
            launchOptions?[.url]  != nil {

            appOpenAction = AppOpenAction(source: .deepLink)

        } else if launchOptions?[.remoteNotification] != nil ||
            launchOptions?[.localNotification] != nil {

            appOpenAction = AppOpenAction(source: .notification)

        } else if #available(iOS 9.0, *),
            launchOptions?[.shortcutItem] != nil {

            appOpenAction = AppOpenAction(source: .shortcut)

        }

        return true
    }

    // MARK: - App Open from Shortcut

    @available(iOS 9.0, *)
    public func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        // When a user opens your app from a shortcut
        if appOpenAction == nil {
            appOpenAction = AppOpenAction(source: .shortcut)
        }
    }

    // MARK: - App Open from Deep Link

    @discardableResult
    public func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any] = [:]) -> Bool {
        // When a user clicks a deep link that opens your app
        if appOpenAction == nil {
            appOpenAction = AppOpenAction(source: .deepLink)
        }
        return true
    }

    // MARK: - App Open from Notifications

    // MARK: Notifications for iOS >= 10.0
    @available(iOS 10.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // When the user opens your app from clicking a notification
        if appOpenAction == nil {
            appOpenAction = AppOpenAction(source: .notification)
        }
    }

    // MARK: Notifications for iOS < 10.0
    @available(iOS, deprecated: 10.0)
    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // When the user opens your app from clicking a remote notification
        if appOpenAction == nil {
            appOpenAction = AppOpenAction(source: .notification)
        }
    }

    @available(iOS, deprecated: 10.0)
    public func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        // When the user opens your app from clicking a local notification
        if appOpenAction == nil {
            appOpenAction = AppOpenAction(source: .notification)
        }
    }

    // MARK: - App Open for Default

    public func applicationDidBecomeActive(_ application: UIApplication) {
        // If none of the other app open actions have been set,
        // then the user must've tapped open the app from
        // Spotlight, Springboard, or from the App Switcher which are all internal cues
        if appOpenAction == nil {
            appOpenAction = AppOpenAction(source: .default)
        }
    }

    // MARK: - App Close

    public func applicationDidEnterBackground(_ application: UIApplication) {
        // Clear the action so a new one can be set
        appOpenAction = nil
    }

}
