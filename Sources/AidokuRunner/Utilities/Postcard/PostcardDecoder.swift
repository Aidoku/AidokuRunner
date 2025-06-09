//
//  PostcardDecoder.swift
//  AidokuRunner
//
//  Created by Skitty on 1/5/25.
//

import Combine
import Foundation

public class PostcardDecoder: TopLevelDecoder {
    public init() {
        // nothing to initialize
    }

    public func decode<T>(_: T.Type, from data: Data) throws -> T where T: Decodable {
        let decodingContainer: DecodingContainer = .init(data: data, currentIndex: data.startIndex)
        let decoding = PostcardDecoding(decodingContainer: decodingContainer)
        return try T(from: decoding)
    }
}

private class DecodingContainer {
    var data: Data
    var currentIndex: Data.Index

    init(data: Data, currentIndex: Data.Index) {
        self.data = data
        self.currentIndex = currentIndex
    }

    func decodeNil() throws -> Bool {
        guard currentIndex < data.endIndex else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: [],
                debugDescription: "Out of bytes")
            )
        }
        let byte = data[currentIndex]
        currentIndex += 1
        return byte == 0
    }

    func decode(_: Bool.Type) throws -> Bool {
        guard currentIndex < data.endIndex else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: [],
                debugDescription: "Out of bytes")
            )
        }
        let byte = data[currentIndex]
        currentIndex += 1
        return byte != 0
    }

    func decode(_: String.Type) throws -> String {
        let length: UInt64 = try decodeVarInt(data, currentIndex: &currentIndex)
        let endIndex = currentIndex.advanced(by: Int(truncatingIfNeeded: length))
        guard endIndex <= data.endIndex && endIndex >= currentIndex else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: [],
                debugDescription: "Invalid string length")
            )
        }
        let stringData = data[currentIndex..<endIndex]
        currentIndex = endIndex
        return String(data: stringData, encoding: .utf8) ?? ""
    }

    func decode(_: Double.Type) throws -> Double {
        let endIndex = currentIndex.advanced(by: MemoryLayout<Double>.size)
        guard endIndex <= data.endIndex else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: [],
                debugDescription: "Invalid double length")
            )
        }
        let value = Data(data[currentIndex..<endIndex])
        currentIndex = endIndex
        return Double(bitPattern: value.withUnsafeBytes { $0.load(as: UInt64.self) }.littleEndian)
    }

    func decode(_: Float.Type) throws -> Float {
        let endIndex = currentIndex.advanced(by: MemoryLayout<Float>.size)
        guard endIndex <= data.endIndex else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: [],
                debugDescription: "Invalid float length")
            )
        }
        let value = Data(data[currentIndex..<endIndex])
        currentIndex = endIndex
        return Float(bitPattern: value.withUnsafeBytes { $0.load(as: UInt32.self) }.littleEndian)
    }

    func decode(_: Int.Type) throws -> Int {
        Int(try decode(Int64.self))
    }

    func decode(_: Int8.Type) throws -> Int8 {
        let value: UInt8 = try decode(UInt8.self)
        return Int8(bitPattern: value)
    }

    func decode(_: Int16.Type) throws -> Int16 {
        let value: UInt16 = try decode(UInt16.self)
        return decodeZigZag(Int16(value))
    }

    func decode(_: Int32.Type) throws -> Int32 {
        let value: UInt32 = try decode(UInt32.self)
        return decodeZigZag(Int32(value))
    }

    func decode(_: Int64.Type) throws -> Int64 {
        let value: UInt64 = try decode(UInt64.self)
        return decodeZigZag(Int64(value))
    }

    func decode(_: UInt.Type) throws -> UInt {
        UInt(try decode(UInt64.self))
    }

    func decode(_: UInt8.Type) throws -> UInt8 {
        guard currentIndex < data.endIndex else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: [],
                debugDescription: "Ran out of bytes")
            )
        }
        let byte = data[currentIndex]
        currentIndex += 1
        return byte
    }

    func decode(_: UInt16.Type) throws -> UInt16 {
        try decodeVarInt(data, currentIndex: &currentIndex)
    }

    func decode(_: UInt32.Type) throws -> UInt32 {
        try decodeVarInt(data, currentIndex: &currentIndex)
    }

    func decode(_: UInt64.Type) throws -> UInt64 {
        try decodeVarInt(data, currentIndex: &currentIndex)
    }

    func decode<T>(_: T.Type) throws -> T where T: Decodable {
        try T(from: PostcardDecoding(decodingContainer: self))
    }
}

