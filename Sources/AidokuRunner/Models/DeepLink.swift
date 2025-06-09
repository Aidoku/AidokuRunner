//
//  DeepLink.swift
//  AidokuRunner
//
//  Created by Skitty on 12/29/23.
//

import Foundation

public struct DeepLinkResult: Sendable, Codable {
    public let mangaId: String?
    public let chapterId: String?
    public let listing: Listing?

    public init(
        mangaId: String? = nil,
        chapterId: String? = nil,
        listing: Listing? = nil
    ) {
        self.mangaId = mangaId
        self.chapterId = chapterId
        self.listing = listing
    }
}
