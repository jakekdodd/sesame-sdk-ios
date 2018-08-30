//
//  Cartridge.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation

class Cartridge: NSObject {
    static let NeutralCartridgeId = "CLIENT_NEUTRAL"
    static let NeutralReinforcementName = "nuetral"
    let cartridgeId: String
    var decisions: [String]
    static var nuetral: Cartridge {
        return Cartridge(NeutralCartridgeId, [])
    }
    init(_ id: String, _ decisions: [String]) { cartridgeId = id; self.decisions = decisions}

    func removeDecision() -> String {
        guard !decisions.isEmpty else {
            return Cartridge.NeutralReinforcementName
        }
        return decisions.remove(at: 0)
    }
}
