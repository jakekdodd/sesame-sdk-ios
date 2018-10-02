//
//  SesameConfig.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import UIKit

class APIClient: HTTPClient {

    enum Endpoint {
        case boot, reinforce

        var url: URL {
            switch self {
            case .boot:
//                return URL(string: "https://reinforce.boundless.ai/v6/app/boot")!
                return URL(string: "http://localhost:8080/v1/boot")!
            case .reinforce:
//                return URL(string: "https://reinforce.boundless.ai/v6/app/report")!
                return URL(string: "http://localhost:8080/v1/reinforce")!
            }
        }
    }

    func post(endpoint: Endpoint, jsonObject: [String: Any], timeout: TimeInterval = 3.0, completion: @escaping ([String: Any]?) -> Void) {
        post(url: endpoint.url, jsonObject: jsonObject, timeout: timeout, completion: completion)
    }

    func createPayload(appId: String, secret: String, versionId: String?, revision: Int, primaryIdentity: String? = nil, timestamps: Bool) -> [String: Any] {
        var payload: [String: Any] =
            ["appId": appId,
//             "auth": secret,
             "appVersionId": versionId ?? "nil",
             "revision": revision,
             "device": ["osName": "iOS",
                        "osVersion": UIDevice.current.systemVersion,
                        "buildVersion": Bundle.main.shortVersionString ?? "UNKNOWN",
                        "clientVersion": Bundle(for: APIClient.self).shortVersionString ?? "UNKNOWN"]
        ]
        if let externalId = primaryIdentity {
            payload["externalId"] = externalId
        }
        if timestamps {
            payload["utc"] = NSNumber(value: Int64(Date().timeIntervalSince1970) * 1000)
            payload["timezoneOffset"] = NSNumber(value: Int64(NSTimeZone.default.secondsFromGMT()) * 1000)
        }
        return payload
    }

}
