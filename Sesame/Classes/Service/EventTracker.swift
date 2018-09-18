//
//  EventTracker.swift
//  Sesame
//
//  Created by Akash Desai on 9/13/18.
//

import Foundation

struct BMSMetadata: Collection, Sequence {
    public typealias DictionaryType = [String: Any]
    private var dictionary: DictionaryType

    enum Option: String {
        case IPAddress, language
    }
    var options: [Option: Bool]

    init(_ dict: DictionaryType = DictionaryType(),
         options: [Option: Bool] = [.IPAddress: true,
                                    .language: true]
        ) {
        self.dictionary = dict
        self.options = options
    }

    public var dict: DictionaryType { return dictionary }

    mutating func update() {
        for (option, enabled) in options {
            if enabled {
                dictionary[option.rawValue] = option.getValue()
            } else {
                dictionary.removeValue(forKey: option.rawValue)
            }
        }
    }

}

extension BMSMetadata {

    // MARK: Collection
    public typealias Key = DictionaryType.Key
    public typealias Value = DictionaryType.Value
    public typealias Index = DictionaryType.Index
    public typealias Indices = DictionaryType.Indices
    public typealias Iterator = DictionaryType.Iterator
    public typealias SubSequence = DictionaryType.SubSequence

    public var indices: Indices { return dictionary.indices }
    public var startIndex: Index { return dictionary.startIndex }
    public var endIndex: Index { return dictionary.endIndex }

    public subscript(position: Index) -> Iterator.Element { return dictionary[position] }
    public subscript(bounds: Range<Index>) -> SubSequence { return dictionary[bounds] }
    public subscript(key: Key) -> Value? {
        get { return dictionary[key] }
        set { dictionary[key] = newValue }
    }

    public func index(after i: Index) -> Index {
        return dictionary.index(after: i)
    }

    // MARK: Sequence
    public func makeIterator() -> Iterator {
        return dictionary.makeIterator()
    }
}

extension BMSMetadata.Option {
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
        }
    }
}
