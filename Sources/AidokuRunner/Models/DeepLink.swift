//
//  DeepLink.swift
//  AidokuRunner
//
//  Created by Skitty on 12/29/23.
//

import Foundation

public struct DeepLinkResult: Sendable, Codable {
    public var mangaKey: String?
    public var chapterKey: String?
    public var listing: Listing?

    public init(
        mangaKey: String? = nil,
        chapterKey: String? = nil,
        listing: Listing? = nil
    ) {
        self.mangaKey = mangaKey
        self.chapterKey = chapterKey
        self.listing = listing
    }
}
