//
//  Sesame.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation



public class Sesame : NSObject {
    
    // Start service by extending class
    public var service: SesameApplicationService?
    public var app: SesameAppVersion
    internal var api: SesameApi
    
    
    internal static var _instance: Sesame?
    @objc
    public static var shared: Sesame? {
        get {
            return _instance
        }
    }
    
    init(appId: String, appVersionId: String, auth: String) {
        self.app = SesameAppVersion(appId: appId, appVersionId: appVersionId, auth: auth, config: SesameAppConfig())
        self.api = SesameApi()
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
