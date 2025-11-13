//
//  Page.swift
//  AidokuRunner
//
//  Created by Skitty on 8/21/23.
//

import Foundation

public typealias PageContext = [String: String]

public struct Page: Sendable, Hashable {
    public var content: PageContent
    /// Optional thumbnail image url for the page
    public var thumbnail: URL?
    public var hasDescription: Bool
    public var description: String?

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

    func codable(store: GlobalStore) -> PageCodable {
        .init(
            content: content.codable(store: store),
            thumbnail: thumbnail,
            hasDescription: hasDescription,
            description: description
        )
    }
}

public enum PageContent: Sendable, Hashable {
    case url(url: URL, context: PageContext? = nil)
    case text(String)
    case image(PlatformImage)
    case zipFile(url: URL, filePath: String)

    func codable(store: GlobalStore) -> PageContentCodable {
        switch self {
            case let .url(url, context):
                .url(url: url, context: context)
            case let .text(string):
                .text(string)
            case let .image(image):
                .image(store.store(image))
            case let .zipFile(url, filePath):
                .zipFile(url: url, filePath: filePath)
        }
    }
}

struct PageCodable: Sendable, Hashable, Codable {
    let content: PageContentCodable
    @URLAsString var thumbnail: URL?
    let hasDescription: Bool
    let description: String?

    func into(store: GlobalStore) -> Page? {
        content.into(store: store).flatMap {
            .init(
                content: $0,
                thumbnail: thumbnail,
                hasDescription: hasDescription,
                description: description
            )
        }
    }
}

enum PageContentCodable: Sendable, Hashable {
    case url(url: URL, context: PageContext? = nil)
    case text(String)
    case image(ImageRef)
    case zipFile(url: URL, filePath: String)

    var storePointer: Int32? {
        switch self {
            case .image(let imageRef): imageRef
            default: nil
        }
    }

    func into(store: GlobalStore) -> PageContent? {
        switch self {
            case let .url(url, context):
                .url(url: url, context: context)
            case let .text(string):
                .text(string)
            case let .image(imageRef):
                if let image = store.fetch(from: imageRef) as? PlatformImage {
                    .image(image)
                } else {
                    nil
                }
            case let .zipFile(url, filePath):
                .zipFile(url: url, filePath: filePath)
        }
    }
}

extension PageContentCodable: Codable {
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
                self = .image(try container.decode(ImageRef.self, forKey: .key))
            case 3:
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
            case let .text(string):
                try container.encode(UInt8(1), forKey: .key)
                try container.encode(string, forKey: .key)
            case let .image(ref):
                try container.encode(UInt8(2), forKey: .key)
                try container.encode(ref, forKey: .key)
            case let .zipFile(url, filePath):
                try container.encode(UInt8(3), forKey: .key)
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
