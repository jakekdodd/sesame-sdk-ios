//
//  SesameApplicationService.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation
import CoreData

public protocol SesameApplicationServiceDelegate : class {
    func app(_ app: Sesame, didReceiveReinforcement reinforcement: String, withOptions options: [String: Any]?)
}

final public class SesameApplicationService : NSObject, ApplicationService {
    
    public static var shared: SesameApplicationService?
    public var app: Sesame
    public weak var delegate: SesameApplicationServiceDelegate?
    
    
    enum SesameAppState {
        case closed, opened
    }
    
    var lastOpened: Date? = nil
    var appState: SesameAppState = .closed {
        didSet {
            Logger.debug("App state changed from \(oldValue) to \(appState)")
            let reinforce = {
                let reinforcement = self.app.reinforcer.cartridge.removeDecision()
                self.delegate?.app(self.app, didReceiveReinforcement: reinforcement, withOptions: self.app.reinforcer.options?[reinforcement])
            }
            
            switch (oldValue, appState) {
            case (.closed, .opened):
                self.lastOpened = Date()
                app.tracker.add(action: "appOpen", details: [:])
                print("Action count:\(app.tracker.actions.count)")
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
    
    public convenience init?(args: [String: Any], delegate: SesameApplicationServiceDelegate? = nil) {
        guard let appId = args["appId"] as? String,
            let appVersionId = args["appVersionId"] as? String,
            let auth = args["auth"] as? String else {
                return nil
        }
        self.init(appId: appId, appVersionId: appVersionId, auth: auth, delegate: delegate)
    }
    
    init(appId: String, appVersionId: String, auth: String, delegate: SesameApplicationServiceDelegate?) {
        self.app = Sesame(appId: appId, appVersionId: appVersionId, auth: auth)
        self.delegate = delegate
        super.init()
    }
    
    /// MARK: protocol ApplicationService UIApplicationDelegate
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        
        app.tracker.context = persistentContainer.viewContext
        Logger.debug("Sesame service app did launch")
        
        appState = .opened
        
//        app.tracker.actions.append(ReportEvent.init(ReportEvent.ACTION_APP_OPEN, [String : Any]()))
//        app.api.boot(app: app) { (success, newConfig) in
//            guard success else {
//                Logger.debug(error: "Boot call failed.")
//                return
//            }
//            if let newConfig = newConfig {
//                self.app.config = newConfig
//            }
//        }
        return true
    }
    
    public func applicationWillEnterForeground(_ application: UIApplication) {
        Logger.debug("Sesame service app will enter foreground")
        
        appState = .opened
    }
    
    public func applicationDidEnterBackground(_ application: UIApplication) {
        Logger.debug("Sesame service app did enter background")
        
        appState = .closed
    }
    
    // MARK: - Core Data Container Mangement
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let modelURL = Bundle(for: type(of: self)).url(forResource: "Sesame", withExtension: "momd")!
        let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)
        let container = NSPersistentContainer(name: "Sesame", managedObjectModel: managedObjectModel!)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            print("Store description:\(storeDescription)")
        })
        return container
    }()
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
