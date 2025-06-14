//
//  FilterValue.swift
//  AidokuRunner
//
//  Created by Skitty on 10/14/23.
//

import Foundation

enum FilterType: UInt8 {
    case text = 0
    case sort = 1
    case check = 2
    case select = 3
    case multiselect = 4
}

public enum FilterValue: Sendable, Hashable {
    case text(id: String, value: String)
    case sort(SortFilterValue)
    case check(id: String, value: Int)
    case select(id: String, value: String)
    case multiselect(id: String, included: [String], excluded: [String])
}

public extension FilterValue {
    var id: String {
        switch self {
            case let .text(id, _): id
            case let .sort(value): value.id
            case let .check(id, _): id
            case let .select(id, _): id
            case let .multiselect(id, _, _): id
        }
    }
}

public struct SortFilterValue: Sendable, Equatable, Hashable {
    public let id: String
    public let index: Int32
    public let ascending: Bool

    public init(id: String, index: Int, ascending: Bool) {
        self.id = id
        self.index = Int32(index)
        self.ascending = ascending
    }
}

extension FilterValue: Equatable {
    public static func == (lhs: FilterValue, rhs: FilterValue) -> Bool {
        switch lhs {
            case let .text(lhsId, lhsValue):
                if case let .text(rhsId, rhsValue) = rhs {
                    lhsId == rhsId && lhsValue == rhsValue
                } else {
                    false
                }
            case .sort(let lhsValue):
                if case .sort(let rhsValue) = rhs {
                    lhsValue == rhsValue
                } else {
                    false
                }
            case let .check(lhsId, lhsValue):
                if case let .check(rhsId, rhsValue) = rhs {
                    lhsId == rhsId && lhsValue == rhsValue
                } else {
                    false
                }
            case let .select(lhsId, lhsValue):
                if case let .select(rhsId, rhsValue) = rhs {
                    lhsId == rhsId && lhsValue == rhsValue
                } else {
                    false
                }
            case let .multiselect(lhsId, lhsIncluded, lhsExcluded):
                if case let .multiselect(rhsId, rhsIncluded, rhsExcluded) = rhs {
                    lhsId == rhsId && lhsIncluded == rhsIncluded && lhsExcluded == rhsExcluded
                } else {
                    false
                }
        }
    }
}

extension FilterValue: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = FilterType(rawValue: try container.decode(UInt8.self, forKey: .type))
        guard let type else {
            throw DecodingError.invalidType
        }
        switch type {
            case .text:
                let id = try container.decode(String.self, forKey: .id)
                let value = try container.decode(String.self, forKey: .value)
                self = .text(id: id, value: value)
            case .sort:
                let id = try container.decode(String.self, forKey: .id)
                let index = try container.decode(Int32.self, forKey: .index)
                let ascending = try container.decode(Bool.self, forKey: .ascending)
                self = .sort(SortFilterValue(id: id, index: Int(index), ascending: ascending))
            case .check:
                let id = try container.decode(String.self, forKey: .id)
                let value = try container.decode(Int.self, forKey: .value)
                self = .check(id: id, value: value)
            case .select:
                let id = try container.decode(String.self, forKey: .id)
                let value = try container.decode(String.self, forKey: .value)
                self = .select(id: id, value: value)
            case .multiselect:
                let id = try container.decode(String.self, forKey: .id)
                let included = try container.decode([String].self, forKey: .included)
                let excluded = try container.decode([String].self, forKey: .excluded)
                self = .multiselect(id: id, included: included, excluded: excluded)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
            case let .text(id, value):
                try container.encode(FilterType.text.rawValue, forKey: .type)
                try container.encode(id, forKey: .id)
                try container.encode(value, forKey: .value)
            case .sort(let value):
                try container.encode(FilterType.sort.rawValue, forKey: .type)
                try container.encode(value.id, forKey: .id)
                try container.encode(value.index, forKey: .index)
                try container.encode(value.ascending, forKey: .ascending)
            case let .check(id, value):
                try container.encode(FilterType.check.rawValue, forKey: .type)
                try container.encode(id, forKey: .id)
                try container.encode(value, forKey: .value)
            case let .select(id, value):
                try container.encode(FilterType.select.rawValue, forKey: .type)
                try container.encode(id, forKey: .id)
                try container.encode(value, forKey: .value)
            case let .multiselect(id, included, excluded):
                try container.encode(FilterType.multiselect.rawValue, forKey: .type)
                try container.encode(id, forKey: .id)
                try container.encode(included, forKey: .included)
                try container.encode(excluded, forKey: .excluded)
        }
    }

    enum DecodingError: Error {
        case invalidType
    }

    enum CodingKeys: CodingKey {
        case id
        case type
        case index
        case value
        case ascending
        case included
        case excluded
    }
}
