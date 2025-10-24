//
//  SourceInfo.swift
//  AidokuRunner
//
//  Created by Skitty on 10/6/23.
//

import Foundation

public struct SourceInfo: Sendable, Codable {
    public let info: Info
    public let listings: [Listing]?
    public let config: Configuration?

    public struct Info: Sendable, Codable {
        public let id: String
        public let name: String
        public let altNames: [String]?
        public let version: Int
        public let url: String?
        public let urls: [String]?
        public let contentRating: SourceContentRating?
        public let languages: [String]

        public init(
            id: String,
            name: String,
            altNames: [String]?,
            version: Int,
            url: String?,
            urls: [String]?,
            contentRating: SourceContentRating?,
            languages: [String]
        ) {
            self.id = id
            self.name = name
            self.altNames = altNames
            self.version = version
            self.url = url
            self.urls = urls
            self.contentRating = contentRating
            self.languages = languages
        }
    }

    public struct Configuration: Sendable, Codable {
        public var languageSelectType: LanguageSelectType?
        public var supportsArtistSearch: Bool?
        public var supportsAuthorSearch: Bool?
        public var supportsTagSearch: Bool?
        public var allowsBaseUrlSelect: Bool?
        public var breakingChangeVersion: Int?
        public var hidesFiltersWhileSearching: Bool?

        public init(
            languageSelectType: LanguageSelectType? = nil,
            supportsArtistSearch: Bool? = nil,
            supportsAuthorSearch: Bool? = nil,
            supportsTagSearch: Bool? = nil,
            allowsBaseUrlSelect: Bool? = nil,
            breakingChangeVersion: Int? = nil,
            hidesFiltersWhileSearching: Bool? = nil
        ) {
            self.languageSelectType = languageSelectType
            self.supportsArtistSearch = supportsArtistSearch
            self.supportsAuthorSearch = supportsAuthorSearch
            self.supportsTagSearch = supportsTagSearch
            self.allowsBaseUrlSelect = allowsBaseUrlSelect
            self.breakingChangeVersion = breakingChangeVersion
            self.hidesFiltersWhileSearching = hidesFiltersWhileSearching
        }
    }

    public init(
        info: Info,
        listings: [Listing]?,
        config: Configuration?
    ) {
        self.info = info
        self.listings = listings
        self.config = config
    }
}

public enum SourceContentRating: Int, Sendable, Codable, CaseIterable {
    case safe = 0
    case containsNsfw = 1
    case primarilyNsfw = 2
}

public enum LanguageSelectType: String, Sendable, Codable {
    case single
    case multiple
}
