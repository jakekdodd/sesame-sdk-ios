//
//  SesameConfig.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation

struct SesameApiCreds {
    let appId: String
    let secret: String
}

struct SesameApiConfig {
    var versionId: String
    var revision: Int
    
    init(_ versionId: String, _ revision: Int) {
        self.versionId = versionId
        self.revision = revision
    }
}

class SesameApi : NSObject {
    func boot(creds: SesameApiCreds, completion: (Bool, SesameApiConfig?) -> Void) {
        
    }
    
    func reinforce(creds: SesameApiCreds, events: [ReportEvent]?, completion: (Bool, Cartridge) -> Void) {
        
    }
    
}
