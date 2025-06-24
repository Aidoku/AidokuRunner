//
//  MangaWithChapter.swift
//  AidokuRunner
//
//  Created by Skitty on 8/24/23.
//

import Foundation

public struct MangaWithChapter: Sendable, Codable, Hashable {
    public var manga: Manga
    public var chapter: Chapter

    public init(manga: Manga, chapter: Chapter) {
        self.manga = manga
        self.chapter = chapter
    }
}
