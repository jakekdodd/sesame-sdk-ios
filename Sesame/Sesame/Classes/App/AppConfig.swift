//
//  AppConfig.swift
//  Sesame
//
//  Created by Akash Desai on 7/24/18.
//

import Foundation

public struct AppConfig {
    var revision: Int
    var values: [String: Any]
    
    init(_ revision: Int = 0,
         _ values: [String: Any] = ["tracking": [ "enabled": true,
                                                  "appState": true],
                                    "reinforcementEnabled": true,
                                    "reinforcedActions": [[String:Any]]()
        ]) {
        self.revision = revision
        self.values = values
    }
    
    init?(_ dict: [String: Any]) {
        var dict = dict
        guard let revision = dict.removeValue(forKey: "revision") as? Int else {
            return nil
        }
        self.init(revision, dict)
    }
    
    var tracking: [String: Any] {
        get {
            return values["tracking"] as? [String: Any] ?? [:]
        }
        set {
            values["tracking"] = newValue
        }
    }
    
    var trackingEnabled: Bool {
        get {
            return tracking["enabled"] as? Bool ?? false
        }
        set {
            tracking["enabled"] = newValue
        }
    }
    
    var reinforcedActions: [[String: Any]] {
        get {
            return values["reinforcedActions"] as? [[String: Any]] ?? [[:]]
        }
        set {
            values["reinforcedActions"] = newValue
        }
    }
    
    var reinforcementEnabled: Bool {
        get {
            return values["reinforcementEnabled"] as? Bool ?? false
        }
        set {
            values["reinforcementEnabled"] = newValue
        }
    }
}
