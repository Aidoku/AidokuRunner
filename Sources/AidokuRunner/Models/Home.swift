//
//  Home.swift
//  AidokuRunner
//
//  Created by Skitty on 8/24/23.
//

import Foundation

public struct Home: Sendable, Codable, Hashable {
    public var components: [HomeComponent]

    public init(components: [HomeComponent]) {
        self.components = components
    }
}

extension Home {
    mutating func setSourceKey(_ sourceKey: String) {
        for i in 0..<components.count {
            components[i].setSourceKey(sourceKey)
        }
    }
}

// MARK: - Home Component

public struct HomeComponent: Sendable, Codable, Hashable {
    public var title: String?
    public var subtitle: String?
    public var value: Value

    public enum Value: Sendable, Codable, Hashable {
        case imageScroller(
            links: [Link],
            autoScrollInterval: TimeInterval? = nil,
            width: Int? = nil,
            height: Int? = nil
        )
        case bigScroller(
            entries: [Manga],
            autoScrollInterval: TimeInterval? = nil
        )
        case scroller(
            entries: [Link],
            listing: Listing? = nil
        )
        case mangaList(
            ranking: Bool = false,
            pageSize: Int? = nil,
            entries: [Link],
            listing: Listing? = nil
        )
        case mangaChapterList(
            pageSize: Int? = nil,
            entries: [MangaWithChapter],
            listing: Listing? = nil
        )
        case filters([FilterItem])
        case links([Link])

        public var intValue: Int {
            switch self {
                case .imageScroller: 0
                case .bigScroller: 1
                case .scroller: 2
                case .mangaList: 3
                case .mangaChapterList: 4
                case .filters: 5
                case .links: 6
            }
        }

        public struct FilterItem: Sendable, Codable, Hashable {
            public var title: String
            public var values: [FilterValue]?

            public init(title: String, values: [FilterValue]?) {
                self.title = title
                self.values = values
            }
        }

        public struct Link: Codable, Hashable, Sendable {
            public var title: String
            public var subtitle: String?
            public var imageUrl: String?
            public var value: LinkValue?

            public init(
                title: String,
                imageUrl: String? = nil,
                subtitle: String? = nil,
                value: LinkValue? = nil
            ) {
                self.title = title
                self.imageUrl = imageUrl
                self.subtitle = subtitle
                self.value = value
            }

            mutating func setSourceKey(_ sourceKey: String) {
                self.value = switch value {
                    case .manga(let manga):
                        .manga({
                            var newManga = manga
                            newManga.sourceKey = sourceKey
                            return newManga
                        }())
                    default:
                        self.value
                }
            }
        }

        public enum LinkValue: Codable, Hashable, Sendable {
            case url(String)
            case listing(Listing)
            case manga(Manga)

            public init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let type = try container.decode(UInt8.self, forKey: .key)
                switch type {
                    case 0:
                        let value = try container.decode(String.self, forKey: .key)
                        self = .url(value)
                    case 1:
                        let value = try container.decode(Listing.self, forKey: .key)
                        self = .listing(value)
                    case 2:
                        let value = try container.decode(Manga.self, forKey: .key)
                        self = .manga(value)
                    default:
                        throw DecodingError.dataCorruptedError(
                            forKey: .key,
                            in: container,
                            debugDescription: "Invalid type"
                        )
                }
            }

            public func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                switch self {
                    case let .url(value):
                        try container.encode(UInt8(0), forKey: .key)
                        try container.encode(value, forKey: .key)
                    case let .listing(value):
                        try container.encode(UInt8(1), forKey: .key)
                        try container.encode(value, forKey: .key)
                    case let .manga(value):
                        try container.encode(UInt8(2), forKey: .key)
                        try container.encode(value, forKey: .key)
                }
            }

