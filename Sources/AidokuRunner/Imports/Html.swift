//
//  Html.swift
//  AidokuRunner
//
//  Created by Skitty on 4/1/24.
//

import Foundation
import SwiftSoup
import Wasm3

struct Html: SourceLibrary {
    static let namespace = "html"

    let module: Module
    let store: GlobalStore

    func link() throws {
        try? module.linkFunction(name: "parse", namespace: Self.namespace, function: parse)
        try? module.linkFunction(name: "parse_fragment", namespace: Self.namespace, function: parseFragment)
        try? module.linkFunction(name: "escape", namespace: Self.namespace, function: escape)
        try? module.linkFunction(name: "unescape", namespace: Self.namespace, function: unescape)

        // `Elements` and `Element` functions
        try? module.linkFunction(name: "select", namespace: Self.namespace, function: select)
        try? module.linkFunction(name: "select_first", namespace: Self.namespace, function: selectFirst)
        try? module.linkFunction(name: "attr", namespace: Self.namespace, function: attr)
        try? module.linkFunction(name: "text", namespace: Self.namespace, function: text)
        try? module.linkFunction(name: "untrimmed_text", namespace: Self.namespace, function: untrimmedText)
        try? module.linkFunction(name: "html", namespace: Self.namespace, function: html)
        try? module.linkFunction(name: "outer_html", namespace: Self.namespace, function: outerHtml)

        // `Element` functions
        try? module.linkFunction(name: "set_text", namespace: Self.namespace, function: setText)
        try? module.linkFunction(name: "set_html", namespace: Self.namespace, function: setHtml)
        try? module.linkFunction(name: "prepend", namespace: Self.namespace, function: prepend)
        try? module.linkFunction(name: "append", namespace: Self.namespace, function: append)
        try? module.linkFunction(name: "next", namespace: Self.namespace, function: next)
        try? module.linkFunction(name: "previous", namespace: Self.namespace, function: previous)
        try? module.linkFunction(name: "base_uri", namespace: Self.namespace, function: baseUri)
        try? module.linkFunction(name: "own_text", namespace: Self.namespace, function: ownText)
        try? module.linkFunction(name: "data", namespace: Self.namespace, function: data)
        try? module.linkFunction(name: "id", namespace: Self.namespace, function: id)
        try? module.linkFunction(name: "tag_name", namespace: Self.namespace, function: tagName)
        try? module.linkFunction(name: "class_name", namespace: Self.namespace, function: className)
        try? module.linkFunction(name: "has_class", namespace: Self.namespace, function: hasClass)
        try? module.linkFunction(name: "has_attr", namespace: Self.namespace, function: hasAttr)

        // `Elements` functions
        try? module.linkFunction(name: "first", namespace: Self.namespace, function: first)
        try? module.linkFunction(name: "last", namespace: Self.namespace, function: last)
        try? module.linkFunction(name: "get", namespace: Self.namespace, function: get)
        try? module.linkFunction(name: "size", namespace: Self.namespace, function: size)
    }

    enum Result: Int32 {
        case success = 0
        case invalidDescriptor = -1
        case invalidString = -2
        case invalidHtml = -3
        case invalidQuery = -4
        case noResult = -5
        case swiftSoupError = -6
    }
}

extension Html {
    private func readString(memory: Memory, offset: Int32, length: Int32) -> String? {
        guard offset >= 0, length > 0 else { return nil }
        return try? memory.readString(offset: UInt32(offset), length: UInt32(length))
    }

    func parse(
        _ memory: Memory,
        html: Int32,
        htmlLength: Int32,
        baseUrl: Int32,
        baseUrlLength: Int32
    ) -> Int32 {
        guard let htmlString = readString(memory: memory, offset: html, length: htmlLength)
        else { return Result.invalidString.rawValue }

        let baseUrl = readString(memory: memory, offset: baseUrl, length: baseUrlLength)

        do {
            let document = if let baseUrl {
                try SwiftSoup.parse(htmlString, baseUrl)
            } else {
                try SwiftSoup.parse(htmlString)
            }
            return store.store(document)
        } catch {
            return Result.invalidHtml.rawValue
        }
    }

    func parseFragment(
        _ memory: Memory,
        html: Int32,
        htmlLength: Int32,
        baseUrl: Int32,
        baseUrlLength: Int32
    ) -> Int32 {
        guard let htmlString = readString(memory: memory, offset: html, length: htmlLength)
        else { return Result.invalidString.rawValue }

        let baseUrl = readString(memory: memory, offset: baseUrl, length: baseUrlLength)

        do {
            let document = if let baseUrl {
                try SwiftSoup.parseBodyFragment(htmlString, baseUrl)
            } else {
                try SwiftSoup.parseBodyFragment(htmlString)
            }
            return store.store(document)
        } catch {
            return Result.invalidHtml.rawValue
        }
    }

    func escape(_ memory: Memory, text: Int32, textLength: Int32) -> Int32 {
        guard let textString = readString(memory: memory, offset: text, length: textLength)
        else { return Result.invalidString.rawValue }
        return store.store(Entities.escape(textString))
    }

