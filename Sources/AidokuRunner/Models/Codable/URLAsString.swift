//
//  URLAsString.swift
//  AidokuRunner
//
//  Created by Skitty on 4/8/25.
//

import Foundation

@propertyWrapper
public struct URLAsString: Codable, Hashable, Sendable {
    public var wrappedValue: URL?

    public init(wrappedValue: URL?) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let urlString = try container.decode(String?.self)
        self.wrappedValue = urlString.flatMap(URL.init)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if encoder is PostcardEncoding {
            if let wrappedValue {
                try container.encode(UInt8(1))
                try container.encode(wrappedValue.absoluteString)
            } else {
                try container.encode(UInt8(0))
            }
        } else {
            try container.encode(wrappedValue?.absoluteString)
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(wrappedValue)
    }
}
