//
//  Runner.swift
//  AidokuRunner
//
//  Created by Skitty on 5/9/25.
//

import Foundation

public protocol Runner: Sendable {
    var features: SourceFeatures { get }

    var partialHomePublisher: SinglePublisher<Home>? { get }
    var partialMangaPublisher: SinglePublisher<Manga>? { get }

    func getMangaList(listing: Listing, page: Int) async throws -> MangaPageResult
    func getSearchMangaList(query: String?, page: Int, filters: [FilterValue]) async throws -> MangaPageResult
    func getMangaUpdate(manga: Manga, needsDetails: Bool, needsChapters: Bool) async throws -> Manga
    func getPageList(manga: Manga, chapter: Chapter) async throws -> [Page]

    func getHome() async throws -> Home
    func processPageImage(response: Response, context: PageContext?) async throws -> PlatformImage?
    func getSearchFilters() async throws -> [Filter]
    func getSettings() async throws -> [Setting]
    func getListings() async throws -> [Listing]
    func getImageRequest(url: String, context: PageContext?) async throws -> URLRequest
    func getPageDescription(page: Page) async throws -> String?
    func getAlternateCovers(manga: Manga) async throws -> [String]
    func getBaseUrl() async throws -> URL?
    func handleNotification(notification: String) async throws
    func handleDeepLink(url: String) async throws -> DeepLinkResult?
    func handleBasicLogin(key: String, username: String, password: String) async throws -> Bool
    func handleWebLogin(key: String, cookies: [String: String]) async throws -> Bool
    func handleMigration(id: String, kind: IdKind) async throws -> String

    func store<T: Sendable>(value: T) async throws -> Int32
    func remove(value: Int32) async throws
}

// default implementation for optional methods
public extension Runner {
    func processPageImage(response _: Response, context _: PageContext?) throws -> PlatformImage? {
        throw SourceError.unimplemented
    }

    func getSearchFilters() throws -> [Filter] {
        throw SourceError.unimplemented
    }

    func getSettings() throws -> [Setting] {
        throw SourceError.unimplemented
    }

    func getListings() throws -> [Listing] {
        throw SourceError.unimplemented
    }

    func getImageRequest(url _: String, context _: PageContext?) throws -> URLRequest {
        throw SourceError.unimplemented
    }

    func getPageDescription(page _: AidokuRunner.Page) throws -> String? {
        throw SourceError.unimplemented
    }

    func getAlternateCovers(manga _: AidokuRunner.Manga) throws -> [String] {
        throw SourceError.unimplemented
    }

    func getBaseUrl() throws -> URL? {
        throw SourceError.unimplemented
    }

    func handleNotification(notification _: String) throws {
        throw SourceError.unimplemented
    }

    func handleDeepLink(url _: String) throws -> DeepLinkResult? {
        throw SourceError.unimplemented
    }

    func handleBasicLogin(key _: String, username _: String, password _: String) throws -> Bool {
        throw SourceError.unimplemented
    }

    func handleWebLogin(key _: String, cookies _: [String: String]) throws -> Bool {
        throw SourceError.unimplemented
    }

    func handleMigration(id _: String, kind _: IdKind) throws -> String {
        throw SourceError.unimplemented
    }

    func store<T: Sendable>(value _: T) throws -> Int32 {
        throw SourceError.unimplemented
    }

    func remove(value _: Int32) throws {
        throw SourceError.unimplemented
    }
}