            enum CodingKeys: CodingKey {
                case key
            }
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: HomeComponent.Value.CodingKeys.self)
            try container.encode(UInt8(intValue), forKey: .key)
            switch self {
                case let .imageScroller(links, autoScrollInterval, width, height):
                    try container.encode(links, forKey: .key)
                    try container.encodeIfPresent(autoScrollInterval.flatMap(Float.init), forKey: .key)
                    try container.encodeIfPresent(width, forKey: .key)
                    try container.encodeIfPresent(height, forKey: .key)
                case let .bigScroller(entries, autoScrollInterval):
                    try container.encode(entries, forKey: .key)
                    try container.encodeIfPresent(autoScrollInterval.flatMap(Float.init), forKey: .key)
                case let .scroller(entries, listing):
                    try container.encode(entries, forKey: .key)
                    try container.encodeIfPresent(listing, forKey: .key)
                case let .mangaList(ranking, pageSize, entries, listing):
                    try container.encode(ranking, forKey: .key)
                    try container.encodeIfPresent(pageSize, forKey: .key)
                    try container.encode(entries, forKey: .key)
                    try container.encodeIfPresent(listing, forKey: .key)
                case let .mangaChapterList(pageSize, entries, listing):
                    try container.encodeIfPresent(pageSize, forKey: .key)
                    try container.encode(entries, forKey: .key)
                    try container.encodeIfPresent(listing, forKey: .key)
                case .filters(let a0):
                    try container.encode(a0, forKey: .key)
                case .links(let a0):
                    try container.encode(a0, forKey: .key)
            }
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(UInt8.self, forKey: .key)
            switch type {
                case 0:
                    let links = try container.decode([Link].self, forKey: .key)
                    let autoScrollInterval = try container
                        .decodeIfPresent(Float.self, forKey: .key)
                        .map(TimeInterval.init)
                    let width = try container.decodeIfPresent(Int.self, forKey: .key)
                    let height = try container.decodeIfPresent(Int.self, forKey: .key)
                    self = .imageScroller(
                        links: links,
                        autoScrollInterval: autoScrollInterval,
                        width: width,
                        height: height
                    )
                case 1:
                    let entries = try container.decode([Manga].self, forKey: .key)
                    let autoScrollInterval = try container.decodeIfPresent(
                        Float.self,
                        forKey: .key
                    ).map(TimeInterval.init)
                    self = .bigScroller(
                        entries: entries,
                        autoScrollInterval: autoScrollInterval
                    )
                case 2:
                    let entries = try container.decode([Link].self, forKey: .key)
                    let listing = try container.decodeIfPresent(Listing.self, forKey: .key)
                    self = .scroller(entries: entries, listing: listing)
                case 3:
                    let ranking = try container.decode(Bool.self, forKey: .key)
                    let pageSize = try container.decodeIfPresent(Int.self, forKey: .key)
                    let entries = try container.decode([Link].self, forKey: .key)
                    let listing = try container.decodeIfPresent(Listing.self, forKey: .key)
                    self = .mangaList(ranking: ranking, pageSize: pageSize, entries: entries, listing: listing)
                case 4:
                    let pageSize = try container.decodeIfPresent(Int.self, forKey: .key)
                    let entries = try container.decode([MangaWithChapter].self, forKey: .key)
                    let listing = try container.decodeIfPresent(Listing.self, forKey: .key)
                    self = .mangaChapterList(pageSize: pageSize, entries: entries, listing: listing)
                case 5:
                    let a0 = try container.decode([FilterItem].self, forKey: .key)
                    self = .filters(a0)
                case 6:
                    let a0 = try container.decode([Link].self, forKey: .key)
                    self = .links(a0)
                default:
                    throw DecodingError.dataCorruptedError(
                        forKey: .key,
                        in: container,
                        debugDescription: "Invalid type"
                    )
            }
        }

        enum CodingKeys: String, CodingKey {
            case key
        }
    }

    public init(title: String?, subtitle: String? = nil, value: Value) {
        self.title = title
        self.subtitle = subtitle
        self.value = value
    }
}

extension HomeComponent {
    mutating func setSourceKey(_ sourceKey: String) {
        self.value = switch self.value {
            case let .imageScroller(links, autoScrollInterval, width, height):
                .imageScroller(
                    links: links.map { link in
                        var newLink = link
                        newLink.setSourceKey(sourceKey)
                        return newLink
                    },
                    autoScrollInterval: autoScrollInterval,
                    width: width,
                    height: height
                )
            case let .bigScroller(entries, autoScrollInterval):
                .bigScroller(
                    entries: entries.map { manga in
                        var newManga = manga
                        newManga.sourceKey = sourceKey
                        return newManga
                    },
                    autoScrollInterval: autoScrollInterval
                )
            case let .scroller(entries, listing):
                    .scroller(
                        entries: entries.map { link in
                            var newLink = link
                            newLink.setSourceKey(sourceKey)
                            return newLink
                        },
                        listing: listing
                    )
            case let .mangaList(ranking, pageSize, entries, listing):
                .mangaList(
                    ranking: ranking,
                    pageSize: pageSize,
                    entries: entries.map { link in
                        var newLink = link
                        newLink.setSourceKey(sourceKey)
                        return newLink
                    },
                    listing: listing
                )
            case let .mangaChapterList(pageSize, entries, listing):
                .mangaChapterList(
                    pageSize: pageSize,
                    entries: entries.map { mangaWithChapter in
                        var newMangaWithChapter = mangaWithChapter
                        newMangaWithChapter.manga.sourceKey = sourceKey
                        return newMangaWithChapter
                    },
                    listing: listing
                )
            case .links(let array):
                .links(
                    array.map { link in
                        var newLink = link
                        newLink.setSourceKey(sourceKey)
                        return newLink
                    }
                )
            default:
                self.value
        }
    }
}

// MARK: - Home Partial Result

public enum HomePartialResult {
    case layout(Home)
    case component(HomeComponent)
}

extension HomePartialResult: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(UInt8.self, forKey: .key)
        switch type {
            case 0:
                self = .layout(try container.decode(Home.self, forKey: .key))
            case 1:
                self = .component(try container.decode(HomeComponent.self, forKey: .key))
            default:
                throw DecodingError.dataCorruptedError(
                    forKey: .key,
                    in: container,
                    debugDescription: "Invalid type"
                )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
            case let .layout(value):
                try container.encode(UInt8(0), forKey: .key)
                try container.encode(value, forKey: .key)
            case let .component(value):
                try container.encode(UInt8(1), forKey: .key)
                try container.encode(value, forKey: .key)
        }
    }

    enum CodingKeys: CodingKey {
        case key
    }
}
