//
//  BlockingTask.swift
//  AidokuRunner
//
//  Created by Skitty on 2/6/25.
//

import Foundation

final class BlockingTask<T>: @unchecked Sendable {
    let semaphore = DispatchSemaphore(value: 0)
    private var result: T?

    init(block: @escaping @Sendable () async -> T) {
        Task {
            result = await block()
            semaphore.signal()
        }
    }

    func get() -> T {
        if let result { return result }
        semaphore.wait()
        return result!
    }
}
