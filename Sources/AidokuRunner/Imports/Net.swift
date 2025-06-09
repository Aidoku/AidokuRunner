//
//  Net.swift
//  AidokuRunner
//
//  Created by Skitty on 9/3/23.
//

import Foundation
import SwiftSoup
import Wasm3

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

struct Net: SourceLibrary {
    static let namespace = "net"

    let module: Module
    let store: GlobalStore

    private let rateLimit = RateLimit()

    func link() throws {
        try? module.linkFunction(name: "init", namespace: Self.namespace, function: initialize)
        try? module.linkFunction(name: "send", namespace: Self.namespace, function: send)
        try? module.linkFunction(name: "send_all", namespace: Self.namespace, function: sendAll)

        try? module.linkFunction(name: "set_url", namespace: Self.namespace, function: setUrl)
        try? module.linkFunction(name: "set_header", namespace: Self.namespace, function: setHeader)
        try? module.linkFunction(name: "set_body", namespace: Self.namespace, function: setBody)

        try? module.linkFunction(name: "data_len", namespace: Self.namespace, function: dataLength)
        try? module.linkFunction(name: "read_data", namespace: Self.namespace, function: readData)
        try? module.linkFunction(name: "get_image", namespace: Self.namespace, function: getImage)
        try? module.linkFunction(name: "get_status_code", namespace: Self.namespace, function: getStatusCode)
        try? module.linkFunction(name: "get_header", namespace: Self.namespace, function: getHeader)
        try? module.linkFunction(name: "html", namespace: Self.namespace, function: dataToHtml)

        try? module.linkFunction(name: "set_rate_limit", namespace: Self.namespace, function: setRateLimit)
    }

    enum Result: Int32 {
        case success = 0
        case invalidDescriptor = -1
        case invalidString = -2
        case invalidMethod = -3
        case invalidUrl = -4
        case invalidHtml = -5
        case invalidBufferSize = -6
        case missingData = -7
        case missingResponse = -8
        case missingUrl = -9
        case requestError = -10
        case failedMemoryWrite = -11
        case notAnImage = -12
    }
}

extension Net {
    func initialize(method: Int32) -> Int32 {
        guard let method = NetRequest.Method(rawValue: Int(method)) else {
            return Result.invalidMethod.rawValue
        }
        let request = NetRequest(method: method)
        return store.store(request)
    }

