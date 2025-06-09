//
//  EpochDate.swift
//  AidokuRunner
//
//  Created by Skitty on 5/11/25.
//

import Foundation

@propertyWrapper
public struct EpochDate: Codable, Hashable, Sendable {
    public var wrappedValue: Date?

    public init(wrappedValue: Date?) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let isSome = try container.decode(UInt8.self) != 0
        if isSome {
            let intValue = try container.decode(Int64.self)
            self.wrappedValue = Date(timeIntervalSince1970: TimeInterval(intValue))
        } else {
            self.wrappedValue = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let wrappedValue {
            try container.encode(UInt8(1))
            try container.encode(Int64(wrappedValue.timeIntervalSince1970))
        } else {
            try container.encode(UInt8(0))
        }
    }
}
