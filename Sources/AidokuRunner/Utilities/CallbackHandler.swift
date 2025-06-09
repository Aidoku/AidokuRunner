//
//  CallbackHandler.swift
//  AidokuRunner
//
//  Created by Skitty on 5/27/25.
//

import Foundation

actor CallbackHandler {
    typealias Partial = (any Sendable)?
    typealias Callback = (Partial, Data) async -> Partial

    private var callbacks: [UUID: Callback] = [:]
    private var storage: [UUID: Partial] = [:]

    func registerCallback(_ callback: @escaping @Sendable Callback) -> UUID {
        let id = UUID()
        callbacks[id] = callback
        return id
    }

    func removeCallback(id: UUID) {
        callbacks.removeValue(forKey: id)
    }

    func getData(for key: UUID) -> Partial {
        storage[key]
    }

    func triggerCallbacks(with item: Data) async {
        for callback in callbacks {
            let stored = storage[callback.key]
            let result = await callback.value(stored, item)
            storage[callback.key] = result
        }
    }
}