    func unescape(_ memory: Memory, text: Int32, textLength: Int32) -> Int32 {
        guard let textString = readString(memory: memory, offset: text, length: textLength)
        else { return Result.invalidString.rawValue }
        do {
            return store.store(try Entities.unescape(textString))
        } catch {
            return Result.swiftSoupError.rawValue
        }
    }
}

// MARK: `Elements` and `Element` functions
extension Html {
    func select(_ memory: Memory, descriptor: Int32, query: Int32, queryLength: Int32) -> Int32 {
        guard let item = store.fetch(from: descriptor)
        else { return Result.invalidDescriptor.rawValue }

        guard let queryString = readString(memory: memory, offset: query, length: queryLength)
        else { return Result.invalidString.rawValue }

        do {
            let elements: Elements? = if let baseElements = item as? Elements {
                try baseElements.select(queryString)
            } else if let element = item as? Element {
                try element.select(queryString)
            } else {
                nil
            }

            if let elements {
                return store.store(elements)
            } else {
                return Result.noResult.rawValue
            }
        } catch {
            return Result.invalidQuery.rawValue
        }
    }

    func selectFirst(_ memory: Memory, descriptor: Int32, query: Int32, queryLength: Int32) -> Int32 {
        let selectResult = select(memory, descriptor: descriptor, query: query, queryLength: queryLength)
        if selectResult < 0 {
            return selectResult
        }
        defer { store.remove(at: selectResult) }
        guard let element = (store.fetch(from: selectResult) as? Elements)?.first() else {
            return Result.noResult.rawValue
        }
        return store.store(element)
    }

    func attr(_ memory: Memory, descriptor: Int32, key: Int32, keyLength: Int32) -> Int32 {
        guard let item = store.fetch(from: descriptor)
        else { return Result.invalidDescriptor.rawValue }

        guard let keyString = readString(memory: memory, offset: key, length: keyLength)
        else { return Result.invalidString.rawValue }

        let attr: String? = if let elements = item as? Elements {
            try? elements.attr(keyString)
        } else if let element = item as? Element {
            try? element.attr(keyString)
        } else {
            nil
        }

        if let attr {
            return store.store(attr)
        } else {
            return Result.noResult.rawValue
        }
    }

    func text(descriptor: Int32) -> Int32 {
        guard let item = store.fetch(from: descriptor)
        else { return Result.invalidDescriptor.rawValue }

        let text: String? = if let elements = item as? Elements {
            try? elements.text()
        } else if let element = item as? Element {
            try? element.text()
        } else {
            nil
        }

        if let text {
            return store.store(text)
        } else {
            return Result.noResult.rawValue
        }
    }

    func untrimmedText(descriptor: Int32) -> Int32 {
        guard let item = store.fetch(from: descriptor)
        else { return Result.invalidDescriptor.rawValue }

        let text: String? = if let elements = item as? Elements {
            try? elements.text(trimAndNormaliseWhitespace: false)
        } else if let element = item as? Element {
            try? element.text(trimAndNormaliseWhitespace: false)
        } else {
            nil
        }

        if let text {
            return store.store(text)
        } else {
            return Result.noResult.rawValue
        }
    }

    func html(descriptor: Int32) -> Int32 {
        guard let item = store.fetch(from: descriptor)
        else { return Result.invalidDescriptor.rawValue }

        let text: String? = if let elements = item as? Elements {
            try? elements.html()
        } else if let element = item as? Element {
            try? element.html()
        } else {
            nil
        }

        if let text {
            return store.store(text)
        } else {
            return Result.noResult.rawValue
        }
    }

    func outerHtml(descriptor: Int32) -> Int32 {
        guard let item = store.fetch(from: descriptor)
        else { return Result.invalidDescriptor.rawValue }

        let text: String? = if let elements = item as? Elements {
            try? elements.outerHtml()
        } else if let element = item as? Element {
            try? element.outerHtml()
        } else {
            nil
        }

        if let text {
            return store.store(text)
        } else {
            return Result.noResult.rawValue
        }
    }
}

// MARK: `Element` functions
extension Html {
    func next(descriptor: Int32) -> Int32 {
        guard let element = store.fetch(from: descriptor) as? Element
        else { return Result.invalidDescriptor.rawValue }

        if let element = try? element.nextElementSibling() {
            return store.store(element)
        }

        return Result.noResult.rawValue
    }

    func previous(descriptor: Int32) -> Int32 {
        guard let element = store.fetch(from: descriptor) as? Element
        else { return Result.invalidDescriptor.rawValue }

        if let element = try? element.previousElementSibling() {
            return store.store(element)
        }

        return Result.noResult.rawValue
    }

