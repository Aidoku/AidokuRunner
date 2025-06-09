//
//  Filter.swift
//  AidokuRunner
//
//  Created by Skitty on 10/6/23.
//

import Foundation

public struct Filter: Sendable, Hashable {
    public let id: String
    public let title: String?
    public let hideFromHeader: Bool?
    public let value: Value

    public enum Value: Sendable, Hashable {
        case text(placeholder: String?)
        case sort(
            canAscend: Bool,
            options: [String],
            defaultValue: SortDefault?
        )
        case check(
            name: String?,
            canExclude: Bool,
            defaultValue: Bool?
        )
        case select(
            isGenre: Bool = false,
            usesTagStyle: Bool,
            options: [String],
            defaultValue: Int?
        )
        case multiselect(MultiSelectFilter)
        case note(String)
    }

    public struct SortDefault: Sendable, Codable, Hashable {
        public let index: Int
        public let ascending: Bool

        public init(index: Int, ascending: Bool) {
            self.index = index
            self.ascending = ascending
        }
    }

    public init(
        id: String,
        title: String? = nil,
        hideFromHeader: Bool? = nil,
        value: Value
    ) {
        self.id = id
        self.title = title
        self.hideFromHeader = hideFromHeader
        self.value = value
    }
}

extension Filter: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decodeIfPresent(String.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        hideFromHeader = try container.decodeIfPresent(Bool.self, forKey: .hideFromHeader)
        let type = try container.decode(String.self, forKey: .type)
        self.id = id ?? title ?? type
        switch type {
            case "text":
                let placeholder = try container.decodeIfPresent(String.self, forKey: .placeholder)
                value = .text(placeholder: placeholder)
            case "sort":
                let canAscend = try container.decodeIfPresent(Bool.self, forKey: .canAscend) ?? true
                let options = try container.decode([String].self, forKey: .options)
                let defaultValue = try container.decodeIfPresent(SortDefault.self, forKey: .defaultValue)
                value = .sort(canAscend: canAscend, options: options, defaultValue: defaultValue)
            case "check":
                let name = try container.decodeIfPresent(String.self, forKey: .name)
                let canExclude = try container.decodeIfPresent(Bool.self, forKey: .canExclude) ?? false
                let defaultValue = try container.decodeIfPresent(Bool.self, forKey: .defaultValue)
                value = .check(name: name, canExclude: canExclude, defaultValue: defaultValue)
            case "select":
                let isGenre = try container.decodeIfPresent(Bool.self, forKey: .isGenre) ?? false
                let usesTagStyle = try container.decodeIfPresent(Bool.self, forKey: .usesTagStyle) ?? isGenre
                let options = try container.decode([String].self, forKey: .options)
                let defaultValue = try container.decodeIfPresent(Int.self, forKey: .defaultValue)
                value = .select(
                    isGenre: isGenre,
                    usesTagStyle: usesTagStyle,
                    options: options,
                    defaultValue: defaultValue
                )
            case "multi-select":
                value = .multiselect(try MultiSelectFilter(from: decoder))
            case "note":
                value = .note(try container.decode(String.self, forKey: .text))
            default:
                throw DecodingError.dataCorruptedError(
                    forKey: .type,
                    in: container,
                    debugDescription: "Invalid type"
                )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(hideFromHeader, forKey: .hideFromHeader)
        switch value {
            case .text(let placeholder):
                try container.encode("text", forKey: .type)
                try container.encodeIfPresent(placeholder, forKey: .placeholder)
            case let .sort(canAscend, options, defaultValue):
                try container.encode("sort", forKey: .type)
                try container.encodeIfPresent(canAscend, forKey: .canAscend)
                try container.encode(options, forKey: .options)
                try container.encode(defaultValue, forKey: .defaultValue)
            case let .check(name, canExclude, defaultValue):
                try container.encode("check", forKey: .type)
                try container.encodeIfPresent(name, forKey: .name)
                try container.encodeIfPresent(canExclude, forKey: .canExclude)
                try container.encodeIfPresent(defaultValue, forKey: .defaultValue)
            case let .select(isGenre, usesTagStyle, options, defaultValue):
                try container.encode("select", forKey: .type)
                try container.encodeIfPresent(isGenre, forKey: .isGenre)
                try container.encodeIfPresent(usesTagStyle, forKey: .usesTagStyle)
                try container.encode(options, forKey: .options)
                try container.encodeIfPresent(defaultValue, forKey: .defaultValue)
            case .multiselect(let filter):
                try container.encode("multi-select", forKey: .type)
                try filter.encode(to: encoder)
            case .note(let note):
                try container.encode("note", forKey: .type)
                try container.encode(note, forKey: .text)
        }
    }

    enum CodingKeys: String, CodingKey {
        case type
        case id
        case title
        case hideFromHeader

        case placeholder
        case canAscend
        case options
        case defaultValue = "default"
        case isGenre
        case canExclude
        case usesTagStyle
        case ids
        case text
        case name
    }
}

public struct MultiSelectFilter: Sendable, Hashable {
    public let isGenre: Bool
    public let canExclude: Bool
    public var usesTagStyle: Bool
    public let options: [String]
    public let ids: [String]?
    public let defaultIncluded: [String]?
    public let defaultExcluded: [String]?

    public init(
        isGenre: Bool = false,
        canExclude: Bool = false,
        usesTagStyle: Bool? = nil,
        options: [String],
        ids: [String]? = nil,
        defaultIncluded: [String]? = nil,
        defaultExcluded: [String]? = nil
    ) {
        self.isGenre = isGenre
        self.canExclude = canExclude
        self.usesTagStyle = usesTagStyle ?? isGenre
        self.options = options
        self.ids = ids
        self.defaultIncluded = defaultIncluded
        self.defaultExcluded = defaultExcluded
    }
}

extension MultiSelectFilter: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isGenre = try container.decodeIfPresent(Bool.self, forKey: .isGenre) ?? false
        canExclude = try container.decodeIfPresent(Bool.self, forKey: .canExclude) ?? false
        usesTagStyle = try container.decodeIfPresent(Bool.self, forKey: .usesTagStyle) ?? isGenre
        options = try container.decode([String].self, forKey: .options)
        ids = try container.decodeIfPresent([String].self, forKey: .ids)
        defaultIncluded = try container.decodeIfPresent([String].self, forKey: .defaultIncluded)
        defaultExcluded = try container.decodeIfPresent([String].self, forKey: .defaultExcluded)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isGenre, forKey: .isGenre)
        try container.encode(canExclude, forKey: .canExclude)
        try container.encode(usesTagStyle, forKey: .usesTagStyle)
        try container.encode(options, forKey: .options)
        try container.encode(ids, forKey: .ids)
        try container.encode(defaultIncluded, forKey: .defaultIncluded)
        try container.encode(defaultExcluded, forKey: .defaultExcluded)
    }

    enum CodingKeys: String, CodingKey {
        case isGenre
        case canExclude
        case usesTagStyle
        case options
        case ids
        case defaultIncluded
        case defaultExcluded
    }
}
