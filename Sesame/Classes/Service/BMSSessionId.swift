//
//  BMSSessionId.swift
//  Sesame
//
//  Created by Akash Desai on 9/19/18.
//

import Foundation

typealias BMSSessionId = Int64

extension Optional where Wrapped == BMSSessionId {
    static var new: BMSSessionId { return Int64( Date().timeIntervalSince1970 * 1000 ) }
}

extension BMSSessionId {
    func elapsedTime() -> Int64 {
        return BMSSessionId?.new - self
    }
}
