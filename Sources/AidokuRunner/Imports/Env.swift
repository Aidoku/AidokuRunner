//
//  Env.swift
//  AidokuRunner
//
//  Created by Skitty on 7/16/23.
//

import Foundation
import Wasm3

struct Env: SourceLibrary {
    static let namespace = "env"

    let module: Module
    let partialValueHandler: CallbackHandler
    let printHandler: (String) -> Void

    func link() throws {
        try? module.linkFunction(name: "abort", namespace: Self.namespace, function: abort)
        try? module.linkFunction(name: "print", namespace: Self.namespace, function: envPrint)
        try? module.linkFunction(name: "sleep", namespace: Self.namespace, function: sleep)
        try? module.linkFunction(name: "send_partial_result", namespace: Self.namespace, function: sendPartialResult)
    }
}

extension Env {
    func abort() {
        printHandler("Aborted")
        Wasm3.yieldNext()
    }

    func envPrint(memory: Memory, offset: Int32, length: Int32) {
        guard offset >= 0, length >= 0 else { return }
        let string = try? memory.readString(offset: UInt32(offset), length: UInt32(length))
        printHandler(string ?? "")
    }

    func sleep(seconds: Int32) {
        BlockingTask {
            try? await Task.sleep(nanoseconds: UInt64(seconds) * 1_000_000_000)
        }.get()
    }
}

extension Env {
    func sendPartialResult(memory: Memory, valuePointer: Int32) {
        guard
            valuePointer >= 0,
            case let pointer = UInt32(valuePointer),
            let length: UInt32 = try? memory.readValues(offset: pointer, length: 1)[0],
            let data = try? memory.readData(offset: pointer + 8, length: length + 8)
        else {
            return
        }

        let partialValueHandler = partialValueHandler // capture actor
        BlockingTask {
            await partialValueHandler.triggerCallbacks(with: data)
        }.get()
    }
}
