//
//  IsolatedJSContext.swift
//  AidokuRunner
//
//  Created by skitty on 6/26/26.
//

import JavaScriptCore

actor IsolatedJSContext {
    let context: JSContext

    init(exceptionHandler: ((JSContext?, JSValue?) -> Void)? = nil) {
        context = .init()
        context.exceptionHandler = exceptionHandler
    }

    func evaluateScript(_ script: String) -> String? {
        context.evaluateScript(script)?.toString()
    }

    func evaluateAsyncScript(_ script: String) async throws -> String {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            let onResolve: @convention(block) (JSValue) -> Void = { value in
                continuation.resume(returning: value.toString())
            }

            let onReject: @convention(block) (JSValue) -> Void = { error in
                let errorMessage = error.toString() ?? "JS promise rejected"
                continuation.resume(
                    throwing: NSError(
                        domain: "IsolatedJSContext",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: errorMessage]
                    )
                )
            }

            context.setObject(onResolve, forKeyedSubscript: "__resolve" as NSCopying & NSObjectProtocol)
            context.setObject(onReject, forKeyedSubscript: "__reject" as NSCopying & NSObjectProtocol)

            let wrappedScript = """
            (async () => {
                try {
                    let result = await (\(script));
                    __resolve(result);
                } catch (err) {
                    __reject(err.message || err);
                }
            })();
            """

            context.evaluateScript(wrappedScript)
        }
    }

    func objectForKeyedSubscript(_ key: Any) -> String? {
        context.objectForKeyedSubscript(key)?.toString()
    }
}
