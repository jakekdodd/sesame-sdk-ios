//
//  SesameConfig.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation

public struct SesameAppVersion {
    let appId: String
    let appVersionId: String
    let auth: String
    var config: SesameAppConfig
    internal var reinforcer: Reinforcer
    public var tracker: Tracker
    
    init(appId: String, appVersionId: String, auth: String, config: SesameAppConfig) {
        self.appId = appId
        self.appVersionId = appVersionId
        self.auth = auth
        self.config = config
        self.reinforcer = Reinforcer()
        self.tracker = Tracker()
    }

    func createPayload() -> [String: Any] {
        return [ "clientOS": "iOS",
                 "clientOSVersion": UIDevice.current.systemVersion,
                 "clientSDKVersion": Bundle(for: Sesame.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String,
                 "clientBuild": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String,
                 
                 "appId": appId,
                 "versionId": appVersionId,
                 "revision": config.revision,
                 "secret": auth,
                 "primaryIdentity": "IDUNAVAILABLE",
                 
                 "utc": NSNumber(value: Int64(Date().timeIntervalSince1970) * 1000),
                 "timezoneOffset": NSNumber(value: Int64(NSTimeZone.default.secondsFromGMT()) * 1000)
        ]
    }
    
}

struct SesameAppConfig {
    var revision: Int
    var values: [String: Any]
    
    init(_ revision: Int = 0,
         _ values: [String: Any] = ["tracking": [
        "enabled": true
        ]
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
}

class SesameApi : HTTPClient {
    
    static let BOOT_URL = URL(string:"https://reinforce.boundless.ai/v6/app/boot")!
    
    func boot(appVersion: SesameAppVersion, completion: @escaping (Bool, SesameAppConfig?) -> Void) {
        
        var payload = appVersion.createPayload()
        payload["initialBoot"] = false
        payload["inProduction"] = false
        payload["currentVersion"] = appVersion.appVersionId
        payload["currentConfig"] = "\(appVersion.config.revision)"
        
        post(url: SesameApi.BOOT_URL, jsonObject: payload) { response in
            guard let response = response,
                response["errors"] == nil else {
                    completion(false, nil)
                    return
            }
            
            if let config = response["config"] as? [String: Any] {
                
            }
        }.start()
    }
    
    func reinforce(appVersion: SesameAppVersion, completion: (Bool, Cartridge) -> Void) {
        
    }
    
}
