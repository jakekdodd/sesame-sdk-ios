//
//  BMSApplicationLifecycleTracker.swift
//  Sesame
//
//  Created by Akash Desai on 9/13/18.
//

import Foundation

open class BMSAppLifecycleTracker: NSObject {

    weak var sesame: Sesame?

    fileprivate(set) var appOpenAction: BMSEventAppOpen? {
        didSet {
            guard let newValue = appOpenAction else { return }
            sesame?.reinforce(appOpenEvent: newValue)
        }
    }

    override init() {
        super.init()
        setupNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func setupNotifications() {
        for notification in [Notification.Name.UIApplicationWillTerminate,
                             .UIApplicationDidBecomeActive,
                             .UIApplicationDidEnterBackground] {
                                NotificationCenter.default.addObserver(self,
                                                                       selector: #selector(receive(_:)),
                                                                       name: notification,
                                                                       object: nil)
        }
    }

    @objc func receive(_ notification: Notification) {
        switch notification.name {
        case .UIApplicationWillTerminate:
            didTerminate()
        case .UIApplicationDidBecomeActive:
            didBecomeActive()
        case .UIApplicationDidEnterBackground:
            didEnterBackground()
        default:
            break
        }
    }
}

// MARK: - Tracked Events

extension BMSAppLifecycleTracker {

    // MARK: - UIApplicationDidFinishLaunching

    @objc
    public func didLaunch(_ launchOptions: [UIApplicationLaunchOptionsKey: Any]? = nil) {
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
    }

    // MARK: - UIApplicationDidEnterBackground

    @objc
    public func didEnterBackground() {
        appOpenAction = nil
    }
}
