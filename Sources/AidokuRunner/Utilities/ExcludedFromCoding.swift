//
//  ExcludedFromCoding.swift
//  AidokuRunner
//
//  Created by Skitty on 4/8/25.
//

import Foundation

@propertyWrapper
public struct ExcludedFromCoding: Sendable, Codable, Hashable {
    public var wrappedValue: String

    public init(wrappedValue: String) {
        self.wrappedValue = wrappedValue
    }

    public init(from _: Decoder) throws {
        self.wrappedValue = ""
    }

    public func encode(to _: Encoder) throws {
        // do nothing
    }
}
