//
//  ApplicationLifecycleTracker.swift
//  Sesame
//
//  Created by Akash Desai on 9/13/18.
//

import Foundation

class ApplicationLifecycleTracker: NSObject {

    weak var sesame: Sesame?

    override init() {
        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(test(_:)),
                                               name: NSNotification.Name.UIApplicationDidFinishLaunching,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(test(_:)),
                                               name: NSNotification.Name.UIApplicationWillTerminate,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(test(_:)),
                                               name: NSNotification.Name.UIApplicationDidBecomeActive,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(test(_:)),
                                               name: NSNotification.Name.UIApplicationWillResignActive,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(test(_:)),
                                               name: NSNotification.Name.UIApplicationWillEnterForeground,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(test(_:)),
                                               name: NSNotification.Name.UIApplicationDidEnterBackground,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func test(_ notification: Notification) {
        sesame?.addEvent(actionName: notification.name.rawValue)
        let context = sesame!.coreDataManager.newContext()
        sesame?.sendTracks(context: context, userId: sesame!.getUserId(context)!)
    }
}
