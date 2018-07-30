//
//  SesameApplicationDelegate.swift
//  Sesame
//
//  Created by Akash Desai on 7/30/18.
//

import Foundation

/* Extend this class to seamlessly plug-in Sesame to your product.
 *
 * Copy and paste your credentials as a swift dictionary.
 * Reinforcements will invoke method *app(_:didReceiveReinforcement:withOptions:)*
 *
 */
open class AppDelegateWithSesame: PluggableApplicationDelegate {
    
    // From a UIViewController or SesameEffectDelegate, set yourself as a delegate to get reinforcement messages
    open var sesame: Sesame?
    
    // MARK: - Override this dictionary to return your app's credentials
    open var SesameCredentials: [String: Any] {
        get { fatalError("Need to override `SesameCredentials` in SesameApplicationDelegate with your credentials") }
    }
    
    // MARK: - PluggableApplicationDelegate
    // You may ignore this method if no additional plug-ins needed. Plug-ins allow for multiple UIApplicationDelegate objects.
    //
    // This method creates both the Sesame app and app service. The Sesame app service is a UIApplicationDelegate that
    // sends messages to the Sesame app for open and close actions, along with the UIApplication lifecycle events.
    open override var services: [ApplicationService] {
        let sesameService = SesameApplicationService.init(args: SesameCredentials)
        
        sesame = sesameService.app
        
        return super.services + [
            sesameService
        ]
    }
    
    // MARK: - SesameApplicationServiceDelegate - Override this method to receive reinforcements!
    open func app(_ app: Sesame, didReceiveReinforcement reinforcement: String, withOptions options: [String : Any]?) {
        Logger.debug(confirmed: "Received reinforcement:\(reinforcement) with options:\(options as AnyObject)")
        Logger.debug(error: "The method *app(_:didReceiveReinforcement:withOptions:)* for SesameApplicationDelegate should be overriden.")
    }
    
}
