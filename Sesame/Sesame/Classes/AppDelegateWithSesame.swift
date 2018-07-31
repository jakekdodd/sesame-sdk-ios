//
//  SesameApplicationDelegate.swift
//  Sesame
//
//  Created by Akash Desai on 7/30/18.
//

import Foundation

/// Extend this class to seamlessly plug-in Sesame to your product.
///
/// - A subclass should:
///     - Override `SesameCredentials` with credentials from the web dashboard
///     - Have `sesame.effectDelegate` set with a `SesameEffectDelegate`
///
/// A SesameEffectDelegate will receive reinforcements in method *app(_:didReceiveReinforcement:withOptions:)*.
///
/// The suggested implementation is to have a UIViewController implement protocol `SesameEffectDelegate`,
/// and in `viewDidLoad()` set itself as the sesame.effectDelegate via `UIApplication.shared.delegate`.
///
open class AppDelegateWithSesame: PluggableApplicationDelegate {
    
    // MARK: - Set sesame.effectDelegate with a UIViewController
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
        // Create a service to connect Sesame to the UIApplication lifecycle
        let sesameService = SesameApplicationService.init(args: SesameCredentials)
        
        // Keep a reference to Sesame so the delegate can be set later
        sesame = sesameService.app
        
        // Set the AppDelegate if it's also a SesameEffectDelegate
        if let effectDelegate = self as? SesameEffectDelegate {
            sesame?.effectDelegate = effectDelegate
        }
        
        return super.services + [
            sesameService
        ]
    }
    
}
