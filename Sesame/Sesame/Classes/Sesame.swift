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
    internal var app: SesameAppVersion
    internal var api: SesameApi
    public var reinforcer: Reinforcer
    public var tracker: Tracker
    
    
    @objc
    public static var shared: Sesame? {
        get {
            return _instance
        }
    }
    
    init(appId: String, appVersionId: String, auth: String) {
        self.app = SesameAppVersion(appId: appId, appVersionId: appVersionId, auth: auth, config: SesameAppConfig())
        self.api = SesameApi()
        self.reinforcer = Reinforcer()
        self.tracker = Tracker()
        super.init()
    }
    
    @objc
    static func createShared(appId: String, appVersionId: String, auth: String) {
        _instance = Sesame(
            appId: appId, appVersionId: appVersionId, auth: auth
        )
    }
    
    @objc
    func boot() {
        api.boot(appVersion: app) { (success, config) in
            guard success else {
                Logger.debug("Boot failed")
                return
            }
        }
    }
    
}
