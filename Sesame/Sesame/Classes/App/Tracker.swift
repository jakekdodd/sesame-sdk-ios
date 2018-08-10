//
//  Tracker.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation
import CoreData

public class Tracker : NSObject {
    
    public var context: NSManagedObjectContext
    public var actions: [ReportEvent] = []
    
    init(context: NSManagedObjectContext) {
        self.context = context
        super.init()
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ReportEvent")
        do {
            if let actions = try context.fetch(fetchRequest) as? [ReportEvent] {
                self.actions = actions
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    func add(action: String, details: [String: Any]) {
        guard let entity = NSEntityDescription.entity(forEntityName: "ReportEvent", in: context) else { return }
        let event = ReportEvent(entity: entity, insertInto: context)
        event.actionName = action
        
        do {
            try context.save()
            actions.append(event)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        saveContext()
        
        print("Tracker count:\(actions.count)")
    }
    
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
                print()
            } catch {
                let nserror = error as NSError
                Logger.debug(error: "Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
