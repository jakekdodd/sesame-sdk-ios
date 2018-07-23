//
//  SesameConfig.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation

struct SesameApiCreds {
    let appId: String
    let secret: String
    
    let clientOS = "iOS"
    let clientOSVersion = UIDevice.current.systemVersion
    let clientSDKVersion = Bundle(for: Sesame.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    let clientBuild = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    
    func createPayload() -> [String: Any] {
        return [ "clientOS": clientOS,
                 "clientOSVersion": clientOSVersion,
                 "clientSDKVersion": clientSDKVersion,
                 "clientBuild": clientBuild,
                 "primaryIdentity": "IDUNAVAILABLE",
                 "appId": appId,
                 "secret": secret,
                 "utc": NSNumber(value: Int64(Date().timeIntervalSince1970) * 1000),
                 "timezoneOffset": NSNumber(value: Int64(NSTimeZone.default.secondsFromGMT()) * 1000)
        ]
    }
}

struct SesameApiConfig {
    var versionId: String
    var revision: Int
    
    init(_ versionId: String, _ revision: Int) {
        self.versionId = versionId
        self.revision = revision
    }
}

class SesameApi : HTTPClient {
    
    static let BOOT_URL = URL(string:"https://reinforce.boundless.ai/v6/app/boot")!
    
    func boot(creds: SesameApiCreds, currentConfig: SesameApiConfig? = nil, completion: (Bool, SesameApiConfig?) -> Void) {
        
        var payload = creds.createPayload()
        payload["initialBoot"] = false
        payload["inProduction"] = false
        payload["currentVersion"] = currentConfig?.versionId ?? "nil"
        payload["currentConfig"] = currentConfig?.revision != nil ? "\(currentConfig!.revision)" : "nil"
        
        post(url: SesameApi.BOOT_URL, jsonObject: payload) { response in
            
        }.start()
    }
    
    func reinforce(creds: SesameApiCreds, events: [ReportEvent]?, completion: (Bool, Cartridge) -> Void) {
        
    }
    
}
