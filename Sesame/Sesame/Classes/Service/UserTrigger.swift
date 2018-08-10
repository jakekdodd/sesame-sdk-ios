//
//  UserTrigger.swift
//  Sesame
//
//  Created by Akash Desai on 8/9/18.
//

import UIKit

public struct UserTrigger {
    
    public enum UserTriggerType {
        case `internal`(InternalTrigger), external(ExternalTrigger), synthetic(SyntheticTrigger)
        
        public enum InternalTrigger {
            case `default`, shortcut
        }
        
        public enum ExternalTrigger {
            case deepLink
        }
        
        public enum SyntheticTrigger {
            case notification
        }
    }
    
    public let type: UserTriggerType
    public let date: Date
    
    init(type: UserTriggerType, date: Date = Date()) {
        self.type = type
        self.date = date
    }
    
}

public extension UserTrigger.UserTriggerType {
    public var description: String {
        switch(self) {
        case .internal(.default):
            return "Internal.default"
        case .internal(.shortcut):
            return "Internal.shortcut"
        case .external(.deepLink):
            return "External.deepLink"
        case .synthetic(.notification):
            return "Synthetic.notification"
        }
    }
}
