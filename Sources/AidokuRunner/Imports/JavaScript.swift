//
//  JavaScript.swift
//  AidokuRunner
//
//  Created by Skitty on 12/30/24.
//

import Foundation
import JavaScriptCore
import Wasm3
import WebKit

struct JavaScript: SourceLibrary {
    static let namespace = "js"

    let module: Module
    let store: GlobalStore
    let printHandler: @Sendable (String) -> Void
    let webViewNamespace: String

    func link() {
        try? module.linkFunction(name: "context_create", namespace: Self.namespace, function: contextCreate)
        try? module.linkFunction(name: "context_eval", namespace: Self.namespace, function: contextEval)
        try? module.linkFunction(name: "context_eval_async", namespace: Self.namespace, function: contextEvalAsync)
        try? module.linkFunction(name: "context_get", namespace: Self.namespace, function: contextGet)

        try? module.linkFunction(name: "webview_create", namespace: Self.namespace, function: webViewCreate)
        try? module.linkFunction(name: "webview_set_rule_list", namespace: Self.namespace, function: webViewSetRuleList)
        try? module.linkFunction(name: "webview_load", namespace: Self.namespace, function: webViewLoad)
        try? module.linkFunction(name: "webview_load_html", namespace: Self.namespace, function: webViewLoadHtml)
        try? module.linkFunction(name: "webview_wait_for_load", namespace: Self.namespace, function: webViewWaitForLoad)
        try? module.linkFunction(name: "webview_eval", namespace: Self.namespace, function: webViewEval)
        try? module.linkFunction(name: "webview_eval_async", namespace: Self.namespace, function: webViewEvalAsync)
        try? module.linkFunction(
            name: "webview_add_user_script",
            namespace: Self.namespace,
            function: webViewAddUserScript
        )
        try? module.linkFunction(name: "webview_get_cookies", namespace: Self.namespace, function: webViewGetCookies)
        try? module.linkFunction(
            name: "webview_delete_cookie",
            namespace: Self.namespace,
            function: webViewDeleteCookie
        )
    }

    enum Result: Int32 {
        case success = 0
        case missingResult = -1
        case invalidContext = -2
        case invalidString = -3
        case invalidHandler = -4
        case invalidRequest = -5
        case invalidRuleList = -6
        case failedEncoding = -7
        case missingCookie = -8
    }
}

extension JavaScript {
    func contextCreate() -> Int32 {
        let context = IsolatedJSContext { [printHandler] _, exception in
            printHandler("JS Exception: \(exception?.toString() ?? "Unknown")")
        }
        return store.store(context)
    }

    func contextEval(memory: Memory, descriptor: Int32, stringPointer: Int32, length: Int32) -> Int32 {
        guard let context = store.fetch(from: descriptor) as? IsolatedJSContext
        else { return Result.invalidContext.rawValue }

        guard
            stringPointer >= 0, length > 0,
            let jsString = try? memory.readString(offset: UInt32(stringPointer), length: UInt32(length))
        else {
            return Result.invalidString.rawValue
        }

        let result = BlockingTask {
            await context.evaluateScript(jsString)
        }.get()

        guard let result else {
            return Result.missingResult.rawValue
        }

        return store.store(result)
    }

    func contextEvalAsync(memory: Memory, descriptor: Int32, stringPointer: Int32, length: Int32) -> Int32 {
        guard let context = store.fetch(from: descriptor) as? IsolatedJSContext
        else { return Result.invalidContext.rawValue }

        guard
            stringPointer >= 0, length > 0,
            let jsString = try? memory.readString(offset: UInt32(stringPointer), length: UInt32(length))
        else {
            return Result.invalidString.rawValue
        }

        let result: String? = BlockingTask { [printHandler] in
            do {
                return try await context.evaluateAsyncScript(jsString)
            } catch {
                printHandler("JS Error: \(error.localizedDescription)")
                return nil
            }
        }.get()

        guard let result else {
            return Result.missingResult.rawValue
        }

        return store.store(result)
    }

