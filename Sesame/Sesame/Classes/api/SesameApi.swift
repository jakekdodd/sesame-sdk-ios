//
//  SesameConfig.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation

enum SesameAppState {
    case closed, opened, reopened
}

public class SesameAppVersion : NSObject {
    let appId: String
    let appVersionId: String
    let auth: String
    let api: SesameApi
    public var config: SesameAppConfig
    public var reinforcer: Reinforcer
    public var tracker: Tracker
    
    init(appId: String, appVersionId: String, auth: String) {
        self.appId = appId
        self.appVersionId = appVersionId
        self.auth = auth
        self.api = SesameApi()
        self.config = SesameAppConfig()
        self.reinforcer = Reinforcer()
        self.tracker = Tracker()
        super.init()
    }
}

public struct SesameAppConfig {
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
    
    func createPayload(for app: SesameAppVersion) -> [String: Any] {
        return [ "clientOS": "iOS",
                 "clientOSVersion": UIDevice.current.systemVersion,
                 "clientSDKVersion": Bundle(for: type(of: app).self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String,
                 "clientBuild": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String,
                 
                 "appId": app.appId,
                 "versionId": app.appVersionId,
                 "revision": app.config.revision,
                 "secret": app.auth,
                 "primaryIdentity": "IDUNAVAILABLE",
                 
                 "utc": NSNumber(value: Int64(Date().timeIntervalSince1970) * 1000),
                 "timezoneOffset": NSNumber(value: Int64(NSTimeZone.default.secondsFromGMT()) * 1000)
        ]
    }
    
    func boot(app: SesameAppVersion, completion: @escaping (Bool, SesameAppConfig?) -> Void) {
        
        var payload = createPayload(for: app)
        payload["initialBoot"] = false
        payload["inProduction"] = false
        payload["currentVersion"] = app.appVersionId
        payload["currentConfig"] = "\(app.config.revision)"
        
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
