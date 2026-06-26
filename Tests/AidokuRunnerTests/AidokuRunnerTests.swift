@testable import AidokuRunner
import Testing
import Foundation
import Wasm3

struct AidokuRunnerTests {
    private enum TestError: Error {
        case missingResource
        case invalidSource
    }

    func source() async throws -> Source {
        guard let url = Bundle.module.url(forResource: "Payload", withExtension: nil)
        else { throw TestError.missingResource }
        return try await Source(url: url)
    }

    func module() throws -> (Runtime, Module) {
        // minimal source that provides the `alloc` function for testing
        guard let url = Bundle.module.url(forResource: "Payload/main", withExtension: "wasm")
        else { throw TestError.missingResource }
        let data = try Data(contentsOf: url)
        let env = try Environment()
        let runtime = try env.createRuntime(stackSize: 1024 * 200)
        let module = try runtime.parseAndLoadModule(bytes: [UInt8](data))
        return (runtime, module)
    }

    func write(runtime: Runtime, module: Module, string: String) throws -> (Int32, Int32) {
        let data = Data(string.utf8)
        let alloc = try module.findFunction(name: "alloc")
        let ptr: Int32 = try alloc.call(Int32(data.count))
        let memory = try runtime.memory()
        try memory.write(data: data, offset: UInt32(ptr))
        return (ptr, Int32(data.count))
    }

    @Test func testLoadSource() async throws {
        let source = try await self.source()
        #expect(source.key == "test")
        #expect(source.name == "Test")
        #expect(source.version == 1)
    }
}

extension AidokuRunnerTests {
    @Test func testJavascript() async throws {
        let (runtime, module) = try module()
        let store = GlobalStore()
        let library = JavaScript(module: module, store: store, printHandler: {
            print("JS Print:", $0)
        })

        let ctx = library.contextCreate()
        let wv = library.webViewCreate()

        // basic js eval
        if true {
            let (ptr, length) = try write(runtime: runtime, module: module, string: "1+1")
            let memory = try runtime.memory()

            let rid = library.contextEval(memory: memory, descriptor: ctx, stringPointer: ptr, length: length)
            let result = store.fetch(from: rid) as? String
            #expect(result == "2")

            let rid2 = library.webViewEval(memory: memory, descriptor: wv, stringPointer: ptr, length: length)
            let result2 = store.fetch(from: rid2) as? String
            #expect(result2 == "2")
        }

        // async js eval
        if true {
            let js = """
                new Promise((resolve) => {
                    resolve("async test");
                })
            """
            let (ptr, length) = try write(runtime: runtime, module: module, string: js)
            let memory = try runtime.memory()

            let rid = library.contextEvalAsync(memory: memory, descriptor: ctx, stringPointer: ptr, length: length)
            let result = store.fetch(from: rid) as? String
            #expect(result == "async test")

            let rid2 = library.webViewEvalAsync(memory: memory, descriptor: wv, stringPointer: ptr, length: length)
            let result2 = store.fetch(from: rid2) as? String
            #expect(result2 == "async test")
        }

        // rule list blocking
        if true {
            let html = """
                <!doctype html>
                <html>
                <body>
                <script>
                window.blockTestResult = "pending";

                const img = new Image();
                img.onload = () => { window.blockTestResult = "loaded"; };
                img.onerror = () => { window.blockTestResult = "blocked-or-failed"; };
                img.src = "https://aidoku.app/images/aidoku.svg";

                document.body.appendChild(img);
                </script>
                </body>
                </html>
            """
            let js = "window.blockTestResult"
            let ruleList = """
                [
                  {
                    "trigger": {
                      "url-filter": ".*aidoku.svg*",
                      "resource-type": ["image"]
                    },
                    "action": {
                      "type": "block"
                    }
                  }
                ]
            """
            let (htmlPtr, htmlLength) = try write(runtime: runtime, module: module, string: html)
            let (jsPtr, jsLength) = try write(runtime: runtime, module: module, string: js)
            let (rulesPtr, rulesLength) = try write(runtime: runtime, module: module, string: ruleList)
            let memory = try runtime.memory()

            #expect(library.webViewLoadHtml(
                memory: memory,
                descriptor: wv,
                stringPointer: htmlPtr,
                length: htmlLength,
                urlStringPointer: -1,
                urlLength: 0
            ) == 0)
            #expect(library.webViewWaitForLoad(descriptor: wv) == 0)

            let rid = library.webViewEval(memory: memory, descriptor: wv, stringPointer: jsPtr, length: jsLength)
            let result = store.fetch(from: rid) as? String
            #expect(result == "loaded")

            #expect(library.webViewSetRuleList(
                memory: memory,
                descriptor: wv,
                stringPointer: rulesPtr,
                length: rulesLength
            ) == 0)
            #expect(library.webViewLoadHtml(
                memory: memory,
                descriptor: wv,
                stringPointer: htmlPtr,
                length: htmlLength,
                urlStringPointer: -1,
                urlLength: 0
            ) == 0)

            let rid2 = library.webViewEval(memory: memory, descriptor: wv, stringPointer: jsPtr, length: jsLength)
            let result2 = store.fetch(from: rid2) as? String
            #expect(result2 == "blocked-or-failed")
        }

        // user script
        if true {
            let html = "<!doctype html><html><body></body></html>"
            let script = "window.userScriptTestResult = 'injected';"
            let js = "window.userScriptTestResult"

            let (htmlPtr, htmlLength) = try write(runtime: runtime, module: module, string: html)
            let (scriptPtr, scriptLength) = try write(runtime: runtime, module: module, string: script)
            let (jsPtr, jsLength) = try write(runtime: runtime, module: module, string: js)
            let memory = try runtime.memory()

            #expect(library.webViewAddUserScript(
                memory: memory,
                descriptor: wv,
                stringPointer: scriptPtr,
                length: scriptLength,
                atDocumentEnd: 0,
                forMainFrameOnly: 0
            ) == 0)

            #expect(library.webViewLoadHtml(
                memory: memory,
                descriptor: wv,
                stringPointer: htmlPtr,
                length: htmlLength,
                urlStringPointer: -1,
                urlLength: 0
            ) == 0)
            #expect(library.webViewWaitForLoad(descriptor: wv) == 0)

            let rid2 = library.webViewEvalAsync(memory: memory, descriptor: wv, stringPointer: jsPtr, length: jsLength)
            let result2 = store.fetch(from: rid2) as? String
            #expect(result2 == "injected")
        }
    }
}
