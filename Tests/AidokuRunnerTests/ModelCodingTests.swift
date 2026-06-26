//
//  ModelCodingTests.swift
//  AidokuRunnerTests
//
//  Created by Skitty on 8/13/23.
//

@testable import AidokuRunner
import Testing

struct ModelCodingTests {
    @Test func testMangaCoding() throws {
        let manga = Manga(
            sourceKey: "",
            key: "1",
            title: "Manga 1",
            cover: nil,
            artists: nil,
            authors: ["Author"],
            description: "Description",
            url: nil,
            tags: ["Tag"],
            status: .ongoing,
            contentRating: .safe,
            viewer: .webtoon,
            updateStrategy: .always,
            nextUpdateTime: nil,
            chapters: nil
        )
        let data = try PostcardEncoder().encode(manga)
        let decodedManga = try PostcardDecoder().decode(Manga.self, from: data)

        #expect(manga.key == decodedManga.key)
        #expect(manga.title == decodedManga.title)
        #expect(manga.cover == decodedManga.cover)
        #expect(manga.artists == decodedManga.artists)
        #expect(manga.authors == decodedManga.authors)
        #expect(manga.description == decodedManga.description)
        #expect(manga.url == decodedManga.url)
        #expect(manga.tags == decodedManga.tags)
        #expect(manga.status == decodedManga.status)
        #expect(manga.contentRating == decodedManga.contentRating)
        #expect(manga.viewer == decodedManga.viewer)
        #expect(manga.updateStrategy == decodedManga.updateStrategy)
        #expect(manga.nextUpdateTime == decodedManga.nextUpdateTime)
        #expect(manga.chapters?.count == decodedManga.chapters?.count)
    }
}
