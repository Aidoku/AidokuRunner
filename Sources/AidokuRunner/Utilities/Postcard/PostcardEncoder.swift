//
//  PostcardEncoder.swift
//  AidokuRunner
//
//  Created by Skitty on 1/5/25.
//

import Combine
import Foundation

// https://postcard.jamesmunns.com/wire-format
public class PostcardEncoder: TopLevelEncoder {
    public init() {
        // nothing to configure
    }

    public func encode<T: Encodable>(_ value: T) throws -> Data {
        let stringsEncoding = PostcardEncoding()
        try value.encode(to: stringsEncoding)
        return stringsEncoding.data.data
    }
}

final class PostcardContainer {
    private(set) var data = Data()

    private var reservedPositions: [Int: Int] = [:]

    func encodeNil() {
        data.append(0x00)
    }

    func encode(_ value: Bool) {
        data.append(value ? 1 : 0)
    }

    func encode(_ value: String) {
        let utf8 = [UInt8](value.utf8)
        encode(UInt64(utf8.count))
        data.append(contentsOf: utf8)
    }

    func encode(_ value: Double) {
        withUnsafeBytes(of: value) { buffer in
            data.append(contentsOf: buffer)
        }
    }

    func encode(_ value: Float) {
        withUnsafeBytes(of: value) { buffer in
            data.append(contentsOf: buffer)
        }
    }

    func encode(_ value: Int) {
        encode(Int64(value))
    }

    func encode(_ value: Int8) {
        encode(UInt8(truncatingIfNeeded: value.littleEndian))
    }

    func encode(_ value: Int16) {
        encode(zigZag(value))
    }

    func encode(_ value: Int32) {
        encode(zigZag(value))
    }

    func encode(_ value: Int64) {
        encode(zigZag(value))
    }

    func encode(_ value: UInt) {
        encode(UInt64(value))
    }

    func encode(_ value: UInt8) {
        data.append(value)
    }

    func encode(_ value: UInt16) {
        varInt(value, data: &data)
    }

    func encode(_ value: UInt32) {
        varInt(value, data: &data)
    }

    func encode(_ value: UInt64) {
        varInt(value, data: &data)
    }

    func reserve() -> Int {
        let position = data.count
        data.append(0x00)
        reservedPositions[position] = 1
        return position
    }

    func update(at position: Int, with value: UInt64) {
        var lengthData = Data()
        varInt(value, data: &lengthData)
        let reservedLength = reservedPositions[position] ?? 10
        data.replaceSubrange(position..<(position + reservedLength), with: lengthData)
        reservedPositions[position] = lengthData.count
    }

    func removeReserve(at position: Int) {
        reservedPositions.removeValue(forKey: position)
    }
}

private struct PostcardEncoding: Encoder {
    fileprivate var data: PostcardContainer

    init(to encodedData: PostcardContainer = PostcardContainer()) {
        self.data = encodedData
    }

    var codingPath: [CodingKey] = []

    let userInfo: [CodingUserInfoKey: Any] = [:]

    // struct
    func container<Key: CodingKey>(keyedBy key: Key.Type) -> KeyedEncodingContainer<Key> {
        let description = "\(key)"
        let useKeys = description == "_DictionaryCodingKey"
        let prependLength = useKeys
        return KeyedEncodingContainer(
            PostcardKeyedEncoding<Key>(
                to: data,
                useKeys: useKeys,
                prependLength: prependLength
            )
        )
    }

    // array / enum
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        PostcardUnkeyedEncoding(to: data)
   }

    func singleValueContainer() -> SingleValueEncodingContainer {
        PostcardSingleValueEncoding(to: data)
    }
}

private class PostcardKeyedEncoding<Key: CodingKey>: KeyedEncodingContainerProtocol {
    private let data: PostcardContainer
    private let useKeys: Bool
    private let prependLength: Bool

    private let lengthLocation: Int?

