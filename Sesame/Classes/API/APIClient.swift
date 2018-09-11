//
//  SesameConfig.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation

class APIClient: HTTPClient {

    enum Endpoint {
        case boot, track, refresh

        var url: URL {
            switch self {
            case .boot:
                return URL(string: "https://reinforce.boundless.ai/v6/app/boot")!
            case .track:
                return URL(string: "https://reinforce.boundless.ai/v6/app/track")!
            case .refresh:
                return URL(string: "https://reinforce.boundless.ai/v6/app/refresh")!
            }
        }
    }

    func post(endpoint: Endpoint, jsonObject: [String: Any], timeout: TimeInterval = 3.0, completion: @escaping ([String: Any]?) -> Void) -> URLSessionDataTaskProtocol {
        return super.post(url: endpoint.url, jsonObject: jsonObject, timeout: timeout, completion: completion)
    }

    func createPayload(appId: String, versionId: String?, secret: String, primaryIdentity: String?) -> [String: Any] {
        var payload = [String: Any]()
        payload = [ "clientOS": "iOS",
                    "clientOSVersion": UIDevice.current.systemVersion,
                    "clientSDKVersion": Bundle(for: APIClient.self).shortVersionString ?? "UNKNOWN",
                    "clientBuild": Bundle.main.shortVersionString ?? "UNKNOWN",
                    "utc": NSNumber(value: Int64(Date().timeIntervalSince1970) * 1000),
                    "timezoneOffset": NSNumber(value: Int64(NSTimeZone.default.secondsFromGMT()) * 1000),
                    "appId": appId,
                    "versionId": versionId ?? "nil",
                    "secret": secret,
                    "primaryIdentity": primaryIdentity ?? "IDUNAVAILABLE"
        ]
        return payload
    }

}
