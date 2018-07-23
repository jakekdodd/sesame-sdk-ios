//
//  ReportEvent.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation

public class ReportEvent : NSObject {
    static let ACTION_APP_OPEN = "appOpen"
    static let ACTION_APP_CLOSE = "appClose"
    static let REINFORCEMENT_NUETRAL = "nuetral"
    let actionName: String
    var details: [String: Any]
    
    init(_ actionName: String, _ details: [String: Any]) { self.actionName = actionName; self.details = details}
}