    init(to data: PostcardContainer, useKeys: Bool = false, prependLength: Bool = false) {
        self.data = data
        self.useKeys = useKeys
        self.prependLength = prependLength
        self.lengthLocation = prependLength ? data.reserve() : nil
    }

    deinit {
        if let location = lengthLocation {
            data.removeReserve(at: location)
        }
    }

    var codingPath: [CodingKey] = []

    private(set) var count: UInt64 = 0 {
        didSet {
            if let location = lengthLocation {
                data.update(at: location, with: count)
            }
        }
    }

    func encodeNil(forKey key: Key) throws {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let intValue = key.intValue {
            data.encode(UInt64(intValue))
        }
        data.encodeNil()
        count += prependLength ? 1 : 0
    }

    func encode(_ value: Bool, forKey key: Key) throws {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let intValue = key.intValue {
            data.encode(UInt64(intValue))
        }
        data.encode(value)
        count += prependLength ? 1 : 0
    }

    func encode(_ value: String, forKey key: Key) throws {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let intValue = key.intValue {
            data.encode(UInt64(intValue))
        }
        data.encode(value)
        count += prependLength ? 1 : 0
    }

    func encode(_ value: Double, forKey key: Key) throws {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let intValue = key.intValue {
            data.encode(UInt64(intValue))
        }
        data.encode(value)
        count += prependLength ? 1 : 0
    }

    func encode(_ value: Float, forKey key: Key) throws {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let intValue = key.intValue {
            data.encode(UInt64(intValue))
        }
        data.encode(value)
        count += prependLength ? 1 : 0
    }

    func encode(_ value: Int, forKey key: Key) throws {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let intValue = key.intValue {
            data.encode(UInt64(intValue))
        }
        data.encode(value)
        count += prependLength ? 1 : 0
    }

    func encode(_ value: Int8, forKey key: Key) throws {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let intValue = key.intValue {
            data.encode(UInt64(intValue))
        }
        data.encode(value)
        count += prependLength ? 1 : 0
    }

    func encode(_ value: Int16, forKey key: Key) throws {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let intValue = key.intValue {
            data.encode(UInt64(intValue))
        }
        data.encode(value)
        count += prependLength ? 1 : 0
    }

    func encode(_ value: Int32, forKey key: Key) throws {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let intValue = key.intValue {
            data.encode(UInt64(intValue))
        }
        data.encode(value)
        count += prependLength ? 1 : 0
    }

    func encode(_ value: Int64, forKey key: Key) throws {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let intValue = key.intValue {
            data.encode(UInt64(intValue))
        }
        data.encode(value)
        count += prependLength ? 1 : 0
    }

    func encode(_ value: UInt, forKey key: Key) throws {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let intValue = key.intValue {
            data.encode(UInt64(intValue))
        }
        data.encode(value)
        count += prependLength ? 1 : 0
    }

    func encode(_ value: UInt8, forKey key: Key) throws {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let intValue = key.intValue {
            data.encode(UInt64(intValue))
        }
        data.encode(value)
        count += prependLength ? 1 : 0
    }

    func encode(_ value: UInt16, forKey key: Key) throws {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let intValue = key.intValue {
            data.encode(UInt64(intValue))
        }
        data.encode(value)
        count += prependLength ? 1 : 0
    }

    func encode(_ value: UInt32, forKey key: Key) throws {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let intValue = key.intValue {
            data.encode(UInt64(intValue))
        }
        data.encode(value)
        count += prependLength ? 1 : 0
    }

    func encode(_ value: UInt64, forKey key: Key) throws {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let intValue = key.intValue {
            data.encode(UInt64(intValue))
        }
        data.encode(value)
        count += prependLength ? 1 : 0
    }

