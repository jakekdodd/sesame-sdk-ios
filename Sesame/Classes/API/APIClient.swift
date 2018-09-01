//
//  SesameConfig.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation

class APIClient: HTTPClient {

    enum Endpoint {
        case boot, track, reinforce

        var url: URL {
            switch self {
            case .boot:
                return URL(string: "https://reinforce.boundless.ai/v6/app/boot")!
            case .track:
                return URL(string: "https://reinforce.boundless.ai/v6/app/track")!
            case .reinforce:
                return URL(string: "https://reinforce.boundless.ai/v6/app/boot")!
            }
        }
    }

    func post(endpoint: Endpoint, jsonObject: [String: Any], timeout: TimeInterval = 3.0, completion: @escaping ([String: Any]?) -> Void) -> URLSessionDataTaskProtocol {
        return super.post(url: endpoint.url, jsonObject: jsonObject, timeout: timeout, completion: completion)
    }

    func createPayload(for app: Sesame) -> [String: Any] {
        return [ "clientOS": "iOS",
                 "clientOSVersion": UIDevice.current.systemVersion,
                 "clientSDKVersion": Bundle(for: type(of: app).self).shortVersionString ?? "UNKNOWN",
                 "clientBuild": Bundle.main.shortVersionString ?? "UNKNOWN",

                 "appId": app.appId,
                 "versionId": app.appVersionId,
                 "revision": app.config?.revision ?? 0,
                 "secret": app.auth,
                 "primaryIdentity": app.config?.user?.id ?? app.config?.user?.fallbackId ?? "IDUNAVAILABLE",

                 "utc": NSNumber(value: Int64(Date().timeIntervalSince1970) * 1000),
                 "timezoneOffset": NSNumber(value: Int64(NSTimeZone.default.secondsFromGMT()) * 1000)
        ]
    }

    func reinforce(appVersion: Sesame, completion: (Bool, Cartridge) -> Void) {

    }

}
