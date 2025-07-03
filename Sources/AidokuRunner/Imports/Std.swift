//
//  Std.swift
//  AidokuRunner
//
//  Created by Skitty on 7/16/23.
//

import Foundation
import Wasm3

struct Std: SourceLibrary {
    static let namespace = "std"

    let module: Module
    var store: GlobalStore

    func link() throws {
        try? module.linkFunction(name: "destroy", namespace: Self.namespace, function: destroy)
        try? module.linkFunction(name: "buffer_len", namespace: Self.namespace, function: bufferLength)
        try? module.linkFunction(name: "read_buffer", namespace: Self.namespace, function: readBuffer)
        try? module.linkFunction(name: "current_date", namespace: Self.namespace, function: currentDate)
        try? module.linkFunction(name: "utc_offset", namespace: Self.namespace, function: utcOffset)
        try? module.linkFunction(name: "parse_date", namespace: Self.namespace, function: parseDate)
    }

    enum Result: Int32 {
        case success = 0
        case invalidDescriptor = -1
        case invalidBufferSize = -2
        case failedMemoryWrite = -3
        case invalidString = -4
        case invalidDateString = -5
    }
}

extension Std {
    func destroy(descriptor: Int32) {
        store.remove(at: descriptor)
    }
}

extension Std {
    private func getBytes(descriptor: Int32) -> [UInt8]? {
        let item = store.fetch(from: descriptor)
        var data = (item as? Data).flatMap { [UInt8]($0) }
        if data == nil {
            data = (item as? String).flatMap { [UInt8]($0.utf8) }
        }
        return data
    }

    func bufferLength(descriptor: Int32) -> Int32 {
        guard let data = getBytes(descriptor: descriptor) else {
            return Result.invalidDescriptor.rawValue
        }
        return Int32(data.count)
    }

    func readBuffer(_ memory: Memory, descriptor: Int32, buffer: UInt32, size: UInt32) -> Int32 {
        guard let data = getBytes(descriptor: descriptor) else {
            return Result.invalidDescriptor.rawValue
        }
        do {
            if size <= data.count {
                try memory.write(bytes: data.dropLast(data.count - Int(size)), offset: buffer)
                return Result.success.rawValue
            } else {
                return Result.invalidBufferSize.rawValue
            }
        } catch {
            return Result.failedMemoryWrite.rawValue
        }
    }
}

extension Std {
    func currentDate() -> Float64 {
        Date.now.timeIntervalSince1970
    }

    func utcOffset() -> Int64 {
        -Int64(TimeZone.current.secondsFromGMT())
    }

    // swiftlint:disable:next function_parameter_count
    func parseDate(
        _ memory: Memory,
        stringPtr: UInt32,
        stringLength: UInt32,
        formatPtr: UInt32,
        formatLength: UInt32,
        localePtr: UInt32,
        localeLength: UInt32,
        timeZonePtr: UInt32,
        timeZoneLength: UInt32
    ) -> Float64 {
        guard
            let string = try? memory.readString(offset: stringPtr, length: stringLength),
            let format = try? memory.readString(offset: formatPtr, length: formatLength)
        else {
            return Float64(Result.invalidString.rawValue)
        }
        let locale: String? = if localeLength > 0 {
            try? memory.readString(offset: localePtr, length: localeLength)
        } else {
            nil
        }
        let timeZone: String? = if timeZoneLength > 0 {
            try? memory.readString(offset: timeZonePtr, length: timeZoneLength)
        } else {
            nil
        }
        let formatter = DateFormatter()
        if let locale {
            formatter.locale = if locale == "current" {
                Locale.current
            } else {
                Locale(identifier: locale)
            }
        }
        if let timeZone {
            formatter.timeZone = if timeZone == "current" {
                TimeZone.current
            } else {
                TimeZone(identifier: timeZone)
            }
        }
        formatter.dateFormat = format
        guard let date = formatter.date(from: string) else {
            return Float64(Result.invalidDateString.rawValue)
        }
        return Float64(date.timeIntervalSince1970)
    }
}
