//
//  Sesame.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation
import CoreData

public protocol SesameEffectDelegate : class {
    
    /// Override this method to receive reinforcements! Set this object as the delegate of the Sesame object from your AppDelegate
    ///
    /// - Parameters:
    ///   - app: The Sesame app
    ///   - reinforcement: A string representing the reinforcement effect configured on the web dashboard
    ///   - options: A dictionary with any additional options configured on the web dashboard
    func app(_ app: Sesame, didReceiveReinforcement reinforcement: String, withOptions options: [String: Any]?)
}

public class Sesame : NSObject {
    
    public var effectDelegate: SesameEffectDelegate? {
        didSet {
            _effect = {_effect}()
        }
    }
    
    /// If the delegate isn't set when an effect is supposed to show, the effect is stored until the delegate is set
    fileprivate var _effect: (String, [String: Any])? {
        didSet {
            if let effect = _effect,
                let effectDelegate = effectDelegate {
                effectDelegate.app(self, didReceiveReinforcement: effect.0, withOptions: effect.1)
                _effect = nil
            }
        }
    }
    
    let appId: String
    let appVersionId: String
    let auth: String
    let api: APIClient
    public var config: AppConfig
    
    public unowned let service: SesameApplicationService
    let coreDataManager: CoreDataManager
    public var reinforcer: Reinforcer
    
    
    init(appId: String, appVersionId: String, auth: String, service: SesameApplicationService) {
        self.appId = appId
        self.appVersionId = appVersionId
        self.auth = auth
        self.api = APIClient()
        self.config = AppConfig()
        self.service = service
        self.coreDataManager = CoreDataManager()
        self.reinforcer = Reinforcer()
        super.init()
    }

    func open() {
        let reinforcement = reinforcer.cartridge.removeDecision()
        _effect = (reinforcement, [:])

        coreDataManager.addEvent(for: "appOpen")
    }

//    func set(userId: String) {
//        User
//    }
    
}
