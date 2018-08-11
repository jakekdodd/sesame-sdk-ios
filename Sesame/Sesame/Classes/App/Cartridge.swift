//
//  Cartridge.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation

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
            return Report.REINFORCEMENT_NUETRAL
        }
        return decisions.remove(at: 0)
    }
}
