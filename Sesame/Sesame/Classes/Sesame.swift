//
//  Sesame.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation



public class Sesame : NSObject {
    internal static var _instance: Sesame?
    internal var service: SesameApplicationService?
    internal var apiCreds: SesameApiCreds
    internal var config: SesameApiConfig
    public var reinforcer: Reinforcer
    public var tracker: Tracker
    
    
    @objc
    public static var shared: Sesame? {
        get {
            return _instance
        }
    }
    
    init(credentials: SesameApiCreds, config: SesameApiConfig) {
        self.apiCreds = credentials
        self.config = config
        self.reinforcer = Reinforcer()
        self.tracker = Tracker()
        super.init()
    }
    
    @objc
    static func configureShared(appId: String, secret: String, versionId: String, revision: Int = 0) {
        _instance = Sesame(
            credentials: SesameApiCreds(appId: appId, secret: secret),
            config: SesameApiConfig.init(versionId, revision)
        )
    }
    
}
