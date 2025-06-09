//
//  Page.swift
//  AidokuRunner
//
//  Created by Skitty on 8/21/23.
//

import Foundation

public typealias PageContext = [String: String]

public struct Page: Sendable, Hashable, Codable {
    public let content: PageContent
    /// Optional thumbnail image url for the page
    @URLAsString public var thumbnail: URL?
    public let hasDescription: Bool
    public let description: String?

    public init(
        content: PageContent,
        thumbnail: URL? = nil,
        hasDescription: Bool = false,
        description: String? = nil
    ) {
        self.content = content
        self.thumbnail = thumbnail
        self.hasDescription = hasDescription
        self.description = description
    }
}

public enum PageContent: Sendable, Hashable {
    case url(url: URL, context: PageContext? = nil)
    case text(String)
    case zipFile(url: URL, filePath: String)
}

extension PageContent: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(UInt8.self, forKey: .key)
        switch type {
            case 0:
                guard let url = URL(string: try container.decode(String.self, forKey: .key))
                else { throw DecodingError.invalidUrl }
                let hasContext = try container.decode(UInt8.self, forKey: .key) == 1
                let context: PageContext? = try {
                    if hasContext {
                        var context = PageContext()
                        let count = try container.decode(UInt64.self, forKey: .key)
                        for _ in 0..<count {
                            let key = try container.decode(String.self, forKey: .key)
                            let value = try container.decode(String.self, forKey: .key)
                            context[key] = value
                        }
                        return context
                    } else {
                        return nil
                    }
                }()
                self = .url(url: url, context: context)
            case 1:
                self = .text(try container.decode(String.self, forKey: .key))
            case 2:
                guard let url = URL(string: try container.decode(String.self, forKey: .key))
                else { throw DecodingError.invalidUrl }
                let filePath = try container.decode(String.self, forKey: .key)
                self = .zipFile(url: url, filePath: filePath)
            default:
                throw DecodingError.invalidContent
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
            case let .url(url, context):
                try container.encode(UInt8(0), forKey: .key)
                try container.encode(url.absoluteString, forKey: .key)
                if let context {
                    try container.encode(UInt8(1), forKey: .key)
                    try container.encode(UInt64(context.count), forKey: .key)
                    for (key, value) in context {
                        try container.encode(key, forKey: .key)
                        try container.encode(value, forKey: .key)
                    }
                } else {
                    try container.encode(UInt8(0), forKey: .key)
                }
            case .text(let string):
                try container.encode(UInt8(1), forKey: .key)
                try container.encode(string, forKey: .key)
            case let .zipFile(url, filePath):
                try container.encode(UInt8(2), forKey: .key)
                try container.encode(url.absoluteString, forKey: .key)
                try container.encode(filePath, forKey: .key)
        }
    }

    enum DecodingError: Error {
        case invalidContent
        case invalidUrl
    }

    enum CodingKeys: CodingKey {
        case type
        case key
    }
}
