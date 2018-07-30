//
//  Tracker.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation
import CoreData

public class Tracker : NSObject {
    
    public var context: NSManagedObjectContext?
    public var actions: [ReportEvent]
    
    init(actions: [ReportEvent] = []) {
        self.actions = actions
        super.init()
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ReportEvent")
        do {
            if let actions = try context?.fetch(fetchRequest) as? [ReportEvent] {
                self.actions = actions
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    func add(action: String, details: [String: Any]) {
        guard let managedContext = context else {
            return
        }
        
        let entity = NSEntityDescription.entity(forEntityName: "ReportEvent",
                                                in: managedContext)!
        let event = ReportEvent(entity: entity,
                                     insertInto: managedContext)
        event.actionName = action
        
        do {
            try managedContext.save()
            actions.append(event)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        saveContext()
    }
//
//    func save(name: String) {
//        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
//            return
//        }
//
//        let managedContext = appDelegate.persistentContainer.viewContext
//
//        let entity = NSEntityDescription.entity(forEntityName: "Person",
//                                                in: managedContext)!
//
//        let person = NSManagedObject(entity: entity,
//                                     insertInto: managedContext)
//
//        person.setValue(name, forKeyPath: "name")
//
//        do {
//            try managedContext.save()
//            people.append(person)
//        } catch let error as NSError {
//            print("Could not save. \(error), \(error.userInfo)")
//        }
//    }
    func saveContext() {
//        
//        let context = persistentContainer.viewContext
//        if context.hasChanges {
//            do {
//                try context.save()
//            } catch {
//                let nserror = error as NSError
//                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
//            }
//        }
    }
}
