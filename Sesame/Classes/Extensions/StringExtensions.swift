//
//  StringExtensions.swift
//  Sesame
//
//  Created by Akash Desai on 12/1/17.
//

import Foundation

extension String {
    func jsonDecoded() -> [String: AnyObject]? {
        if let data = data(using: String.Encoding.utf8),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: AnyObject] {
            return json
        }
        return nil
    }
}

public extension NSString {
    @objc
    func utf8Decoded() -> NSString {
        if let data = self.data(using: String.Encoding.utf8.rawValue),
            let str = NSString(data: data, encoding: String.Encoding.nonLossyASCII.rawValue) {
            return str as NSString
        } else {
            return self
        }
    }
}
