//
//  SesameConfig.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation

class APIClient : HTTPClient {
    
    enum APIClientURL {
        case boot, reinforce
        
        var url: URL {
            switch self {
            case .boot:
                return URL(string:"https://reinforce.boundless.ai/v6/app/boot")!
            case .reinforce:
                return URL(string:"https://reinforce.boundless.ai/v6/app/boot")!
            }
        }
    }
    
    func createPayload(for app: Sesame) -> [String: Any] {
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
    
    func boot(app: Sesame, completion: @escaping (Bool, AppConfig?) -> Void) {
        
        var payload = createPayload(for: app)
        payload["initialBoot"] = false
        payload["inProduction"] = false
        payload["currentVersion"] = app.appVersionId
        payload["currentConfig"] = "\(app.config.revision)"
        
        post(url: APIClientURL.boot.url, jsonObject: payload) { response in
            guard let response = response,
                response["errors"] == nil else {
                    completion(false, nil)
                    return
            }
            
            if let revision = response["revision"] as? Int,
                let configValues = response["config"] as? [String: Any] {
                app.config = AppConfig(revision, configValues)
            }
        }.start()
    }
    
    func reinforce(appVersion: Sesame, completion: (Bool, Cartridge) -> Void) {
        
    }
    
}