    func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let intValue = key.intValue {
            data.encode(UInt64(intValue))
        }
        let encoding = PostcardEncoding(to: data)
        try value.encode(to: encoding)
        count += prependLength ? 1 : 0
    }

    func nestedContainer<NestedKey: CodingKey>(
        keyedBy _: NestedKey.Type,
        forKey key: Key
    ) -> KeyedEncodingContainer<NestedKey> {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let intValue = key.intValue {
            data.encode(UInt64(intValue))
        }
        let container = PostcardKeyedEncoding<NestedKey>(to: data)
        count += prependLength ? 1 : 0
        return KeyedEncodingContainer(container)
    }

    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let intValue = key.intValue {
            data.encode(UInt64(intValue))
        }
        count += prependLength ? 1 : 0
        return PostcardUnkeyedEncoding(to: data)
    }

    func superEncoder() -> Encoder {
        count += prependLength ? 1 : 0
        return PostcardEncoding(to: data)
    }

    func superEncoder(forKey key: Key) -> Encoder {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let intValue = key.intValue {
            data.encode(UInt64(intValue))
        }
        return superEncoder()
    }

    func encodeIfPresent(_ value: Bool?, forKey key: Key) throws {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let intValue = key.intValue {
            data.encode(UInt64(intValue))
        }
        if let value {
            data.encode(UInt8(1))
            data.encode(value)
        } else {
            data.encodeNil()
        }
        count += prependLength ? 1 : 0
    }

    func encodeIfPresent(_ value: String?, forKey key: Key) throws {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let intValue = key.intValue {
            data.encode(UInt64(intValue))
        }
        if let value {
            data.encode(UInt8(1))
            data.encode(value)
        } else {
            data.encodeNil()
        }
        count += prependLength ? 1 : 0
    }

    func encodeIfPresent(_ value: Double?, forKey key: Key) throws {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let intValue = key.intValue {
            data.encode(UInt64(intValue))
        }
        if let value {
            data.encode(UInt8(1))
            data.encode(value)
        } else {
            data.encodeNil()
        }
        count += prependLength ? 1 : 0
    }

    func encodeIfPresent(_ value: Float?, forKey key: Key) throws {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let value {
            data.encode(UInt8(1))
            data.encode(value)
        } else {
            data.encodeNil()
        }
        count += prependLength ? 1 : 0
    }

    func encodeIfPresent(_ value: Int?, forKey key: Key) throws {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let value {
            data.encode(UInt8(1))
            data.encode(value)
        } else {
            data.encodeNil()
        }
        count += prependLength ? 1 : 0
    }

    func encodeIfPresent(_ value: Int8?, forKey key: Key) throws {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let value {
            data.encode(UInt8(1))
            data.encode(value)
        } else {
            data.encodeNil()
        }
        count += prependLength ? 1 : 0
    }

    func encodeIfPresent(_ value: Int16?, forKey key: Key) throws {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let value {
            data.encode(UInt8(1))
            data.encode(value)
        } else {
            data.encodeNil()
        }
        count += prependLength ? 1 : 0
    }

    func encodeIfPresent(_ value: Int32?, forKey key: Key) throws {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let value {
            data.encode(UInt8(1))
            data.encode(value)
        } else {
            data.encodeNil()
        }
        count += prependLength ? 1 : 0
    }

    func encodeIfPresent(_ value: Int64?, forKey key: Key) throws {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let value {
            data.encode(UInt8(1))
            data.encode(value)
        } else {
            data.encodeNil()
        }
        count += prependLength ? 1 : 0
    }

    func encodeIfPresent(_ value: UInt?, forKey key: Key) throws {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let value {
            data.encode(UInt8(1))
            data.encode(value)
        } else {
            data.encodeNil()
        }
        count += prependLength ? 1 : 0
    }

    func encodeIfPresent(_ value: UInt8?, forKey key: Key) throws {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let value {
            data.encode(UInt8(1))
            data.encode(value)
        } else {
            data.encodeNil()
        }
        count += prependLength ? 1 : 0
    }

    func encodeIfPresent(_ value: UInt16?, forKey key: Key) throws {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let value {
            data.encode(UInt8(1))
            data.encode(value)
        } else {
            data.encodeNil()
        }
        count += prependLength ? 1 : 0
    }

    func encodeIfPresent(_ value: UInt32?, forKey key: Key) throws {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let value {
            data.encode(UInt8(1))
            data.encode(value)
        } else {
            data.encodeNil()
        }
        count += prependLength ? 1 : 0
    }

    func encodeIfPresent(_ value: UInt64?, forKey key: Key) throws {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let value {
            data.encode(UInt8(1))
            data.encode(value)
        } else {
            data.encodeNil()
        }
        count += prependLength ? 1 : 0
    }

    func encodeIfPresent<T: Encodable>(_ value: T?, forKey key: Key) throws {
        if useKeys {
            data.encode(key.stringValue)
        }
        if let value {
            data.encode(UInt8(1))
            let encoding = PostcardEncoding(to: data)
            try value.encode(to: encoding)
        } else {
            data.encodeNil()
        }
        count += prependLength ? 1 : 0
    }
}

