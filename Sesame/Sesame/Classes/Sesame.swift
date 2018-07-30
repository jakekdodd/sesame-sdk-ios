//
//  Sesame.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation
import CoreData


public protocol SesameEffectDelegate : class {
    func app(_ app: Sesame, didReceiveReinforcement reinforcement: String, withOptions options: [String: Any]?)
}

public class Sesame : NSObject {
    
    public var delegate: SesameEffectDelegate?
    
    let appId: String
    let appVersionId: String
    let auth: String
    let api: APIClient
    public var config: AppConfig
    
    unowned let service: SesameApplicationService
    let coreDataManager: CoreDataManager
    public var reinforcer: Reinforcer
    public var tracker: Tracker
    
    var lastOpened: Date? = nil
    var appState: SesameAppState = .closed {
        didSet {
            didSet(oldValue: oldValue, appState: appState)
        }
    }
    
    init(appId: String, appVersionId: String, auth: String, service: SesameApplicationService) {
        self.appId = appId
        self.appVersionId = appVersionId
        self.auth = auth
        self.api = APIClient()
        self.config = AppConfig()
        self.service = service
        let coreDataManager = CoreDataManager()
        self.coreDataManager = coreDataManager
        self.reinforcer = Reinforcer()
        self.tracker = Tracker(context: coreDataManager.persistentContainer.viewContext)
        super.init()
    }
}

// MARK: - App State
extension Sesame {
    enum SesameAppState {
        case closed, opened
    }
    
    fileprivate func didSet(oldValue: SesameAppState, appState: SesameAppState) {
        Logger.debug("App state changed from \(oldValue) to \(appState)")
        let reinforce = {
            let reinforcement = self.reinforcer.cartridge.removeDecision()
            self.delegate?.app(self, didReceiveReinforcement: reinforcement, withOptions: self.reinforcer.options?[reinforcement])
        }
        
        switch (oldValue, appState) {
        case (.closed, .opened):
            self.lastOpened = Date()
            tracker.add(action: "appOpen", details: [:])
            print("Action count:\(tracker.actions.count)")
            reinforce()
            
        case (.opened, .opened):
            let now = Date()
            if let lastOpened = lastOpened,
                lastOpened.timeIntervalSince(now) > 2
            {
                reinforce()
                self.lastOpened = Date()
            } else {
                Logger.debug("App reopened too soon for another reinforcement")
            }
            
        case (.opened, .closed):
            self.lastOpened = nil
            
        default:
            break
        }
    }
}
