//
//  Sesame.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation

public class Sesame : NSObject {
    let appId: String
    let appVersionId: String
    let auth: String
    let api: APIClient
    public var config: AppConfig
    public var reinforcer: Reinforcer
    public var tracker: Tracker
    
    init(appId: String, appVersionId: String, auth: String) {
        self.appId = appId
        self.appVersionId = appVersionId
        self.auth = auth
        self.api = APIClient()
        self.config = AppConfig()
        self.reinforcer = Reinforcer()
        self.tracker = Tracker()
        super.init()
    }
}

/* Extend this class to seamlessly plug-in Sesame to your product.
 *
 * Copy and paste your credentials as a swift dictionary.
 * Reinforcements will invoke method *app(_:didReceiveReinforcement:withOptions:)*
 *
 */
open class SesameApplicationDelegate: PluggableApplicationDelegate, SesameApplicationServiceDelegate {
    
    
    // MARK: - Override this dictionary to return your app's credentials
    open var SesameCredentials: [String: Any] {
        get { fatalError("Need to override `SesameCredentials` in SesameApplicationDelegate with your credentials") }
    }
    
    // MARK: - PluggableApplicationDelegate
    // You may ignore this method if no additional plug-ins needed. Plug-ins allow for multiple UIApplicationDelegate objects.
    open override var services: [ApplicationService] {
        var services = super.services
        if let sesameService = SesameApplicationService(args: SesameCredentials, delegate: self) {
            services.append(sesameService)
        }
        return services
    }
    
    // MARK: - SesameApplicationServiceDelegate
    // Override this method to receive reinforcements!
    open func app(_ app: Sesame, didReceiveReinforcement reinforcement: String, withOptions options: [String : Any]?) {
        Logger.debug(confirmed: "Received reinforcement:\(reinforcement) with options:\(options as AnyObject)")
        Logger.debug(error: "The method *app(_:didReceiveReinforcement:withOptions:)* for SesameApplicationDelegate should be overriden.")
    }
    
}
