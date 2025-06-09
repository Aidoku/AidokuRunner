//
//  Chapter.swift
//  AidokuRunner
//
//  Created by Skitty on 8/12/23.
//

import Foundation

public struct Chapter: Sendable, Hashable, Codable {
    /// Unique identifier for the chapter
    public var key: String
    /// Title of the chapter (excluding volume and chapter number)
    public var title: String?
    /// Chapter number
    public var chapterNumber: Float?
    /// Volume number
    public var volumeNumber: Float?
    /// Date the chapter was uploaded
    @EpochDate public var dateUploaded: Date?
    /// Optional list of groups that scanlated or published the chapter
    public var scanlators: [String]?
    /// Link to the chapter on the source website
    @URLAsString public var url: URL?
    /// Language of the chapter
    public var language: String?
    /// Optional thumbnail image url for the chapter
    public var thumbnail: String?
    /// Boolean indicating if the chapter is locked
    public var locked: Bool

    public init(
        key: String,
        title: String? = nil,
        chapterNumber: Float? = nil,
        volumeNumber: Float? = nil,
        dateUploaded: Date? = nil,
        scanlators: [String]? = nil,
        url: URL? = nil,
        language: String? = nil,
        thumbnail: String? = nil,
        locked: Bool = false
    ) {
        self.key = key
        self.title = title
        self.chapterNumber = chapterNumber
        self.volumeNumber = volumeNumber
        self.dateUploaded = dateUploaded
        self.scanlators = scanlators
        self.url = url
        self.language = language
        self.thumbnail = thumbnail
        self.locked = locked
    }
}

extension Chapter: Identifiable {
    public var id: String { key }
}
