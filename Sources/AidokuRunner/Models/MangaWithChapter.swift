//
//  MangaWithChapter.swift
//  AidokuRunner
//
//  Created by Skitty on 8/24/23.
//

import Foundation

public struct MangaWithChapter: Sendable, Codable, Hashable {
    public let manga: Manga
    public let chapter: Chapter

    public init(manga: Manga, chapter: Chapter) {
        self.manga = manga
        self.chapter = chapter
    }
}
