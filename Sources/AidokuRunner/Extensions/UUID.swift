//
//  UUID.swift
//  AidokuRunner
//
//  Created by skitty on 8/16/26.
//

import CryptoKit
import Foundation

extension UUID {
    init(sourceKey: String) {
        let data = Data(sourceKey.utf8)
        var bytes = Array(Insecure.SHA1.hash(data: data).prefix(16))
        // RFC 4122 UUID version 5
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        self = bytes.withUnsafeBufferPointer { buffer in
            // swiftlint:disable:next legacy_objc_type
            UUID(uuidString: NSUUID(uuidBytes: buffer.baseAddress!).uuidString)!
        }
    }
}
