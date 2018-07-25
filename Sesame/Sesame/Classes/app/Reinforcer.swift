//
//  Reinforcer.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation

public class Reinforcer : NSObject {
    var cartridge: Cartridge
    var options: [String: [String:Any]]?
    
    init(cartridge: Cartridge = Cartridge.nuetral) {
        self.cartridge = cartridge
    }
}
