//
//  GlobalStore.swift
//  AidokuRunner
//
//  Created by Skitty on 8/13/23.
//

import Foundation

class GlobalStore {
    var storage: [Int32: Any] = [:]
    var pointer: Int32 = 1

    func store(_ item: Any) -> Int32 {
        let descriptor = pointer
        storage[descriptor] = item
        incrementPointer()
        return descriptor
    }

    func storeEncoded<T: Codable>(_ item: T) throws -> Int32 {
        try store(PostcardEncoder().encode(item))
    }

    func storeOptionalEncoded<T: Codable>(_ item: T?) throws -> Int32 {
        if let item {
            try store(PostcardEncoder().encode(item))
        } else {
            -1
        }
    }

    func fetch(from descriptor: Int32) -> Any? {
        storage[descriptor]
    }

    func set(at descriptor: Int32, item: Any) {
        storage[descriptor] = item
    }

    func remove(at descriptor: Int32) {
        storage.removeValue(forKey: descriptor)
        // reset the descriptor pointer if there aren't any items left
        if storage.isEmpty {
            pointer = 1
        }
    }

    func incrementPointer() {
        pointer += 1
    }
}

extension GlobalStore {
    func fetchImage(from descriptor: Int32) -> PlatformImage? {
        let result = fetch(from: descriptor)
        if let image = result as? PlatformImage {
            return image
        } else if let data = result as? Data, let image = PlatformImage(data: data) {
            return image
        } else {
            return nil
        }
    }
}