protocol OptionalProtocol {}

extension Optional: OptionalProtocol {}

private class PostcardDecoding: Decoder {
    let decodingContainer: DecodingContainer

    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey: Any] = [:]

    init(decodingContainer: DecodingContainer) {
        self.decodingContainer = decodingContainer
    }

    func container<Key>(keyedBy _: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        KeyedDecodingContainer(
            PostcardKeyedDecoding<Key>(
                decodingContainer: decodingContainer,
                codingPath: codingPath,
                userInfo: userInfo
            )
        )
    }

    func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
        PostcardUnkeyedDecoding(
            decodingContainer: decodingContainer,
            codingPath: codingPath,
            userInfo: userInfo
        )
    }

    func singleValueContainer() throws -> any SingleValueDecodingContainer {
        PostcardSingleValueDecoding(
            decodingContainer: decodingContainer,
            codingPath: codingPath,
            userInfo: userInfo
        )
    }
}

private class PostcardKeyedDecoding<Key: CodingKey>: KeyedDecodingContainerProtocol {
    let decodingContainer: DecodingContainer

    let usesKeys = false

    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any]
    var allKeys: [Key] = []

    init(
        decodingContainer: DecodingContainer,
        codingPath: [CodingKey],
        userInfo: [CodingUserInfoKey: Any]
    ) {
        self.decodingContainer = decodingContainer
        self.codingPath = codingPath
        self.userInfo = userInfo
    }

    func contains(_: Key) -> Bool {
        false
    }

    func decodeNil(forKey _: Key) throws -> Bool {
        try decodingContainer.decodeNil()
    }

    func decode(_ type: Bool.Type, forKey _: Key) throws -> Bool {
        try decodingContainer.decode(type)
    }

    func decode(_ type: String.Type, forKey _: Key) throws -> String {
        try decodingContainer.decode(type)
    }

    func decode(_ type: Double.Type, forKey _: Key) throws -> Double {
        try decodingContainer.decode(type)
    }

    func decode(_ type: Float.Type, forKey _: Key) throws -> Float {
        try decodingContainer.decode(type)
    }

    func decode(_ type: Int.Type, forKey _: Key) throws -> Int {
        try decodingContainer.decode(type)
    }

    func decode(_ type: Int8.Type, forKey _: Key) throws -> Int8 {
        try decodingContainer.decode(type)
    }

    func decode(_ type: Int16.Type, forKey _: Key) throws -> Int16 {
        try decodingContainer.decode(type)
    }

    func decode(_ type: Int32.Type, forKey _: Key) throws -> Int32 {
        try decodingContainer.decode(type)
    }

    func decode(_ type: Int64.Type, forKey _: Key) throws -> Int64 {
        try decodingContainer.decode(type)
    }

    func decode(_ type: UInt.Type, forKey _: Key) throws -> UInt {
        try decodingContainer.decode(type)
    }

    func decode(_ type: UInt8.Type, forKey _: Key) throws -> UInt8 {
        try decodingContainer.decode(type)
    }

    func decode(_ type: UInt16.Type, forKey _: Key) throws -> UInt16 {
        try decodingContainer.decode(type)
    }

    func decode(_ type: UInt32.Type, forKey _: Key) throws -> UInt32 {
        try decodingContainer.decode(type)
    }

    func decode(_ type: UInt64.Type, forKey _: Key) throws -> UInt64 {
        try decodingContainer.decode(type)
    }

    func decode<T>(_: T.Type, forKey _: Key) throws -> T where T: Decodable {
        try T(from: PostcardDecoding(decodingContainer: decodingContainer))
    }

    func decodeIfPresent(_ type: Bool.Type, forKey key: Key) throws -> Bool? {
        let isNil = try decodingContainer.decodeNil()
        if isNil {
            return nil
        }
        return try decode(type, forKey: key)
    }

    func decodeIfPresent(_ type: String.Type, forKey key: Key) throws -> String? {
        let isNil = try decodingContainer.decodeNil()
        if isNil {
            return nil
        }
        return try decode(type, forKey: key)
    }

    func decodeIfPresent(_ type: Double.Type, forKey key: Key) throws -> Double? {
        let isNil = try decodingContainer.decodeNil()
        if isNil {
            return nil
        }
        return try decode(type, forKey: key)
    }

    func decodeIfPresent(_ type: Float.Type, forKey key: Key) throws -> Float? {
        let isNil = try decodingContainer.decodeNil()
        if isNil {
            return nil
        }
        return try decode(type, forKey: key)
    }

    func decodeIfPresent(_ type: Int.Type, forKey key: Key) throws -> Int? {
        let isNil = try decodingContainer.decodeNil()
        if isNil {
            return nil
        }
        return try decode(type, forKey: key)
    }

    func decodeIfPresent(_ type: Int8.Type, forKey key: Key) throws -> Int8? {
        let isNil = try decodingContainer.decodeNil()
        if isNil {
            return nil
        }
        return try decode(type, forKey: key)
    }

    func decodeIfPresent(_ type: Int16.Type, forKey key: Key) throws -> Int16? {
        let isNil = try decodingContainer.decodeNil()
        if isNil {
            return nil
        }
        return try decode(type, forKey: key)
    }

    func decodeIfPresent(_ type: Int32.Type, forKey key: Key) throws -> Int32? {
        let isNil = try decodingContainer.decodeNil()
        if isNil {
            return nil
        }
        return try decode(type, forKey: key)
    }

    func decodeIfPresent(_ type: Int64.Type, forKey key: Key) throws -> Int64? {
        let isNil = try decodingContainer.decodeNil()
        if isNil {
            return nil
        }
        return try decode(type, forKey: key)
    }

    func decodeIfPresent(_ type: UInt.Type, forKey key: Key) throws -> UInt? {
        let isNil = try decodingContainer.decodeNil()
        if isNil {
            return nil
        }
        return try decode(type, forKey: key)
    }

    func decodeIfPresent(_ type: UInt8.Type, forKey key: Key) throws -> UInt8? {
        let isNil = try decodingContainer.decodeNil()
        if isNil {
            return nil
        }
        return try decode(type, forKey: key)
    }

    func decodeIfPresent(_ type: UInt16.Type, forKey key: Key) throws -> UInt16? {
        let isNil = try decodingContainer.decodeNil()
        if isNil {
            return nil
        }
        return try decode(type, forKey: key)
    }

    func decodeIfPresent(_ type: UInt32.Type, forKey key: Key) throws -> UInt32? {
        let isNil = try decodingContainer.decodeNil()
        if isNil {
            return nil
        }
        return try decode(type, forKey: key)
    }

    func decodeIfPresent(_ type: UInt64.Type, forKey key: Key) throws -> UInt64? {
        let isNil = try decodingContainer.decodeNil()
        if isNil {
            return nil
        }
        return try decode(type, forKey: key)
    }

    func decodeIfPresent<T>(_: T.Type, forKey key: Key) throws -> T? where T: Decodable {
        let isNil = try decodingContainer.decodeNil()
        if isNil {
            return nil
        }
        return try decode(T.self, forKey: key)
    }

    func nestedContainer<NestedKey>(
        keyedBy _: NestedKey.Type,
        forKey _: Key
    ) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        KeyedDecodingContainer(
            PostcardKeyedDecoding<NestedKey>(
                decodingContainer: decodingContainer,
                codingPath: codingPath,
                userInfo: userInfo
            )
        )
    }

    func nestedUnkeyedContainer(forKey _: Key) throws -> UnkeyedDecodingContainer {
        PostcardUnkeyedDecoding(
            decodingContainer: decodingContainer,
            codingPath: codingPath,
            userInfo: userInfo
        )
    }

    func superDecoder() throws -> Decoder {
        PostcardDecoding(decodingContainer: decodingContainer)
    }

    func superDecoder(forKey _: Key) throws -> Decoder {
        PostcardDecoding(decodingContainer: decodingContainer)
    }
}

