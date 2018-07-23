//
//  Tracker.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation

public class Tracker : NSObject {
    public var actions: [ReportEvent]
    
    init(actions: [ReportEvent] = []) { self.actions = actions }
}
