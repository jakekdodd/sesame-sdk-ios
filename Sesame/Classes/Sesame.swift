
import CoreData
class Sesame : NSObject {
    
    internal static var _instance: Sesame?
    internal var apiCreds: ApiCredentials
    internal var config: SesameConfig
    public var reinforcer: Reinforcer
    public var tracker: Tracker
    
    @objc
    static var shared: Sesame? {
        get {
            return _instance
        }
    }
    
    init(credentials: ApiCredentials, config: SesameConfig) {
        self.apiCreds = credentials
        self.config = config
        self.reinforcer = Reinforcer()
        self.tracker = Tracker()
        super.init()
    }
    
    @objc
    static func configureShared(appId: String, secret: String, versionId: String, revision: Int = 0) {
        _instance = Sesame(
            credentials: ApiCredentials(appId: appId, secret: secret),
            config: SesameConfig.init(versionId, revision)
        )
    }
}

struct SesameConfig {
    var versionId: String
    var revision: Int
    
    init(_ versionId: String, _ revision: Int) {self.versionId = versionId; self.revision = revision}
}

class Reinforcer : NSObject {
    var cartridge: Cartridge
    
    init(cartridge: Cartridge = Cartridge.nuetral) {
        self.cartridge = cartridge
    }
}

class Tracker : NSObject {
    var actions: [ReportEvent]
    
    init(actions: [ReportEvent] = []) { self.actions = actions }
}

class Cartridge : NSObject {
    static let NUETRAL_CARTRIDGE_ID = "CLIENT_NEUTRAL"
    let cartridgeId: String
    var decisions: [String]
    static var nuetral: Cartridge {
        return Cartridge(NUETRAL_CARTRIDGE_ID, [])
    }
    init(_ id: String, _ decisions: [String]) { cartridgeId = id; self.decisions = decisions}
    
    func removeDecision() -> String {
        guard !decisions.isEmpty else {
            return ReportEvent.REINFORCEMENT_NUETRAL
        }
        return decisions.remove(at: 0)
    }
}


class SesameApi : NSObject {
    func boot(creds: ApiCredentials, completion: (Bool, SesameConfig?) -> Void) { }
    func reinforce(creds: ApiCredentials, events: [ReportEvent]?, completion: (Bool, Cartridge) -> Void) { }
}

protocol Report {
    var actionId: String { get }
}

//class Report : NSObject {
//    enum ReportType : String {
//        case reinforceable = "REINFORCEABLE", nonreinforceable = "NON_REINFORCEABLE"
//    }
//    let actionId: String
//    let reportType: ReportType
//    let cartir
//
//}

class ReportEvent : NSObject {
    static let ACTION_APP_OPEN = "appOpen"
    static let ACTION_APP_CLOSE = "appClose"
    static let REINFORCEMENT_NUETRAL = "nuetral"
    let actionName: String
    var details: [String: Any]
    
    init(_ actionName: String, _ details: [String: Any]) { self.actionName = actionName; self.details = details}
}

struct ApiCredentials {
    let appId: String
    let secret: String
}

open class AppOpenDetector {
    var delegate: SesameApplicationDelegate?
    
    func didDetectOpen() {
        if let sesame = Sesame.shared {
            let reinforcementDecision = sesame.reinforcer.cartridge.removeDecision()
            delegate?.needsReinforcement(reinforcement: reinforcementDecision)
        }
    }
}

//@available(iOS 10.0, *)
//public extension SesameAppDelegate {
//    var persistentContainer: NSPersistentContainer {
//        let container = NSPersistentContainer(name: "CoredataDemo")
//        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
//            if let error = error as NSError? {
//                fatalError("Unresolved error \(error), \(error.userInfo)")
//            }
//        })
//        return container
//    }
//}
