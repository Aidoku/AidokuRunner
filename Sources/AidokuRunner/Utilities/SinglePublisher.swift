//
//  SinglePublisher.swift
//  AidokuRunner
//
//  Created by Skitty on 5/28/25.
//

import Foundation

public actor SinglePublisher<T: Sendable> {
    var sink: ((T) -> Void)?

    public func send(_ value: T) {
        sink?(value)
    }

    public func sink(to closure: @escaping (T) -> Void) {
        sink = closure
    }

    public func removeSink() {
        sink = nil
    }
}