    func contextGet(memory: Memory, descriptor: Int32, stringPointer: Int32, length: Int32) -> Int32 {
        guard let context = store.fetch(from: descriptor) as? IsolatedJSContext
        else { return Result.invalidContext.rawValue }

        guard
            stringPointer >= 0, length > 0,
            let jsString = try? memory.readString(offset: UInt32(stringPointer), length: UInt32(length))
        else {
            return Result.invalidString.rawValue
        }

        let result = BlockingTask {
            await context.objectForKeyedSubscript(jsString)
        }.get()

        guard let result else {
            return Result.missingResult.rawValue
        }

        return store.store(result)
    }
}

extension JavaScript {
    func webViewCreate() -> Int32 {
        let handler = BlockingTask { [webViewNamespace] in
            await MainActor.run {
                WebViewHandler(id: webViewNamespace)
            }
        }.get()

        return store.store(handler)
    }

    func webViewSetRuleList(
        memory: Memory,
        descriptor: Int32,
        stringPointer: Int32,
        length: Int32
    ) -> Int32 {
        guard let webViewHandler = store.fetch(from: descriptor) as? WebViewHandler
        else { return Result.invalidHandler.rawValue }

        guard
            stringPointer >= 0, length > 0,
            let jsonString = try? memory.readString(offset: UInt32(stringPointer), length: UInt32(length))
        else {
            return Result.invalidString.rawValue
        }

        let success = BlockingTask {
            await Task { @MainActor in
                do {
                    try await webViewHandler.setRuleList(jsonString)
                    return true
                } catch {
                    return false
                }
            }.value
        }.get()

        if success {
            return Result.success.rawValue
        } else {
            return Result.invalidRuleList.rawValue
        }
    }

    func webViewLoad(descriptor: Int32, requestDescriptor: Int32) -> Int32 {
        guard let webViewHandler = store.fetch(from: descriptor) as? WebViewHandler
        else { return Result.invalidHandler.rawValue }

        guard
            let request = store.fetch(from: requestDescriptor) as? NetRequest,
            let urlRequest = request.toUrlRequest()
        else { return Result.invalidRequest.rawValue }

        BlockingTask {
           await MainActor.run {
               _ = webViewHandler.webView.load(urlRequest)
           }
        }.get()

        return Result.success.rawValue
    }

    // swiftlint:disable:next function_parameter_count
    func webViewLoadHtml(
        memory: Memory,
        descriptor: Int32,
        stringPointer: Int32,
        length: Int32,
        urlStringPointer: Int32,
        urlLength: Int32
    ) -> Int32 {
        guard let webViewHandler = store.fetch(from: descriptor) as? WebViewHandler
        else { return Result.invalidHandler.rawValue }

        guard
            stringPointer >= 0, length > 0,
            let htmlString = try? memory.readString(offset: UInt32(stringPointer), length: UInt32(length))
        else {
            return Result.invalidString.rawValue
        }

        let url: URL? = if urlStringPointer >= 0, urlLength > 0 {
            (try? memory.readString(offset: UInt32(urlStringPointer), length: UInt32(urlLength)))
                .flatMap { URL(string: $0) }
        } else {
            nil
        }

        BlockingTask {
           await MainActor.run {
               _ = webViewHandler.webView.loadHTMLString(htmlString, baseURL: url)
           }
        }.get()

        return Result.success.rawValue
    }

    func webViewWaitForLoad(descriptor: Int32) -> Int32 {
        guard let webViewHandler = store.fetch(from: descriptor) as? WebViewHandler
        else { return Result.invalidHandler.rawValue }
        webViewHandler.waitForLoad()
        return Result.success.rawValue
    }

    func webViewEval(memory: Memory, descriptor: Int32, stringPointer: Int32, length: Int32) -> Int32 {
        guard let webViewHandler = store.fetch(from: descriptor) as? WebViewHandler
        else { return Result.invalidHandler.rawValue }

        guard
            stringPointer >= 0, length > 0,
            let jsString = try? memory.readString(offset: UInt32(stringPointer), length: UInt32(length))
        else {
            return Result.invalidString.rawValue
        }

        let result: String? = BlockingTask {
            await Task { @MainActor in
                let result = try? await webViewHandler.webView.evaluateJavaScript(jsString)
                guard let result else {
                    return nil
                }
                return "\(result)"
            }.value
        }.get()

        guard let result else {
            return Result.missingResult.rawValue
        }

        return store.store("\(result)")
    }

