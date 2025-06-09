//
//  VarInt.swift
//  AidokuRunner
//
//  Created by Skitty on 1/5/25.
//

import Foundation

func zigZag(_ n: Int16) -> UInt16 {
    UInt16(bitPattern: n << 1 ^ n >> 15)
}

func zigZag(_ n: Int32) -> UInt32 {
    UInt32(bitPattern: n << 1 ^ n >> 31)
}

func zigZag(_ n: Int64) -> UInt64 {
    UInt64(bitPattern: n << 1 ^ n >> 63)
}

func varInt(_ n: UInt16, data: inout Data) {
    let start = data.count
    var value = n
    for offset in 0..<3 {
        data.append(UInt8(truncatingIfNeeded: value.littleEndian))
        if value < 128 {
            break
        }
        data[start + offset] |= 0x80
        value >>= 7
    }
}

func varInt(_ n: UInt32, data: inout Data) {
    let start = data.count
    var value = n
    for offset in 0..<5 {
        data.append(UInt8(truncatingIfNeeded: value.littleEndian))
        if value < 128 {
            break
        }
        data[start + offset] |= 0x80
        value >>= 7
    }
}

public func varInt(_ n: UInt64, data: inout Data) {
    let start = data.count
    var value = n
    for offset in 0..<10 {
        data.append(UInt8(truncatingIfNeeded: value.littleEndian))
        if value < 128 {
            break
        }
        data[start + offset] |= 0x80
        value >>= 7
    }
}

public func decodeVarInt<T: FixedWidthInteger>(_ data: Data, currentIndex: inout Data.Index) throws -> T {
    var result: T = 0
    var shift: T = 0
    while currentIndex < data.endIndex {
        let byte = data[currentIndex]
        currentIndex = data.index(after: currentIndex)
        result |= T(byte & 0x7F) << shift
        if byte & 0x80 == 0 {
            return result
        }
        shift += 7
    }
    throw DecodingError.dataCorrupted(DecodingError.Context(
        codingPath: [],
        debugDescription: "Invalid varint encoding")
    )
}

func decodeZigZag<T: FixedWidthInteger>(_ n: T) -> T where T: SignedInteger {
    (n >> 1) ^ (-(n & 1))
}
