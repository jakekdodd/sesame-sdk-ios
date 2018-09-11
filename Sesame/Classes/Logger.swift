//
//  Logger.swift
//  Sesame
//
//  Created by Akash Desai on 7/23/18.
//

import Foundation
//
//  BKLog.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/14/18.
//

import Foundation

@objc open class Logger: NSObject {

    @objc public static var level = Level.verbose

    @objc public enum Level: Int, CustomStringConvertible, Comparable {
        case none, error, warning, info, verbose

        public var description: String {
            switch self {
            case .none: return "none"
            case .error: return "error"
            case .warning: return "warning"
            case .info: return "info"
            case .verbose: return "verbose"
            }
        }

        public static func < (lhs: Logger.Level, rhs: Logger.Level) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }

    @objc open class func verbose(_ message: Any, filePath: String = #file, function: String = #function, line: Int = #line) {
        Logger.print(.verbose, message, filePath: filePath, function: function, line: line)
    }

    @objc open class func info(_ message: Any, filePath: String = #file, function: String =  #function, line: Int = #line) {
        Logger.print(.info, message, filePath: filePath, function: function, line: line)
    }

    @objc open class func info(confirmed message: Any, filePath: String = #file, function: String =  #function, line: Int = #line) {
        Logger.print(.info, "✅ \(message)", filePath: filePath, function: function, line: line)
    }

    @objc open class func warning(_ message: Any, filePath: String = #file, function: String =  #function, line: Int = #line) {
        Logger.print(.warning, message, filePath: filePath, function: function, line: line)
    }

    @objc open class func error(_ message: Any, filePath: String = #file, function: String =  #function, line: Int = #line) {
        Logger.print(.error, "❌ \(message)", filePath: filePath, function: function, line: line)
    }

    @objc open class func print(_ logLevel: Level, _ message: Any, filePath: String = #file, function: String =  #function, line: Int = #line) {
        guard logLevel <= level else { return }
        var functionSignature = function
        if let parameterNames = functionSignature.range(of: "\\((.*?)\\)", options: .regularExpression) {
            functionSignature.replaceSubrange(parameterNames, with: "()")
        }
        let fileName = (filePath as NSString).lastPathComponent
        Swift.print("[\(fileName):\(line):\(functionSignature) \(logLevel)] - \(message)")
    }

}