    func webViewEvalAsync(memory: Memory, descriptor: Int32, stringPointer: Int32, length: Int32) -> Int32 {
        guard let webViewHandler = store.fetch(from: descriptor) as? WebViewHandler
        else { return Result.invalidHandler.rawValue }

        guard
            stringPointer >= 0, length > 0,
            let jsString = try? memory.readString(offset: UInt32(stringPointer), length: UInt32(length))
        else {
            return Result.invalidString.rawValue
        }

        let result: String? = BlockingTask {
            await Task { @MainActor in
                let result = try? await webViewHandler.evaluateAsyncJavaScript(jsString)
                guard let result else {
                    return nil
                }
                return "\(result)"
            }.value
        }.get()

        guard let result else {
            return Result.missingResult.rawValue
        }

        return store.store("\(result)")
    }

    // swiftlint:disable:next function_parameter_count
    func webViewAddUserScript(
        memory: Memory,
        descriptor: Int32,
        stringPointer: Int32,
        length: Int32,
        atDocumentEnd: Int32,
        forMainFrameOnly: Int32
    ) -> Int32 {
        guard let webViewHandler = store.fetch(from: descriptor) as? WebViewHandler
        else { return Result.invalidHandler.rawValue }

        guard
            stringPointer >= 0, length > 0,
            let sourceString = try? memory.readString(offset: UInt32(stringPointer), length: UInt32(length))
        else {
            return Result.invalidString.rawValue
        }

        BlockingTask {
            await MainActor.run {
                let userScript = WKUserScript(
                    source: sourceString,
                    injectionTime: atDocumentEnd != 0 ? .atDocumentEnd : .atDocumentStart,
                    forMainFrameOnly: forMainFrameOnly != 0
                )
                webViewHandler.webView.configuration.userContentController.addUserScript(userScript)
            }
        }.get()

        return Result.success.rawValue
    }

    func webViewGetCookies(descriptor: Int32) -> Int32 {
        guard let webViewHandler = store.fetch(from: descriptor) as? WebViewHandler
        else { return Result.invalidHandler.rawValue }

        let cookies = BlockingTask {
            await webViewHandler.webView.configuration.websiteDataStore.httpCookieStore.allCookies()
        }
        .get()

        do {
            return try store.storeEncoded(cookies.map(Cookie.init))
        } catch {
            return Result.failedEncoding.rawValue
        }
    }

    // swiftlint:disable:next function_parameter_count
    func webViewDeleteCookie(
        memory: Memory,
        descriptor: Int32,
        namePointer: Int32,
        nameLength: Int32,
        valuePointer: Int32,
        valueLength: Int32,
        domainPointer: Int32,
        domainLength: Int32
    ) -> Int32 {
        guard let webViewHandler = store.fetch(from: descriptor) as? WebViewHandler
        else { return Result.invalidHandler.rawValue }

        let name: String? = if namePointer >= 0, nameLength > 0 {
            try? memory.readString(offset: UInt32(namePointer), length: UInt32(nameLength))
        } else {
            nil
        }
        let value: String? = if valuePointer >= 0, valueLength > 0 {
            try? memory.readString(offset: UInt32(valuePointer), length: UInt32(valueLength))
        } else {
            nil
        }
        let domain: String? = if domainPointer >= 0, domainPointer > 0 {
            try? memory.readString(offset: UInt32(domainPointer), length: UInt32(domainLength))
        } else {
            nil
        }

        let success = BlockingTask {
            if let name {
                let cookies = await webViewHandler.cookieStore.allCookies()
                guard let cookie = cookies.first(where: {
                    let nameMatches = $0.name == name
                    let valueMatches = value == nil || $0.value == value
                    let domainMatches = domain == nil || $0.domain == domain
                    return nameMatches && valueMatches && domainMatches
                }) else { return false }
                await webViewHandler.cookieStore.deleteCookie(cookie)
                return true
            } else if nameLength == -1 {
                await webViewHandler.webView.configuration.websiteDataStore.clearRecords()
                return true
            }
            return false
        }
        .get()

        return success ? Result.success.rawValue : Result.missingCookie.rawValue
    }
}
