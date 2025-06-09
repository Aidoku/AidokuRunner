//
//  Response.swift
//  AidokuRunner
//
//  Created by Skitty on 7/21/24.
//

import Foundation

public typealias ImageRef = Int32

public struct Request: Sendable, Codable {
    @URLAsString var url: URL?
    let headers: [String: String]

    public init(url: URL?, headers: [String: String]) {
        self.url = url
        self.headers = headers
    }
}

public struct Response: Sendable, Codable {
    let code: UInt16
    let headers: [String: String]
    let request: Request
    let image: ImageRef

    public init(code: Int, headers: [String: String], request: Request, image: ImageRef) {
        self.code = UInt16(code)
        self.headers = headers
        self.request = request
        self.image = image
    }
}
