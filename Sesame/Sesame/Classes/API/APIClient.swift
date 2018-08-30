//
//  SesameConfig.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation

class APIClient: HTTPClient {

    enum APIClientURL {
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

    func createPayload(for app: Sesame) -> [String: Any] {
        return [ "clientOS": "iOS",
                 "clientOSVersion": UIDevice.current.systemVersion,
                 "clientSDKVersion": Bundle(for: type(of: app).self).shortVersionString ?? "UNKNOWN",
                 "clientBuild": Bundle.main.shortVersionString ?? "UNKNOWN",

                 "appId": app.appId,
                 "versionId": app.appVersionId,
                 "revision": app.config?.revision ?? 0,
                 "secret": app.auth,
                 "primaryIdentity": app.user?.id ?? "IDUNAVAILABLE",

                 "utc": NSNumber(value: Int64(Date().timeIntervalSince1970) * 1000),
                 "timezoneOffset": NSNumber(value: Int64(NSTimeZone.default.secondsFromGMT()) * 1000)
        ]
    }

    func reinforce(appVersion: Sesame, completion: (Bool, Cartridge) -> Void) {

    }

}
