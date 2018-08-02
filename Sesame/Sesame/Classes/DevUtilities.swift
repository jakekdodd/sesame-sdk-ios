//
//  Dev.swift
//  Pods-Sesame_Example
//
//  Created by Akash Desai on 8/1/18.
//

import UserNotifications

public extension UIApplicationShortcutItem {
    public static func registerDynamicItems() {
        UIApplication.shared.shortcutItems = [
            UIApplicationShortcutItem(
                type: "alert",
                localizedTitle: "Recent Activity",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(templateImageName: "Alert Icon"),
                userInfo: nil
            ), UIApplicationShortcutItem(
                type: "messages",
                localizedTitle: "Messages",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(templateImageName: "Messenger Icon"),
                userInfo: nil)
        ]
    }
}

public extension UNUserNotificationCenter {
    public func scheduleNotification(identifier: String, body: String, time: Double) {
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
    
    public func askPermission(completionHandler: @escaping (Bool, Error?) -> Void = {_, _ in}) {
        requestAuthorization(options: [.alert, .sound], completionHandler: completionHandler)
    }
}
