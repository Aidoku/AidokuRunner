//
//  Manga.swift
//  AidokuRunner
//
//  Created by Skitty on 7/16/23.
//

import Foundation

public struct Manga: Sendable, Hashable, Codable {
    /// Unique identifier of the manga's source
    @ExcludedFromCoding
    public internal(set) var sourceKey: String
    /// Unique identifier for the manga
    public let key: String
    /// Title of the manga
    public var title: String
    /// Link to the manga cover image
    public var cover: String?
    /// Optional list of artists
    public var artists: [String]?
    /// Optional list of authors
    public var authors: [String]?
    /// Description of the manga
    public var description: String?
    /// Link to the manga on the source website
    @URLAsString public var url: URL?
    /// Optional list of genres or tags (max: 255)
    public var tags: [String]?
    /// Publishing status of the manga
    public var status: MangaStatus
    /// Content rating of the manga
    public var contentRating: MangaContentRating
    /// Preferred viewer type of the manga
    public var viewer: Viewer
    /// Ideal update strategy for the manga
    public var updateStrategy: UpdateStrategy
    /// Optional date for when the manga should next be updated
    public var nextUpdateTime: Int?
    /// List of chapters
    public var chapters: [Chapter]?

    public init(
        sourceKey: String,
        key: String,
        title: String,
        cover: String? = nil,
        artists: [String]? = nil,
        authors: [String]? = nil,
        description: String? = nil,
        url: URL? = nil,
        tags: [String]? = nil,
        status: MangaStatus = .unknown,
        contentRating: MangaContentRating = .unknown,
        viewer: Viewer = .unknown,
        updateStrategy: UpdateStrategy = .always,
        nextUpdateTime: Int? = nil,
        chapters: [Chapter]? = nil
    ) {
        self.sourceKey = sourceKey
        self.key = key
        self.title = title
        self.cover = cover
        self.artists = artists
        self.authors = authors
        self.description = description
        self.url = url
        self.tags = tags
        self.status = status
        self.contentRating = contentRating
        self.viewer = viewer
        self.updateStrategy = updateStrategy
        self.nextUpdateTime = nextUpdateTime
        self.chapters = chapters
    }

    public func copy(from manga: Self) -> Self {
        .init(
            sourceKey: manga.sourceKey.isEmpty ? sourceKey : manga.sourceKey,
            key: manga.key.isEmpty ? key : manga.key,
            title: manga.title.isEmpty ? title : manga.title,
            cover: manga.cover ?? cover,
            artists: manga.artists ?? artists,
            authors: manga.authors ?? authors,
            description: manga.description ?? description,
            url: manga.url ?? url,
            tags: manga.tags ?? tags,
            status: manga.status,
            contentRating: manga.contentRating,
            viewer: manga.viewer,
            updateStrategy: manga.updateStrategy,
            nextUpdateTime: manga.nextUpdateTime,
            chapters: manga.chapters ?? chapters
        )
    }
}

public enum MangaStatus: UInt8, Sendable, Codable {
    case unknown
    case ongoing
    case completed
    case cancelled
    case hiatus
}

public enum MangaContentRating: UInt8, Sendable, Codable {
    case unknown
    case safe
    case suggestive
    case nsfw
}

public enum Viewer: UInt8, Sendable, Codable {
    case unknown
    case leftToRight
    case rightToLeft
    case vertical
    case webtoon
}

public enum UpdateStrategy: UInt8, Sendable, Codable {
    case always
    case never
}

public extension Manga {
    func intoLink() -> HomeComponent.Value.Link {
        .init(
            title: title,
            imageUrl: cover,
            subtitle: authors?.joined(separator: ", ") ?? description,
            value: .manga(self)
        )
    }
}