    func setText(memory: Memory, descriptor: Int32, text: Int32, textLength: Int32) -> Int32 {
        guard let element = store.fetch(from: descriptor) as? Element
        else { return Result.invalidDescriptor.rawValue }

        guard let textString = readString(memory: memory, offset: text, length: textLength)
        else { return Result.invalidString.rawValue }

        do {
            try element.text(textString)
        } catch {
            return Result.swiftSoupError.rawValue
        }

        return Result.success.rawValue
    }

    func setHtml(memory: Memory, descriptor: Int32, text: Int32, textLength: Int32) -> Int32 {
        guard let element = store.fetch(from: descriptor) as? Element
        else { return Result.invalidDescriptor.rawValue }

        guard let textString = readString(memory: memory, offset: text, length: textLength)
        else { return Result.invalidString.rawValue }

        do {
            try element.html(textString)
        } catch {
            return Result.swiftSoupError.rawValue
        }

        return Result.success.rawValue
    }

    func prepend(memory: Memory, descriptor: Int32, text: Int32, textLength: Int32) -> Int32 {
        guard let element = store.fetch(from: descriptor) as? Element
        else { return Result.invalidDescriptor.rawValue }

        guard let textString = readString(memory: memory, offset: text, length: textLength)
        else { return Result.invalidString.rawValue }

        do {
            try element.prepend(textString)
        } catch {
            return Result.swiftSoupError.rawValue
        }

        return Result.success.rawValue
    }

    func append(memory: Memory, descriptor: Int32, text: Int32, textLength: Int32) -> Int32 {
        guard let element = store.fetch(from: descriptor) as? Element
        else { return Result.invalidDescriptor.rawValue }

        guard let textString = readString(memory: memory, offset: text, length: textLength)
        else { return Result.invalidString.rawValue }

        do {
            try element.append(textString)
        } catch {
            return Result.swiftSoupError.rawValue
        }

        return Result.success.rawValue
    }

    func baseUri(descriptor: Int32) -> Int32 {
        guard let element = store.fetch(from: descriptor) as? Element
        else { return Result.invalidDescriptor.rawValue }
        return store.store(element.getBaseUri())
    }

    func ownText(descriptor: Int32) -> Int32 {
        guard let element = store.fetch(from: descriptor) as? Element
        else { return Result.invalidDescriptor.rawValue }
        return store.store(element.ownText())
    }

    func data(descriptor: Int32) -> Int32 {
        guard let element = store.fetch(from: descriptor) as? Element
        else { return Result.invalidDescriptor.rawValue }
        return store.store(element.data())
    }

    func id(descriptor: Int32) -> Int32 {
        guard let element = store.fetch(from: descriptor) as? Element
        else { return Result.invalidDescriptor.rawValue }
        return store.store(element.id())
    }

    func tagName(descriptor: Int32) -> Int32 {
        guard let element = store.fetch(from: descriptor) as? Element
        else { return Result.invalidDescriptor.rawValue }
        return store.store(element.tagName())
    }

    func className(descriptor: Int32) -> Int32 {
        guard let element = store.fetch(from: descriptor) as? Element
        else { return Result.invalidDescriptor.rawValue }
        do {
            return try store.store(element.className())
        } catch {
            return Result.swiftSoupError.rawValue
        }
    }

    func hasClass(memory: Memory, descriptor: Int32, classOffset: Int32, classLength: Int32) -> Int32 {
        guard let element = store.fetch(from: descriptor) as? Element
        else { return Result.invalidDescriptor.rawValue }

        guard let className = readString(memory: memory, offset: classOffset, length: classLength)
        else { return Result.invalidString.rawValue }

        return element.hasClass(className) ? 1 : 0
    }

    func hasAttr(memory: Memory, descriptor: Int32, attrOffset: Int32, attrLength: Int32) -> Int32 {
        guard let element = store.fetch(from: descriptor) as? Element
        else { return 0 }

        guard let attr = readString(memory: memory, offset: attrOffset, length: attrLength)
        else { return 0 }

        return element.hasAttr(attr) ? 1 : 0
    }
}

// MARK: `Elements` functions
extension Html {
    func first(descriptor: Int32) -> Int32 {
        guard let elements = store.fetch(from: descriptor) as? Elements
        else { return Result.invalidDescriptor.rawValue }

        if let element = elements.first() {
            return store.store(element)
        }

        return Result.noResult.rawValue
    }

    func last(descriptor: Int32) -> Int32 {
        guard let elements = store.fetch(from: descriptor) as? Elements
        else { return Result.invalidDescriptor.rawValue }

        if let element = elements.last() {
            return store.store(element)
        }

        return Result.noResult.rawValue
    }

    func get(descriptor: Int32, index: Int32) -> Int32 {
        guard let elements = store.fetch(from: descriptor) as? Elements
        else { return Result.invalidDescriptor.rawValue }

        let index = Int(index)
        if elements.indices.contains(index) {
            return store.store(elements.get(index))
        }

        return Result.noResult.rawValue
    }

    func size(descriptor: Int32) -> Int32 {
        guard let elements = store.fetch(from: descriptor) as? Elements
        else { return Result.invalidDescriptor.rawValue }
        return Int32(elements.size())
    }
}
