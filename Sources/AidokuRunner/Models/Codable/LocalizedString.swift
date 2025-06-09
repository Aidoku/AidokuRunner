//
//  LocalizedString.swift
//  AidokuRunner
//
//  Created by Skitty on 3/26/24.
//

import Foundation

/// String that can be decoded from a single string or dictionary of string localizations
public enum LocalizedString {
    case single(String)
    case localized([String: String])

    func localized() -> String {
        switch self {
            case .single(let string):
                return string
            case .localized(let dictionary):
                let id = Locale.current.identifier
                if let string = dictionary[id] {
                    return string
                } else {
                    return dictionary["default"] ?? ""
                }
        }
    }
}

extension LocalizedString: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self = .single(string)
        } else if let dictionary = try? container.decode([String: String].self) {
            self = .localized(dictionary)
        } else {
            throw DecodingError.invalidType
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
            case .single(let string):
                try container.encode(string)
            case .localized(let dictionary):
                try container.encode(dictionary)
        }
    }

    enum DecodingError: Error {
        case invalidType
    }
}
