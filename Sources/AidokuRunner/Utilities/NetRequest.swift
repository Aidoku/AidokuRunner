//
//  NetRequest.swift
//  AidokuRunner
//
//  Created by Skitty on 2/6/25.
//

import Foundation

struct NetRequest: Sendable {
    enum Method: Int {
        case get = 0
        case post
        case put
        case head
        case delete

        var stringValue: String {
            switch self {
                case .get: "GET"
                case .post: "POST"
                case .put: "PUT"
                case .head: "HEAD"
                case .delete: "DELETE"
            }
        }
    }

    let method: Method
    var url: URL?
    var headers: [String: String] = [:]
    var body: Data?

    var response: URLResponse?
    var responseData: Data?
    var responseError: Error?

    init(method: Method, url: URL? = nil) {
        self.method = method
        self.url = url
    }

    func toUrlRequest() -> URLRequest? {
        guard let url else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = method.stringValue
        for header in headers {
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }
        request.httpBody = body
        return request
    }
}
