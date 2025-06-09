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

    func link() throws {
        try? module.linkFunction(name: "context_create", namespace: Self.namespace, function: contextCreate)
        try? module.linkFunction(name: "context_eval", namespace: Self.namespace, function: contextEval)
        try? module.linkFunction(name: "context_get", namespace: Self.namespace, function: contextGet)

        try? module.linkFunction(name: "webview_create", namespace: Self.namespace, function: webViewCreate)
        try? module.linkFunction(name: "webview_load", namespace: Self.namespace, function: webViewLoad)
        try? module.linkFunction(name: "webview_load_html", namespace: Self.namespace, function: webViewLoadHtml)
        try? module.linkFunction(name: "webview_wait_for_load", namespace: Self.namespace, function: webViewWaitForLoad)
        try? module.linkFunction(name: "webview_eval", namespace: Self.namespace, function: webViewEval)
    }

    enum Result: Int32 {
        case success = 0
        case missingResult = -1
        case invalidContext = -2
        case invalidString = -3
        case invalidHandler = -4
        case invalidRequest = -5
    }
}

extension JavaScript {
    func contextCreate() -> Int32 {
        guard let context = JSContext() else {
            return Result.missingResult.rawValue
        }
        return store.store(context)
    }

    func contextEval(memory: Memory, descriptor: Int32, stringPointer: Int32, length: Int32) -> Int32 {
        guard let context = store.fetch(from: descriptor) as? JSContext
        else { return Result.invalidContext.rawValue }

        guard
            stringPointer >= 0, length > 0,
            let jsString = try? memory.readString(offset: UInt32(stringPointer), length: UInt32(length))
        else {
            return Result.invalidString.rawValue
        }

        let result = context.evaluateScript(jsString)?.toString()

        guard let result else {
            return Result.missingResult.rawValue
        }

        return store.store(result)
    }

    func contextGet(memory: Memory, descriptor: Int32, stringPointer: Int32, length: Int32) -> Int32 {
        guard let context = store.fetch(from: descriptor) as? JSContext
        else { return Result.invalidContext.rawValue }

        guard
            stringPointer >= 0, length > 0,
            let jsString = try? memory.readString(offset: UInt32(stringPointer), length: UInt32(length))
        else {
            return Result.invalidString.rawValue
        }

        let result = context.objectForKeyedSubscript(jsString)?.toString()

        guard let result else {
            return Result.missingResult.rawValue
        }

        return store.store(result)
    }
}

extension JavaScript {
    func webViewCreate() -> Int32 {
        let handler = BlockingTask {
            await MainActor.run {
                WebViewHandler(webView: WKWebView())
            }
        }.get()

        return store.store(handler)
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

        let url: URL? = if urlStringPointer >= 0 && urlLength > 0 {
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
}

@MainActor
private class WebViewHandler: NSObject, WKNavigationDelegate {
    let webView: WKWebView

    private let loadedSemaphore = DispatchSemaphore(value: 0)

    init(webView: WKWebView) {
        self.webView = webView
        super.init()
        webView.navigationDelegate = self
    }

    nonisolated func waitForLoad() {
        loadedSemaphore.wait()
    }

    func webView(_: WKWebView, didFinish _: WKNavigation) {
        loadedSemaphore.signal()
    }
}