private class PostcardUnkeyedDecoding: UnkeyedDecodingContainer {
    var decodingContainer: DecodingContainer
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any]

    var currentIndex: Int {
        decodingContainer.currentIndex
    }

    var count: Int?
    var currentCount = 0

    var isAtEnd: Bool {
        decodingContainer.currentIndex >= decodingContainer.data.endIndex || currentCount > count ?? 0
        // current count will be one ahead
    }

    init(
        decodingContainer: DecodingContainer,
        codingPath: [CodingKey],
        userInfo: [CodingUserInfoKey: Any]
    ) {
        self.decodingContainer = decodingContainer
        self.codingPath = codingPath
        self.userInfo = userInfo

        count = (try? decode(UInt64.self)).flatMap(Int.init)
    }

    func decodeNil() throws -> Bool {
        currentCount += 1
        return try decodingContainer.decodeNil()
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        currentCount += 1
        return try decodingContainer.decode(type)
    }

    func decode(_ type: String.Type) throws -> String {
        currentCount += 1
        return try decodingContainer.decode(type)
    }

    func decode(_ type: Double.Type) throws -> Double {
        currentCount += 1
        return try decodingContainer.decode(type)
    }

    func decode(_ type: Float.Type) throws -> Float {
        currentCount += 1
        return try decodingContainer.decode(type)
    }

    func decode(_ type: Int.Type) throws -> Int {
        currentCount += 1
        return try decodingContainer.decode(type)
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        currentCount += 1
        return try decodingContainer.decode(type)
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        currentCount += 1
        return try decodingContainer.decode(type)
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        currentCount += 1
        return try decodingContainer.decode(type)
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        currentCount += 1
        return try decodingContainer.decode(type)
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        currentCount += 1
        return try decodingContainer.decode(type)
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        currentCount += 1
        return try decodingContainer.decode(type)
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        currentCount += 1
        return try decodingContainer.decode(type)
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        currentCount += 1
        return try decodingContainer.decode(type)
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        currentCount += 1
        return try decodingContainer.decode(type)
    }

    func decode<T>(_: T.Type) throws -> T where T: Decodable {
        currentCount += 1
        return try T(from: PostcardDecoding(decodingContainer: decodingContainer))
    }

    func decodeIfPresent(_ type: Bool.Type) throws -> Bool? {
        let isNil = try decodingContainer.decodeNil()
        if isNil {
            currentCount += 1
            return nil
        }
        return try decode(type)
    }

    func decodeIfPresent(_ type: String.Type) throws -> String? {
        let isNil = try decodingContainer.decodeNil()
        if isNil {
            currentCount += 1
            return nil
        }
        return try decode(type)
    }

    func decodeIfPresent(_ type: Double.Type) throws -> Double? {
        let isNil = try decodingContainer.decodeNil()
        if isNil {
            currentCount += 1
            return nil
        }
        return try decode(type)
    }

    func decodeIfPresent(_ type: Float.Type) throws -> Float? {
        let isNil = try decodingContainer.decodeNil()
        if isNil {
            currentCount += 1
            return nil
        }
        return try decode(type)
    }

    func decodeIfPresent(_ type: Int.Type) throws -> Int? {
        let isNil = try decodingContainer.decodeNil()
        if isNil {
            currentCount += 1
            return nil
        }
        return try decode(type)
    }

    func decodeIfPresent(_ type: Int8.Type) throws -> Int8? {
        let isNil = try decodingContainer.decodeNil()
        if isNil {
            currentCount += 1
            return nil
        }
        return try decode(type)
    }

    func decodeIfPresent(_ type: Int16.Type) throws -> Int16? {
        let isNil = try decodingContainer.decodeNil()
        if isNil {
            currentCount += 1
            return nil
        }
        return try decode(type)
    }

    func decodeIfPresent(_ type: Int32.Type) throws -> Int32? {
        let isNil = try decodingContainer.decodeNil()
        if isNil {
            currentCount += 1
            return nil
        }
        return try decode(type)
    }

    func decodeIfPresent(_ type: Int64.Type) throws -> Int64? {
        let isNil = try decodingContainer.decodeNil()
        if isNil {
            currentCount += 1
            return nil
        }
        return try decode(type)
    }

    func decodeIfPresent(_ type: UInt.Type) throws -> UInt? {
        let isNil = try decodingContainer.decodeNil()
        if isNil {
            currentCount += 1
            return nil
        }
        return try decode(type)
    }

    func decodeIfPresent(_ type: UInt8.Type) throws -> UInt8? {
        let isNil = try decodingContainer.decodeNil()
        if isNil {
            currentCount += 1
            return nil
        }
        return try decode(type)
    }

    func decodeIfPresent(_ type: UInt16.Type) throws -> UInt16? {
        let isNil = try decodingContainer.decodeNil()
        if isNil {
            currentCount += 1
            return nil
        }
        return try decode(type)
    }

    func decodeIfPresent(_ type: UInt32.Type) throws -> UInt32? {
        let isNil = try decodingContainer.decodeNil()
        if isNil {
            currentCount += 1
            return nil
        }
        return try decode(type)
    }

    func decodeIfPresent(_ type: UInt64.Type) throws -> UInt64? {
        let isNil = try decodingContainer.decodeNil()
        if isNil {
            currentCount += 1
            return nil
        }
        return try decode(type)
    }

    func decodeIfPresent<T>(_: T.Type) throws -> T? where T: Decodable {
        let isNil = try decodingContainer.decodeNil()
        if isNil {
            currentCount += 1
            return nil
        }
        return try decode(T.self)
    }

    func nestedContainer<NestedKey>(
        keyedBy _: NestedKey.Type
    ) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        currentCount += 1
        return KeyedDecodingContainer(
            PostcardKeyedDecoding<NestedKey>(
                decodingContainer: decodingContainer,
                codingPath: codingPath,
                userInfo: userInfo
            )
        )
    }

    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        currentCount += 1
        return PostcardUnkeyedDecoding(
            decodingContainer: decodingContainer,
            codingPath: codingPath,
            userInfo: userInfo
        )
    }

    func superDecoder() throws -> Decoder {
        currentCount += 1
        return PostcardDecoding(decodingContainer: decodingContainer)
    }
}

