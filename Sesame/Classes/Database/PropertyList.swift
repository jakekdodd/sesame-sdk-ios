//
//  PropertyList.swift
//  Pods-Sesame_Example
//
//  Created by Akash Desai on 10/21/18.
//

import Foundation

public extension Sesame {

    /// Used to read a file `Sesame.plist` in the main bundle.
    /// Includes properties to initialize a Sesame object.
    public struct PropertyList {

        /// Reads `Sesame.plist` and returns a singleton instance
        public static let file: PropertyList = {
            guard let path = Bundle.main.path(forResource: "Sesame", ofType: "plist"),
                let plist = NSDictionary(contentsOfFile: path) as? [String: Any],
                let sesameProperties = PropertyList(dict: plist)
                else { fatalError() }
            return sesameProperties
        }()

        /// The properties as a dictionary
        public let dict: [String: Any]
        public let appId: String
        public let auth: String
        public let versionId: String
        public let userId: String?

        init?(dict: [String: Any]) {
            guard let appId = dict["appId"] as? String, !appId.isEmpty,
                let auth = dict["auth"] as? String, !auth.isEmpty,
                let versionId = dict["versionId"] as? String, !versionId.isEmpty
                else { return nil }
            self.dict = dict
            self.appId = appId
            self.auth = auth
            self.versionId = versionId
            self.userId = dict["userId"] as? String
        }
    }
}
