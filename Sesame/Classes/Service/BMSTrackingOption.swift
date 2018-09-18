//
//  BMSTrackingOption.swift
//  Sesame
//
//  Created by Akash Desai on 9/13/18.
//

import Foundation
import CoreTelephony

public typealias BMSTrackingOptions = [BMSTrackingOption]

public extension Array where Element == BMSTrackingOption {
    static var `default`: BMSTrackingOptions {
        return [.carrier, .deviceModel, .language, .country]
    }

    func annotate(_ dict: inout [String: Any]) {
        for option in self {
            dict[option.rawValue] = option.getValue()
        }
    }
}

public enum BMSTrackingOption: String {
    case carrier, deviceModel, language, country

    func getValue() -> Any? {
        switch self {
        case .carrier:
            return CTTelephonyNetworkInfo().subscriberCellularProvider?.carrierName ?? "unknown"

        case .deviceModel:
            return UIDevice.modelName

        case .language:
            return NSLocale.preferredLanguages.first ?? "unknown"

        case .country:
            return (Locale.current as NSLocale).object(forKey: .countryCode) as? String ?? "unknown"
        }
    }
}
