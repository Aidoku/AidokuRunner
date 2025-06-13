//
//  DeepLink.swift
//  AidokuRunner
//
//  Created by Skitty on 12/29/23.
//

import Foundation

public struct DeepLinkResult: Sendable, Codable {
    public let mangaKey: String?
    public let chapterKey: String?
    public let listing: Listing?

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