    func send(descriptor: Int32) -> Int32 {
        guard var request = store.fetch(from: descriptor) as? NetRequest
        else { return Result.invalidDescriptor.rawValue }

        guard let urlRequest = request.toUrlRequest()
        else { return Result.missingUrl.rawValue }

        // block until rate limit is okay
        let rateLimit = rateLimit // capture rate limit actor
        BlockingTask {
            var shouldWait = !(await rateLimit.incRequest())
            while shouldWait {
                let waitTime = await rateLimit.nextPeriodStart - Int(Date().timeIntervalSince1970)
                if waitTime > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(waitTime) * 1_000_000_000)
                }
                shouldWait = !(await rateLimit.incRequest())
            }
        }.get()

        struct RequestResult {
            var data: Data?
            var response: URLResponse?
            var error: Error?
        }

        let result: RequestResult = BlockingTask {
            do {
                let (data, response) = try await URLSession.shared.data(for: urlRequest)
                return RequestResult(data: data, response: response, error: nil)
            } catch {
                return RequestResult(data: nil, response: nil, error: error)
            }
        }.get()

        request.response = result.response
        request.responseData = result.data
        request.responseError = result.error

        store.set(at: descriptor, item: request)

        if result.error != nil {
            return Result.requestError.rawValue
        }

        return Result.success.rawValue
    }

    func sendAll(memory: Memory, descriptors: Int32, length: Int32) -> Int32 {
        guard
            descriptors >= 0, length > 0,
            let descriptorArray: [Int32] = try? memory.readValues(offset: UInt32(descriptors), length: UInt32(length))
        else {
            return Result.invalidDescriptor.rawValue
        }

        let requestArray: [NetRequest?] = descriptorArray.map {
            store.fetch(from: $0) as? NetRequest
        }

        let rateLimit = rateLimit // capture rate limit actor
        let (errors, requests) = BlockingTask {
            await withTaskGroup(of: (Int, NetRequest, Data?, URLResponse?).self) { group in
                var errors = Array(repeating: Int32(0), count: Int(length))

                for (idx, request) in requestArray.enumerated() {
                    guard let request else {
                        errors[idx] = Result.invalidDescriptor.rawValue
                        continue
                    }
                    guard let urlRequest = request.toUrlRequest()
                    else {
                        errors[idx] = Result.missingUrl.rawValue
                        continue
                    }
                    group.addTask {
                        var shouldWait = !(await rateLimit.incRequest())
                        while shouldWait {
                            while await rateLimit.atLimit {
                                let waitTime = await rateLimit.nextPeriodStart - Int(Date().timeIntervalSince1970)
                                try? await Task.sleep(nanoseconds: UInt64(waitTime) * 1_000_000_000)
                            }
                            shouldWait = !(await rateLimit.incRequest())
                        }
                        do {
                            let (data, response) = try await URLSession.shared.data(for: urlRequest)
                            return (idx, request, data, response)
                        } catch {
                            return (idx, request, nil, nil)
                        }
                    }
                }

                var requests = requestArray

                for await (idx, request, data, response) in group {
                    if data == nil || response == nil {
                        errors[idx] = Result.requestError.rawValue
                    } else {
                        var request = request
                        request.responseData = data
                        request.response = response
                        requests[idx] = request
                    }
                }

                return (errors, requests)
            }
        }.get()

        for (idx, request) in requests.enumerated() {
            if let request {
                let descriptor = descriptorArray[idx]
                store.set(at: descriptor, item: request)
            }
        }

        try? memory.write(values: errors, offset: UInt32(descriptors))

        let hasError = errors.contains { $0 != Result.success.rawValue }

        return hasError ? Result.requestError.rawValue : Result.success.rawValue
    }

    func setUrl(memory: Memory, descriptor: Int32, value: Int32, length: Int32) -> Int32 {
        // fetch request object from descriptor
        guard var request = store.fetch(from: descriptor) as? NetRequest
        else {
            return Result.invalidDescriptor.rawValue
        }
        // read given url string
        guard
            value >= 0, length > 0,
            let urlString = try? memory.readString(offset: UInt32(value), length: UInt32(length))
        else {
            return Result.invalidString.rawValue
        }
        // create url from string
        guard let url = URL(string: urlString)
        else {
            return Result.invalidUrl.rawValue
        }
        request.url = url
        store.set(at: descriptor, item: request)
        return Result.success.rawValue
    }

    // swiftlint:disable:next function_parameter_count
    func setHeader(
        memory: Memory,
        descriptor: Int32,
        key: Int32,
        keyLength: Int32,
        value: Int32,
        valueLength: Int32
    ) -> Int32 {
        // fetch request object from descriptor
        guard var request = store.fetch(from: descriptor) as? NetRequest
        else { return Result.invalidDescriptor.rawValue }
        // read header key and value
        guard
            key >= 0, keyLength > 0, value > 0, valueLength > 0,
            let keyString = try? memory.readString(offset: UInt32(key), length: UInt32(keyLength)),
            let valueString = try? memory.readString(offset: UInt32(value), length: UInt32(valueLength))
        else {
            return Result.invalidString.rawValue
        }
        request.headers[keyString] = valueString
        store.set(at: descriptor, item: request)
        return Result.success.rawValue
    }

    func setBody(memory: Memory, descriptor: Int32, value: Int32, length: Int32) -> Int32 {
        guard var request = store.fetch(from: descriptor) as? NetRequest
        else { return Result.invalidDescriptor.rawValue }
        // read body data
        guard
            value >= 0, length > 0,
            let body = try? memory.readData(offset: UInt32(value), length: UInt32(length))
        else {
            return Result.invalidString.rawValue
        }
        request.body = body
        store.set(at: descriptor, item: request)
        return Result.success.rawValue
    }

    func dataLength(descriptor: Int32) -> Int32 {
        guard let request = store.fetch(from: descriptor) as? NetRequest
        else { return Result.invalidDescriptor.rawValue }

        guard let data = request.responseData
        else { return Result.missingData.rawValue }

        return Int32(data.count)
    }

    func readData(_ memory: Memory, descriptor: Int32, buffer: UInt32, size: UInt32) -> Int32 {
        guard let request = store.fetch(from: descriptor) as? NetRequest
        else { return Result.invalidDescriptor.rawValue }
        guard let data = request.responseData
        else { return Result.missingData.rawValue }
        do {
            if size <= data.count {
                try memory.write(data: data.dropLast(data.count - Int(size)), offset: buffer)
                return Result.success.rawValue
            } else {
                return Result.invalidBufferSize.rawValue
            }
        } catch {
            return Result.failedMemoryWrite.rawValue
        }
    }

    func getImage(descriptor: Int32) -> Int32 {
        guard let request = store.fetch(from: descriptor) as? NetRequest
        else { return Result.invalidDescriptor.rawValue }

        guard let data = request.responseData
        else { return Result.missingData.rawValue }

#if canImport(UIKit)
        let image = UIImage(data: data)
        guard let image else {
            return Result.notAnImage.rawValue
        }
        return store.store(image)
#else
        let image = NSImage(data: data)
        guard let image else {
            return Result.notAnImage.rawValue
        }
        return store.store(NSImageFixed(image))
#endif
    }

    func getStatusCode(descriptor: Int32) -> Int32 {
        guard let request = store.fetch(from: descriptor) as? NetRequest
        else { return Result.invalidDescriptor.rawValue }

        guard let response = request.response as? HTTPURLResponse
        else { return Result.missingResponse.rawValue }

        return Int32(response.statusCode)
    }

    func getHeader(memory: Memory, descriptor: Int32, key: Int32, keyLength: Int32) -> Int32 {
        guard let request = store.fetch(from: descriptor) as? NetRequest
        else { return Result.invalidDescriptor.rawValue }

        guard let response = request.response as? HTTPURLResponse
        else { return Result.missingResponse.rawValue }

        guard
            key >= 0, keyLength > 0,
            let key = try? memory.readString(offset: UInt32(key), length: UInt32(keyLength))
        else {
            return Result.invalidString.rawValue
        }

        guard let value = response.value(forHTTPHeaderField: key)
        else {
            return Result.missingData.rawValue
        }

        return store.store(value)
    }

    func dataToHtml(descriptor: Int32) -> Int32 {
        guard let request = store.fetch(from: descriptor) as? NetRequest
        else { return Result.invalidDescriptor.rawValue }

        guard let data = request.responseData
        else { return Result.missingData.rawValue }

        var html = String(data: data, encoding: .utf8) ?? ""
        if html.isEmpty {
            html = String(data: data, encoding: .ascii) ?? ""
        }

        do {
            let document = if let baseUrl = request.response?.url?.absoluteString {
                try SwiftSoup.parse(html, baseUrl)
            } else {
                try SwiftSoup.parse(html)
            }
            return store.store(document)
        } catch {
            return Result.invalidHtml.rawValue
        }
    }

    enum TimeUnit: Int32 {
        case seconds = 0
        case minutes
        case hours

        var seconds: Int {
            switch self {
                case .seconds: 1
                case .minutes: 60
                case .hours: 3600
            }
        }
    }

    func setRateLimit(permits: Int32, period: Int32, unit: Int32) {
        let timeUnit = TimeUnit(rawValue: unit) ?? .seconds
        let rateLimit = rateLimit
        BlockingTask {
            await rateLimit.set(
                permits: Int(permits),
                period: Int(period) * Int(timeUnit.seconds)
            )
        }.get()
    }
}
