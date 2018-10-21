//
//  PropertyList.swift
//  Pods-Sesame_Example
//
//  Created by Akash Desai on 10/21/18.
//

import Foundation

public extension Sesame {
    public struct PropertyList {
        public static let file: PropertyList = {
            guard let path = Bundle.main.path(forResource: "Sesame", ofType: "plist"),
                let plist = NSDictionary(contentsOfFile: path) as? [String: Any],
                let sesameProperties = PropertyList(dict: plist)
                else { fatalError() }
            return sesameProperties
        }()

        public let raw: [String: Any]
        public let appId: String
        public let auth: String
        public let versionId: String
        public let userId: String

        init?(dict: [String: Any]) {
            guard let appId = dict["appId"] as? String, !appId.isEmpty,
                let auth = dict["auth"] as? String, !auth.isEmpty,
                let versionId = dict["versionId"] as? String, !versionId.isEmpty,
                let userId = dict["userId"] as? String, !userId.isEmpty
                else { return nil }
            self.raw = dict
            self.appId = appId
            self.auth = auth
            self.versionId = versionId
            self.userId = userId
        }
    }
}