private class PostcardUnkeyedEncoding: UnkeyedEncodingContainer {
    private let data: PostcardContainer

    private let lengthLocation: Int

    required init(to data: PostcardContainer) {
        self.data = data
        self.lengthLocation = data.reserve()
    }

    deinit {
        data.removeReserve(at: lengthLocation)
    }

    var codingPath: [CodingKey] = []

    private(set) var count: Int = 0 {
        didSet {
            data.update(at: lengthLocation, with: UInt64(count))
        }
    }

    func encodeNil() throws {
        data.encodeNil()
        count += 1
    }

    func encode(_ value: Bool) throws {
        data.encode(value)
        count += 1
    }

    func encode(_ value: String) throws {
        data.encode(value)
        count += 1
    }

    func encode(_ value: Double) throws {
        data.encode(value)
        count += 1
    }

    func encode(_ value: Float) throws {
        data.encode(value)
        count += 1
    }

    func encode(_ value: Int) throws {
        data.encode(value)
        count += 1
    }

    func encode(_ value: Int8) throws {
        data.encode(value)
        count += 1
    }

    func encode(_ value: Int16) throws {
        data.encode(value)
        count += 1
    }

    func encode(_ value: Int32) throws {
        data.encode(value)
        count += 1
    }

    func encode(_ value: Int64) throws {
        data.encode(value)
        count += 1
    }

    func encode(_ value: UInt) throws {
        data.encode(value)
        count += 1
    }

    func encode(_ value: UInt8) throws {
        data.encode(value)
        count += 1
    }

    func encode(_ value: UInt16) throws {
        data.encode(value)
        count += 1
    }

    func encode(_ value: UInt32) throws {
        data.encode(value)
        count += 1
    }

    func encode(_ value: UInt64) throws {
        data.encode(value)
        count += 1
    }

    func encode<T: Encodable>(_ value: T) throws {
        let encoding = PostcardEncoding(to: data)
        try value.encode(to: encoding)
        count += 1
    }

    func encodeIfPresent(_ value: Bool?) throws {
        if let value {
            data.encode(UInt8(1))
            data.encode(value)
        } else {
            data.encodeNil()
        }
        count += 1
    }

    func encodeIfPresent(_ value: String?) throws {
        if let value {
            data.encode(UInt8(1))
            data.encode(value)
        } else {
            data.encodeNil()
        }
        count += 1
    }

    func encodeIfPresent(_ value: Double?) throws {
        if let value {
            data.encode(UInt8(1))
            data.encode(value)
        } else {
            data.encodeNil()
        }
        count += 1
    }

    func encodeIfPresent(_ value: Float?) throws {
        if let value {
            data.encode(UInt8(1))
            data.encode(value)
        } else {
            data.encodeNil()
        }
        count += 1
    }

    func encodeIfPresent(_ value: Int?) throws {
        if let value {
            data.encode(UInt8(1))
            data.encode(value)
        } else {
            data.encodeNil()
        }
        count += 1
    }

    func encodeIfPresent(_ value: Int8?) throws {
        if let value {
            data.encode(UInt8(1))
            data.encode(value)
        } else {
            data.encodeNil()
        }
        count += 1
    }

