//
//  Cookie.swift
//  AidokuRunner
//
//  Created by skitty on 8/16/26.
//

import Foundation

struct Cookie: Sendable, Codable {
    let name: String
    let value: String
    @EpochDate var expiresDate: Date?
    let domain: String
    let path: String
    let isSecure: Bool
    let isHTTPOnly: Bool

    init(_ httpCookie: HTTPCookie) {
        self.name = httpCookie.name
        self.value = httpCookie.value
        self.expiresDate = httpCookie.expiresDate
        self.domain = httpCookie.domain
        self.path = httpCookie.path
        self.isSecure = httpCookie.isSecure
        self.isHTTPOnly = httpCookie.isHTTPOnly
    }
}
