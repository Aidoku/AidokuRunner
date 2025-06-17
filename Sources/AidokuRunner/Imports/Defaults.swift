//
//  Defaults.swift
//  AidokuRunner
//
//  Created by Skitty on 3/28/24.
//

import Foundation
import Wasm3

struct Defaults: SourceLibrary {
    static let namespace = "defaults"

    let module: Module
    let store: GlobalStore
    let defaultNamespace: String

    func link() throws {
        try? module.linkFunction(name: "get", namespace: Self.namespace, function: get)
        try? module.linkFunction(name: "set", namespace: Self.namespace, function: set)
    }

    enum Result: Int32 {
        case success = 0
        case invalidKey = -1
        case invalidValue = -2
        case failedEncoding = -3
        case failedDecoding = -4
    }

    enum DefaultKind: UInt8 {
        case data = 0
        case bool = 1
        case int = 2
        case float = 3
        case string = 4
        case stringArray = 5
        case null = 6
    }
}

extension Defaults {
    func get(memory: Memory, keyPointer: Int32, length: Int32) -> Int32 {
        guard keyPointer >= 0, length >= 0 else {
            return Result.invalidKey.rawValue
        }
        do {
            let key = try memory.readString(offset: UInt32(keyPointer), length: UInt32(length))
            let object = SettingsStore.shared.object(key: "\(defaultNamespace).\(key)")
            switch object {
                case let object as Bool:
                    return try store.storeEncoded(object)
                case let object as Int32:
                    return try store.storeEncoded(object)
                case let object as Float:
                    return try store.storeEncoded(object)
                case let object as String:
                    return try store.storeEncoded(object)
                case let object as [String]:
                    return try store.storeEncoded(object)
                case let object as Codable:
                    return try store.storeEncoded(object)
                case let object as Data:
                    return store.store(object)
                default:
                    return Result.invalidValue.rawValue
            }
        } catch {
            return Result.failedEncoding.rawValue
        }
    }

    func set(
        memory: Memory,
        keyPointer: Int32,
        length: Int32,
        valueKind: Int32,
        valuePointer: Int32
    ) -> Int32 {
        guard keyPointer >= 0, length >= 0 else {
            return Result.invalidKey.rawValue
        }
        do {
            let key = try memory.readString(offset: UInt32(keyPointer), length: UInt32(length))

            guard let valueKind = DefaultKind(rawValue: UInt8(valueKind)) else {
                return Result.invalidValue.rawValue
            }

            let getData = {
                let pointer = UInt32(valuePointer)
                let length: UInt32 = try memory.readValues(offset: pointer, length: 1)[0]
                return try memory.readData(offset: pointer + 8, length: length - 8)
            }

            let object: Any? = switch valueKind {
                case .data:
                    try getData()
                case .bool:
                    try PostcardDecoder().decode(Bool.self, from: getData())
                case .int:
                    Int(try PostcardDecoder().decode(Int32.self, from: getData()))
                case .float:
                    try PostcardDecoder().decode(Float.self, from: getData())
                case .string:
                    try PostcardDecoder().decode(String.self, from: getData())
                case .stringArray:
                    try PostcardDecoder().decode([String].self, from: getData())
                case .null:
                    nil
            }

            SettingsStore.shared.setValue(key: "\(defaultNamespace).\(key)", value: object)

            return Result.success.rawValue
        } catch {
            return Result.failedDecoding.rawValue
        }
    }
}
