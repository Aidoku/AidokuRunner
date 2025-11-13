//
//  Listing.swift
//  AidokuRunner
//
//  Created by Skitty on 8/21/23.
//

import Foundation

public struct Listing: Sendable, Hashable {
    /// Unique identifier for the listing
    public var id: String
    /// Title of the listing
    public var name: String
    /// Type of listing
    public var kind: ListingKind = .default

    public init(id: String, name: String, kind: ListingKind = .default) {
        self.id = id
        self.name = name
        self.kind = kind
    }
}

public enum ListingKind: UInt8, Sendable, Codable {
    case `default`
    case list
}

extension Listing: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = (try? container.decode(String.self, forKey: .name)) ?? id
        kind = (try? container.decode(ListingKind.self, forKey: .kind)) ?? .default
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(kind, forKey: .kind)
    }

    enum CodingKeys: CodingKey {
        case id
        case name
        case kind
    }
}
