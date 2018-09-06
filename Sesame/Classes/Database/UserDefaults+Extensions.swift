//
//  UserDefaults+Extensions.swift
//  Pods-Sesame_Example
//
//  Created by Akash Desai on 9/4/18.
//

import Foundation

extension UserDefaults {
    class var sesame: UserDefaults {
        return UserDefaults(suiteName: Sesame.description()) ?? UserDefaults.standard
    }
}