private class PostcardSingleValueDecoding: SingleValueDecodingContainer {
    var decodingContainer: DecodingContainer
    var codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey: Any]

    init(
        decodingContainer: DecodingContainer,
        codingPath: [CodingKey],
        userInfo: [CodingUserInfoKey: Any]
    ) {
        self.decodingContainer = decodingContainer
        self.codingPath = codingPath
        self.userInfo = userInfo
    }

    func decodeNil() -> Bool {
        (try? decodingContainer.decodeNil()) ?? false
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        try decodingContainer.decode(type)
    }

    func decode(_ type: String.Type) throws -> String {
        try decodingContainer.decode(type)
    }

    func decode(_ type: Double.Type) throws -> Double {
        try decodingContainer.decode(type)
    }

    func decode(_ type: Float.Type) throws -> Float {
        try decodingContainer.decode(type)
    }

    func decode(_ type: Int.Type) throws -> Int {
        try decodingContainer.decode(type)
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        try decodingContainer.decode(type)
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        try decodingContainer.decode(type)
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        try decodingContainer.decode(type)
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        try decodingContainer.decode(type)
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        try decodingContainer.decode(type)
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        try decodingContainer.decode(type)
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        try decodingContainer.decode(type)
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        try decodingContainer.decode(type)
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        try decodingContainer.decode(type)
    }

    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        try decodingContainer.decode(type)
    }
}
