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
