//
//  BMSIntegrationState+CoreDataClass.swift
//  
//
//  Created by Akash Desai on 9/26/18.
//
//

import Foundation
import CoreData

@objc(BMSAppState)
class BMSAppState: NSManagedObject {

    public static var shared: BMSAppState? {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        if let entity = NSEntityDescription.entity(forEntityName: BMSAppState.description(), in: context) {
            return BMSAppState(entity: entity, insertInto: context)
        } else {
            return nil
        }
    }

}

extension BMSAppState {

    class func fetch(context: NSManagedObjectContext, configId: String?, appId: String? = nil, auth: String? = nil, createIfNotFound: Bool = true) -> BMSAppState? {
        var value: BMSAppState?
        context.performAndWait {
            let request = NSFetchRequest<BMSAppState>(entityName: BMSAppState.description())
            request.predicate = NSPredicate(format: "\(#keyPath(BMSAppState.configId)) == \(configId.predicateValue)")
            request.fetchLimit = 1
            do {
                if let appState = try context.fetch(request).first {
                    value = appState
                } else if createIfNotFound,
                    let appStateEntity = NSEntityDescription.entity(forEntityName: BMSAppState.description(), in: context) {
                    let appState = BMSAppState(entity: appStateEntity, insertInto: context)
                    appState.configId = configId
                    appState.appId = appId
                    appState.auth = auth
                    value = appState
                    try context.save()
                }
            } catch let error as NSError {
                BMSLog.error("Could not fetch or insert. \(error)")
            }
        }

        return value
    }
//
//    //swiftlint:disable:next cyclomatic_complexity function_body_length
//    public func sendBoot(api: APIClient, completion: @escaping (Bool) -> Void = {_ in}) {
//        guard let context = managedObjectContext else { return }
//        context.performAndWait {
//            guard let appId = appId,
//                let auth = auth
//                else { return }
//            var payload = api.createPayload(appId: appId,
//                                            versionId: versionId,
//                                            secret: auth,
//                                            primaryIdentity: user?.id)
//            payload["initialBoot"] = false
//            payload["inProduction"] = false
//            payload["currentVersion"] = versionId
//            payload["currentConfig"] = "\(revision)"
//
//            api.post(endpoint: .boot, jsonObject: payload) { response in
//                guard let response = response,
//                    response["errors"] == nil else {
//                        completion(false)
//                        return
//                }
//                context.performAndWait {
//                    if let configValues = response["config"] as? [String: Any] {
//                        if let configId = configValues["configId"] as? String {
//                            self.configId = configId
//                        }
//                        if let trackingEnabled = configValues["trackingEnabled"] as? Bool {
//                            self.trackingEnabled = trackingEnabled
//                        }
//                    }
//
//                    if let version = response["version"] as? [String: Any] {
//                        if let versionId = version["versionID"] as? String {
//                            self.versionId = versionId
//                        }
//                        if let userId = self.user?.id,
//                            let mappings = version["mappings"] as? [String: [String: Any]] {
//                            for (actionName, effectDetails) in mappings {
//                                if let cartridge = BMSCartridge.fetch(context: context,
//                                                                      userId: userId,
//                                                                      actionName: actionName) {
//                                    cartridge.effectDetailsAsDictionary = effectDetails
//                                } else {
//                                    BMSCartridge.insert(context: context,
//                                                        userId: userId,
//                                                        actionName: actionName,
//                                                        effectDetails: effectDetails)
//                                }
//                            }
//                        }
//                    }
//                    do {
//                        if context.hasChanges {
//                            try context.save()
//                        }
//                    } catch {
//                        BMSLog.error(error)
//                    }
//                }
//                completion(true)
//            }
//        }
//    }
}
