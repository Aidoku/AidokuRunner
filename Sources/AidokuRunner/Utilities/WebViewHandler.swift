//
//  WebViewHandler.swift
//  AidokuRunner
//
//  Created by skitty on 6/26/26.
//

import CryptoKit
import WebKit

@MainActor
class WebViewHandler: NSObject {
    let webView: WKWebView

    private let loadedSemaphore = DispatchSemaphore(value: 0)
    private var continuations: [String: CheckedContinuation<Any?, Error>] = [:]
    private var addedAsyncEvalHandler = false

    private static let asyncEvalHandlerName = "asyncEval"

    var cookieStore: WKHTTPCookieStore {
        webView.configuration.websiteDataStore.httpCookieStore
    }

    init(id: String) {
        let config = WKWebViewConfiguration()
        if #available(iOS 17.0, *) {
            config.websiteDataStore = .init(forIdentifier: UUID(sourceKey: id))
        } else {
            config.websiteDataStore = .nonPersistent()
        }
        self.webView = WKWebView(frame: .zero, configuration: config)
        super.init()
        webView.navigationDelegate = self
    }

    nonisolated func waitForLoad() {
        loadedSemaphore.wait()
    }

    func setRuleList(_ json: String) async throws {
        let ruleList = try await WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "RuleList",
            encodedContentRuleList: json
        )
        guard let ruleList else { return }
        webView.configuration.userContentController.add(ruleList)
    }

    func evaluateAsyncJavaScript(_ javaScriptString: String) async throws -> Any? {
        let callbackID = UUID().uuidString

        if !addedAsyncEvalHandler {
            webView.configuration.userContentController.add(self, name: Self.asyncEvalHandlerName)
            addedAsyncEvalHandler = true
        }

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Any?, Error>) in
            continuations[callbackID] = continuation

            let wrappedScript = """
            (async () => {
                try {
                    const result = await (\(javaScriptString));
                    window.webkit.messageHandlers.\(Self.asyncEvalHandlerName).postMessage({
                        id: '\(callbackID)',
                        ok: true,
                        value: result ?? null
                    });
                } catch (e) {
                    window.webkit.messageHandlers.\(Self.asyncEvalHandlerName).postMessage({
                        id: '\(callbackID)',
                        ok: false,
                        error: String(e?.message ?? e)
                    });
                }
            })();
            """

            webView.evaluateJavaScript(wrappedScript) { _, error in
                if let error {
                    if let continuation = self.continuations.removeValue(forKey: callbackID) {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}

extension WebViewHandler: WKNavigationDelegate {
    func webView(_: WKWebView, didFinish _: WKNavigation) {
        loadedSemaphore.signal()
    }
}

extension WebViewHandler: WKScriptMessageHandler {
    func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
        guard
            message.name == Self.asyncEvalHandlerName,
            let body = message.body as? [String: Any],
            let id = body["id"] as? String,
            let ok = body["ok"] as? Bool,
            let continuation = continuations.removeValue(forKey: id)
        else {
            return
        }

        if ok {
            continuation.resume(returning: body["value"])
        } else {
            let errorMessage = body["error"] as? String ?? "JS evaluation failed"
            continuation.resume(
                throwing: NSError(
                    domain: "WebViewHandler",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: errorMessage]
                )
            )
        }
    }
}
