//
//  Sesame.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation



public class Sesame : NSObject {
    internal static var _instance: Sesame?
    internal var service: SesameApplicationService?
    
    public var tracker: Tracker
    
    
    @objc
    public static var shared: Sesame? {
        get {
            return _instance
        }
    }
    
    override init() {
        self.tracker = Tracker()
        super.init()
    }
    
    @objc
    static func configureShared() {
        _instance = Sesame(
            )
    }
    
}
