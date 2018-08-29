//
//  SesameConfig.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation

class APIClient : HTTPClient {
    
    enum APIClientURL {
        case boot, track, reinforce
        
        var url: URL {
            switch self {
            case .boot:
                return URL(string:"https://reinforce.boundless.ai/v6/app/boot")!
            case .track:
                return URL(string:"https://reinforce.boundless.ai/v6/app/track")!
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

    func track(app: Sesame, completion: @escaping (Bool) -> Void) {
        var payload = createPayload(for: app)
        payload["versionId"] = app.appVersionId
        payload["tracks"] = {
            var tracks = [[String: Any]]()
            if let reports = app.coreDataManager.reports() {
                for case let report in reports {
                    guard let reportEvents = report.events else { continue }

                    var track = [String: Any]()
                    track["actionName"] = report.actionId
                    track["type"] = "NON_REINFORCEABLE"
                    var events = [[String: Any]]()
                    for case let reportEvent as Event in reportEvents {
                        var event = [String: Any]()
                        event["utc"] = reportEvent.utc
                        event["timezoneOffset"] = reportEvent.timezoneOffset
                        event["metadata"] = reportEvent.metadata?.jsonDecoded()
                        events.append(event)
                    }
                    track["events"] = events

                    tracks.append(track)
                }
            }
            return tracks
        }()

        post(url: APIClientURL.track.url, jsonObject: payload) { response in
            guard let response = response,
                response["errors"] == nil else {
                    completion(false)
                    return
            }
            completion(true)
            }.start()
    }
    
}
