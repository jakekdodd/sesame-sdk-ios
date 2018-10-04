//
//  Mock+APIClient.swift
//  Sesame_Tests
//
//  Created by Akash Desai on 9/28/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
@testable import Sesame

class MockAPIClient: APIClient {
    override func post(url: URL, auth: AuthorizationHeader, jsonBody: [String: Any], timeout: TimeInterval, completion: @escaping ([String: Any]?) -> Void) {
        switch url {
        case Endpoint.boot.url:
            completion(MockAPIClient.mockResponse(for: .boot))

        case Endpoint.reinforce.url:
            completion(MockAPIClient.mockResponse(for: .reinforce))

        default:
            completion([:])
        }
    }
}

extension MockAPIClient {
    static func mockResponse(for endpoint: Endpoint, errors: Bool = false) -> [String: Any] {
        guard !errors else {
            return ["errors": ["mock_error"]]
        }
        var response = [String: Any]()
        switch endpoint {
        case .boot:
            response["revision"] = 0
            response["config"] = [
                "tracking": [
                    "enabled": true,
                    "appState": true,
                    "appViews": true
                ],
                "reinforcementEnabled": true,
                "consoleLogging": true,
                "reinforcedActions": [
                    [
                        "id": Mock.aid1,
                        "name": Mock.aname1,
                        "reinforcements": [
                            [
                                "id": Mock.rid1,
                                "name": Mock.rname1,
                                "effects": [
                                    "name": Mock.rname1,
                                    "duration": 2000,
                                    "color": "#ffffffcc",
                                    "aspectRatio": 1.667
                                ]
                            ]
                        ]
                    ]
                ]
            ]

        case .reinforce:
            response["utc"] = Int64(Date().timeIntervalSince1970 * 1000)
            response["cartridges"] = [[
                "ttl": 3600000 as Int64,
                "cartridgeId": Mock.cid1,
                "actionId": Mock.aid1,
                "reinforcements": [
                    ["reinforcementId": Mock.rid1],
                    ["reinforcementId": Mock.rid1]
                ]
            ]]
        }
        return response

    }
}
