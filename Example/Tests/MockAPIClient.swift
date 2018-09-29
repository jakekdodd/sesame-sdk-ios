//
//  MockAPIClient.swift
//  Sesame_Tests
//
//  Created by Akash Desai on 9/28/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
@testable import Sesame

class MockAPIClient: APIClient {
    override func post(url: URL, jsonObject: [String: Any], timeout: TimeInterval, completion: @escaping ([String: Any]?) -> Void) {
        switch url {
        case Endpoint.boot.url:
            completion(MockAPIClient.mockResponse(for: .boot))

        case Endpoint.track.url:
            completion(MockAPIClient.mockResponse(for: .track))

        case Endpoint.refresh.url:
            completion(MockAPIClient.mockResponse(for: .refresh))

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
            response["version"] = [
                "versionID": "sesame2",
                "mappings": [
                    "appOpen": [
                        "actionName": "appOpen",
                        "codeless": [
                            "reinforcements": []
                        ],
                        "manual": [
                            "reinforcements": [
                                "confetti",
                                "sheen",
                                "emojisplosion"
                            ]
                        ]
                    ]
                ],
                "visualizerMappings": []
            ]
            response["config"] = [
                "configID": "4d9cf6d40da638ae28bed8891de5aa3b364a5c3b",
                "trackingCapabilities": [
                    "applicationState": true,
                    "applicationViews": true,
                    "customViews": [
                        "viewName": "viewName"
                    ],
                    "customEvents": [],
                    "notificationObservations": false,
                    "storekitObservations": false,
                    "locationObservations": true,
                    "bluetoothObservations": true
                ],
                "reinforcementEnabled": true,
                "triggerEnabled": false,
                "trackingEnabled": true,
                "consoleLoggingEnabled": true,
                "advertiserID": false,
                "batchSize": [
                    "track": 5,
                    "report": 5
                ],
                "integrationMethod": "codeless"
            ]
            response["status"] = 206

        case .track:
            break

        case .refresh:
            response["cartridgeId"] = "DEVELOPMENT"
            response["serverUtc"] = 1538162488492 as Int64
            response["ttl"] = 86400000 as Int64
            response["actionName"] = "appOpen"
            response["reinforcements"] = [
                ["reinforcementName": "NEUTRAL_RESP"],
                ["reinforcementName": "confetti"],
                ["reinforcementName": "sheen"],
                ["reinforcementName": "emojisplosion"]
            ]

        }
        return response
    }
}