    func encodeIfPresent(_ value: Int16?) throws {
        if let value {
            data.encode(UInt8(1))
            data.encode(value)
        } else {
            data.encodeNil()
        }
        count += 1
    }

    func encodeIfPresent(_ value: Int32?) throws {
        if let value {
            data.encode(UInt8(1))
            data.encode(value)
        } else {
            data.encodeNil()
        }
        count += 1
    }

    func encodeIfPresent(_ value: Int64?) throws {
        if let value {
            data.encode(UInt8(1))
            data.encode(value)
        } else {
            data.encodeNil()
        }
        count += 1
    }

    func encodeIfPresent(_ value: UInt?) throws {
        if let value {
            data.encode(UInt8(1))
            data.encode(value)
        } else {
            data.encodeNil()
        }
        count += 1
    }

    func encodeIfPresent(_ value: UInt8?) throws {
        if let value {
            data.encode(UInt8(1))
            data.encode(value)
        } else {
            data.encodeNil()
        }
        count += 1
    }

    func encodeIfPresent(_ value: UInt16?) throws {
        if let value {
            data.encode(UInt8(1))
            data.encode(value)
        } else {
            data.encodeNil()
        }
        count += 1
    }

    func encodeIfPresent(_ value: UInt32?) throws {
        if let value {
            data.encode(UInt8(1))
            data.encode(value)
        } else {
            data.encodeNil()
        }
        count += 1
    }

    func encodeIfPresent(_ value: UInt64?) throws {
        if let value {
            data.encode(UInt8(1))
            data.encode(value)
        } else {
            data.encodeNil()
        }
        count += 1
    }

    func encodeIfPresent<T: Encodable>(_ value: T?) throws {
        if let value {
            data.encode(UInt8(1))
            try encode(value)
        } else {
            data.encodeNil()
            count += 1
        }
    }

    func nestedContainer<NestedKey: CodingKey>(
        keyedBy _: NestedKey.Type
    ) -> KeyedEncodingContainer<NestedKey> {
        let container = PostcardKeyedEncoding<NestedKey>(to: data)
        count += 1
        return KeyedEncodingContainer(container)
    }

    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        count += 1
        return Self(to: data)
    }

    func superEncoder() -> Encoder {
        count += 1
        return PostcardEncoding(to: data)
    }
}

private struct PostcardSingleValueEncoding: SingleValueEncodingContainer {
    private let data: PostcardContainer

    init(to data: PostcardContainer) {
        self.data = data
    }

    var codingPath: [CodingKey] = []

    mutating func encodeNil() throws {
        data.encodeNil()
    }

    mutating func encode(_ value: Bool) throws {
        data.encode(value)
    }

    mutating func encode(_ value: String) throws {
        data.encode(value)
    }

    mutating func encode(_ value: Double) throws {
        data.encode(value)
    }

    mutating func encode(_ value: Float) throws {
        data.encode(value)
    }

    mutating func encode(_ value: Int) throws {
        data.encode(value)
    }

    mutating func encode(_ value: Int8) throws {
        data.encode(value)
    }

    mutating func encode(_ value: Int16) throws {
        data.encode(value)
    }

    mutating func encode(_ value: Int32) throws {
        data.encode(value)
    }

    mutating func encode(_ value: Int64) throws {
        data.encode(value)
    }

    mutating func encode(_ value: UInt) throws {
        data.encode(value)
    }

    mutating func encode(_ value: UInt8) throws {
        data.encode(value)
    }

    mutating func encode(_ value: UInt16) throws {
        data.encode(value)
    }

    mutating func encode(_ value: UInt32) throws {
        data.encode(value)
    }

    mutating func encode(_ value: UInt64) throws {
        data.encode(value)
    }

    mutating func encode<T: Encodable>(_ value: T) throws {
        let encoding = PostcardEncoding(to: data)
        try value.encode(to: encoding)
    }
}
