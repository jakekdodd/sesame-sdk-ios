//
//  BMSApplicationLifecycleTracker.swift
//  Sesame
//
//  Created by Akash Desai on 9/13/18.
//

import UIKit

open class BMSAppLifecycleTracker: NSObject {

    weak var sesame: Sesame?
    public var isRegisteredForNotification = false {
        didSet (wasRegisteredForNotification) {
            switch (wasRegisteredForNotification, isRegisteredForNotification) {
            case (false, true): registerNotifications()
            case (true, false): unregisterNotifications()
            default: break
            }
        }
    }

    fileprivate var appOpenAction: BMSEventAppOpen? {
        willSet {
            if appOpenAction != nil {
                sesame?.sessionId = nil
            }
        }
        didSet {
            if let appOpenAction = appOpenAction {
                sesame?.sessionId = .new
                sesame?.reinforce(appOpenEvent: appOpenAction)
            }
        }
    }

    fileprivate var appIsInterrupted = false {
        didSet (appWasInterrupted) {
            switch (appWasInterrupted, appIsInterrupted) {
            case (false, true): sesame?.addEvent(actionName: BMSEvent.SessionInterruptionStartName)
            case (true, false): sesame?.addEvent(actionName: BMSEvent.SessionInterruptionEndName)
            default: break
            }
        }
    }

    public var notificationsToRegister = [
        UIApplication.willTerminateNotification,
        UIApplication.didBecomeActiveNotification,
        UIApplication.willResignActiveNotification,
        UIApplication.didEnterBackgroundNotification
    ]

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func registerNotifications() {
        for notification in notificationsToRegister { //swiftlint:disable:next line_length
            NotificationCenter.default.addObserver(self, selector: #selector(receive(_:)), name: notification, object: nil)
        }
        isRegisteredForNotification = true
        BMSLog.info("did register for notifications")
    }

    func unregisterNotifications() {
        for notification in notificationsToRegister {
            NotificationCenter.default.removeObserver(self, name: notification, object: nil)
        }
        isRegisteredForNotification = false
        BMSLog.info("did unregister for notifications")
    }

    @objc func receive(_ notification: Notification) {
        BMSLog.verbose("Got notification:\(notification.name)")
        switch notification.name {
        case UIApplication.willTerminateNotification:       didTerminate()
        case UIApplication.didBecomeActiveNotification:     didBecomeActive()
        case UIApplication.willResignActiveNotification:    willResignActive()
        case UIApplication.didEnterBackgroundNotification:  didEnterBackground()
        default: break
        }
    }
}

// MARK: - Tracked Events

extension BMSAppLifecycleTracker {

    // MARK: - UIApplicationDidFinishLaunching

    /// Optional: This method can be called to make the Sesame effect behave differently
    /// depending on how the app was opened.
    /// It is optional because if appOpenAction is not created here, it will be created
    /// when receiving the UIApplicationDidBecomeActive notification.
    ///
    /// - Parameter launchOptions: launchOptions
    @objc
    public func didLaunch(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) {
        sesame?.sendBoot()

        if #available(iOS 9.0, *), launchOptions?[.shortcutItem] != nil {
            didPerformShortcut()
        } else if launchOptions?[.sourceApplication] != nil || launchOptions?[.url]  != nil {
            didOpenURL()
        } else if launchOptions?[.remoteNotification] != nil || launchOptions?[.localNotification] != nil {
            didReceiveNotification()
        }
    }

    // MARK: App Open from Shortcut

    @objc
    public func didPerformShortcut() {
        if appOpenAction == nil {
            appOpenAction = BMSEventAppOpen(source: .shortcut)
        }
    }

    // MARK: App Open from Deep Link

    @objc
    public func didOpenURL() {
        if appOpenAction == nil {
            appOpenAction = BMSEventAppOpen(source: .deepLink)
        }
    }

    // MARK: App Open from Notifications

    @objc
    public func didReceiveNotification() {
        if appOpenAction == nil {
            appOpenAction = BMSEventAppOpen(source: .notification)
        }
    }

    // MARK: - UIApplicationWillTerminate

    @objc
    public func didTerminate() {
        appOpenAction = nil
    }

    // MARK: - UIApplicationDidBecomeActive

    @objc
    public func didBecomeActive() {
        if appOpenAction == nil {
            appOpenAction = BMSEventAppOpen(source: .default)
        }
        appIsInterrupted = false
    }

    // MARK: - UIApplicationWillResignActive

    @objc
    public func willResignActive() {
        appIsInterrupted = true
    }

    // MARK: - UIApplicationDidEnterBackground

    @objc
    public func didEnterBackground() {
        appOpenAction = nil
    }
}
