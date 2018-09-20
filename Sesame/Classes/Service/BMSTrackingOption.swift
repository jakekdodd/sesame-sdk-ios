//
//  BMSTrackingOption.swift
//  Sesame
//
//  Created by Akash Desai on 9/13/18.
//

import Foundation

public typealias BMSTrackingOptions = [BMSTrackingOption]

public extension Array where Element == BMSTrackingOption {

    static var `default`: BMSTrackingOptions {
        return [.carrier, .deviceModel, .language, .country]
    }

    func annotate(_ dict: inout [String: Any]) {
        for option in self {
            dict[option.key] = option.getValue()
        }
    }

}

@objc
public enum BMSTrackingOption: Int {
    case carrier, deviceModel, language, country

    var key: String {
        switch self {
        case .carrier: return "carrier"
        case .deviceModel: return "deviceModel"
        case .language: return "language"
        case .country: return "country"
        }
    }

    func getValue() -> Any? {
        switch self {
        case .carrier:
            return UIDevice.carrier ?? "unknown"

        case .deviceModel:
            return UIDevice.modelName

        case .language:
            return NSLocale.preferredLanguages.first ?? "unknown"

        case .country:
            return (Locale.current as NSLocale).object(forKey: .countryCode) as? String ?? "unknown"
        }
    }
}
