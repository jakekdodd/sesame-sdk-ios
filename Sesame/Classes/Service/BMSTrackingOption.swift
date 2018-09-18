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
        return [.IPAddress, .language, .model]
    }

    func annotate(_ dict: inout [String: Any]) {
        for option in self {
            dict[option.rawValue] = option.getValue()
        }
    }
}

public enum BMSTrackingOption: String {
    case IPAddress, language, model

    func getValue() -> Any? {
        switch self {
        case .IPAddress:
            var address: String?
            var ifaddr: UnsafeMutablePointer<ifaddrs>?
            if getifaddrs(&ifaddr) == 0 {
                defer { freeifaddrs(ifaddr) }
                var ptr = ifaddr
                while ptr != nil {
                    defer { ptr = ptr?.pointee.ifa_next }

                    if let interface = ptr?.pointee {
                        let addrFamily = interface.ifa_addr.pointee.sa_family
                        if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6),
                            let name = interface.ifa_name,
                            String(cString: name) == "en0",
                            let addr = interface.ifa_addr {
                            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                            getnameinfo(addr,
                                        socklen_t(addr.pointee.sa_len),
                                        &hostname,
                                        socklen_t(hostname.count),
                                        nil,
                                        socklen_t(0),
                                        NI_NUMERICHOST)
                            address = String(cString: hostname)
                        }
                    }
                }
            }
            return address

        case .language:
            return NSLocale.preferredLanguages.first

        case .model:
            return UIDevice.modelName
        }
    }
}