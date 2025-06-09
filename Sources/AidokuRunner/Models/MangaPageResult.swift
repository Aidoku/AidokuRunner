//
//  MangaPageResult.swift
//  AidokuRunner
//
//  Created by Skitty on 8/12/23.
//

import Foundation

public struct MangaPageResult: Sendable, Codable {
    /// List of manga entries
    public var entries: [Manga]
    /// Whether the next page is available or not
    public var hasNextPage: Bool

    public init(entries: [Manga], hasNextPage: Bool) {
        self.entries = entries
        self.hasNextPage = hasNextPage
    }
}

extension MangaPageResult {
    mutating func setSourceKey(_ sourceKey: String) {
        for i in 0..<entries.count {
            entries[i].sourceKey = sourceKey
        }
    }
}
