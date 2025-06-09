//
//  ModelCodingTests.swift
//  AidokuRunnerTests
//
//  Created by Skitty on 8/13/23.
//

@testable import AidokuRunner
import XCTest

final class ModelCodingTests: XCTestCase {
    func testMangaCoding() throws {
        let manga = Manga(
            key: "1",
            title: "Manga 1",
            cover: nil,
            alternateCovers: nil,
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
            extraData: nil,
            chapters: nil
        )
        let data = try ByteEncoder().encode(manga)
        let decodedManga = try ByteDecoder.decode(Manga.self, from: data)

        XCTAssertEqual(manga.key, decodedManga.key)
        XCTAssertEqual(manga.title, decodedManga.title)
        XCTAssertEqual(manga.cover, decodedManga.cover)
        XCTAssertEqual(manga.alternateCovers, decodedManga.alternateCovers)
        XCTAssertEqual(manga.artists, decodedManga.artists)
        XCTAssertEqual(manga.authors, decodedManga.authors)
        XCTAssertEqual(manga.description, decodedManga.description)
        XCTAssertEqual(manga.url, decodedManga.url)
        XCTAssertEqual(manga.tags, decodedManga.tags)
        XCTAssertEqual(manga.status, decodedManga.status)
        XCTAssertEqual(manga.contentRating, decodedManga.contentRating)
        XCTAssertEqual(manga.viewer, decodedManga.viewer)
        XCTAssertEqual(manga.updateStrategy, decodedManga.updateStrategy)
        XCTAssertEqual(manga.nextUpdateTime, decodedManga.nextUpdateTime)
        XCTAssertEqual(manga.extraData, decodedManga.extraData)
        XCTAssertEqual(manga.chapters?.count, decodedManga.chapters?.count)
    }
}
