//
//  Interpreter.swift
//  AidokuRunner
//
//  Created by Skitty on 7/16/23.
//

import Foundation
import Wasm3

public struct InterpreterConfiguration: Sendable {
    let printHandler: (@Sendable (String) -> Void)?
    let requestHandler: (@Sendable (URLRequest) async throws -> (Data, URLResponse))?

    public init(
        printHandler: (@Sendable (String) -> Void)? = nil,
        requestHandler: (@Sendable (URLRequest) async throws -> (Data, URLResponse))? = nil
    ) {
        self.printHandler = printHandler
        self.requestHandler = requestHandler
    }
}

public actor Interpreter {
    private let sourceKey: String
    internal var module: Module
    private let store = GlobalStore()
    private let config: InterpreterConfiguration

    public let features: SourceFeatures

    private let partialValueHandler = CallbackHandler()

    public let partialHomePublisher: SinglePublisher<Home>? = .init()
    public let partialMangaPublisher: SinglePublisher<Manga>? = .init()

    public init(
        sourceKey: String,
        bytes: [UInt8],
        stackSize: UInt32 = 1024 * 200,
        config: InterpreterConfiguration = .init()
        // we call an isolated actor function (start) so this needs to be async despite the lint
        // swiftlint:disable:next async_without_await
    ) async throws {
        self.sourceKey = sourceKey
        let env = try Environment()
        let runtime = try env.createRuntime(stackSize: stackSize)
        module = try runtime.parseAndLoadModule(bytes: bytes)
        self.config = config

        // import functions (must be done before calling findFunction)
        try Env(
            module: module,
            partialValueHandler: partialValueHandler,
            printHandler: config.printHandler ?? { print($0) }
        ).link()
        try Std(module: module, store: store).link()
        try Defaults(module: module, store: store, defaultNamespace: sourceKey).link()
        try Net(
            module: module,
            store: store,
            requestHandler: config.requestHandler
        ).link()
        try Html(module: module, store: store).link()
        try JavaScript(module: module, store: store).link()
#if canImport(UIKit)
        try Canvas(module: module, store: store).link()
#endif

        let providesListings = (try? module.findFunction(name: "get_manga_list")) != nil
        let providesHome = (try? module.findFunction(name: "get_home")) != nil
        let dynamicFilters = (try? module.findFunction(name: "get_filters")) != nil
        let dynamicSettings = (try? module.findFunction(name: "get_settings")) != nil
        let dynamicListings = (try? module.findFunction(name: "get_listings")) != nil
        let processesPages = (try? module.findFunction(name: "process_page_image")) != nil
        let providesImageRequests = (try? module.findFunction(name: "get_image_request")) != nil
        let providesPageDescriptions = (try? module.findFunction(name: "get_page_description")) != nil
        let providesAlternateCovers = (try? module.findFunction(name: "get_alternate_covers")) != nil
        let providesBaseUrl = (try? module.findFunction(name: "get_base_url")) != nil
        let handlesNotifications = (try? module.findFunction(name: "handle_notification")) != nil
        let handlesDeepLinks = (try? module.findFunction(name: "handle_deep_link")) != nil
        let handlesBasicLogin = (try? module.findFunction(name: "handle_basic_login")) != nil
        let handlesWebLogin = (try? module.findFunction(name: "handle_web_login")) != nil
        let handlesMigration = (try? module.findFunction(name: "handle_id_migration")) != nil

        features = .init(
            providesListings: providesListings,
            providesHome: providesHome,
            dynamicFilters: dynamicFilters,
            dynamicSettings: dynamicSettings,
            dynamicListings: dynamicListings,
            processesPages: processesPages,
            providesImageRequests: providesImageRequests,
            providesPageDescriptions: providesPageDescriptions,
            providesAlternateCovers: providesAlternateCovers,
            providesBaseUrl: providesBaseUrl,
            handlesNotifications: handlesNotifications,
            handlesDeepLinks: handlesDeepLinks,
            handlesBasicLogin: handlesBasicLogin,
            handlesWebLogin: handlesWebLogin,
            handlesMigration: handlesMigration
        )

        try start()
    }

    private func start() throws {
        let function = try? module.findFunction(name: "start")
        if let function {
            try function.call()
        }
    }
}

extension Interpreter: Runner {
    public func getSearchMangaList(query: String?, page: Int, filters: [FilterValue]) throws -> MangaPageResult {
        let function = try module.findFunction(name: "get_search_manga_list")
        let queryPointer = store.store(query ?? "")
        defer { store.remove(at: queryPointer) }
        let filterPointer = try store.storeEncoded(filters)
        defer { store.remove(at: filterPointer) }

        let result: Int32 = try function.call(queryPointer, page, filterPointer)
        let data = try handleResult(result: result)
        return try PostcardDecoder().decode(MangaPageResult.self, from: data)
    }

    public func getMangaUpdate(manga: Manga, needsDetails: Bool, needsChapters: Bool) async throws -> Manga {
        let callbackId = await partialValueHandler.registerCallback { @Sendable _, data in
            let manga = try? PostcardDecoder().decode(Manga.self, from: data)
            guard let manga else { return nil }
            await self.partialMangaPublisher?.send(manga)
            return nil
        }

        let function = try module.findFunction(name: "get_manga_update")
        let mangaPointer = try store.storeEncoded(manga)
        defer {
            store.remove(at: mangaPointer)
        }
        let result: Int32 = try function.call(mangaPointer, needsDetails ? 1 : 0, needsChapters ? 1 : 0)
        let data = try handleResult(result: result)
        await partialValueHandler.removeCallback(id: callbackId)
        return try PostcardDecoder().decode(Manga.self, from: data)
    }

    public func getPageList(manga: Manga, chapter: Chapter) throws -> [Page] {
        let function = try module.findFunction(name: "get_page_list")
        var newManga = manga
        newManga.chapters = nil
        let mangaPointer = try store.storeEncoded(newManga)
        defer { store.remove(at: mangaPointer) }
        let chapterPointer = try store.storeEncoded(chapter)
        defer { store.remove(at: chapterPointer) }
        let result: Int32 = try function.call(mangaPointer, chapterPointer)
        let data = try handleResult(result: result)
        return try PostcardDecoder().decode([PageCodable].self, from: data).compactMap { $0.into(store: store) }
    }

    public func getMangaList(listing: Listing, page: Int) throws -> MangaPageResult {
        let function = try module.findFunction(name: "get_manga_list")
        let listingPointer = try store.storeEncoded(listing)
        defer {
            store.remove(at: listingPointer)
        }
        let result: Int32 = try function.call(listingPointer, page)
        let data = try handleResult(result: result)
        return try PostcardDecoder().decode(MangaPageResult.self, from: data)
    }

    public func getHome() async throws -> Home {
        struct PartialValueHolder: Sendable {
            var currentHome: Home?
            var decodingError: Error?
        }

        let callbackId = await partialValueHandler.registerCallback { @Sendable partial, data in
            var partial = (partial as? PartialValueHolder) ?? .init()
            do {
                let home = try PostcardDecoder().decode(HomePartialResult.self, from: data)
                switch home {
                    case var .layout(home):
                        home.setSourceKey(self.sourceKey)
                        partial.currentHome = home
                        await self.partialHomePublisher?.send(home)
                    case var .component(component):
                        component.setSourceKey(self.sourceKey)
                        if let currentHome = partial.currentHome {
                            // find the component in the current home (with the same title) and replace it
                            let index = currentHome.components.firstIndex { $0.title == component.title }
                            var newComponents = currentHome.components
                            if let index {
                                newComponents[index] = component
                            } else {
                                // otherwise, add to the end
                                newComponents.append(component)
                            }
                            partial.currentHome = Home(components: newComponents)
                        } else {
                            partial.currentHome = Home(components: [component])
                        }
                        await self.partialHomePublisher?.send(partial.currentHome!)
                }
            } catch {
                partial.decodingError = error
            }
            return partial
        }

        do {
            let function = try module.findFunction(name: "get_home")
            let result: Int32 = try function.call()
            let data = try handleResult(result: result)

            let homeResult = try PostcardDecoder().decode(Home.self, from: data)

            let partialValueHolder = await partialValueHandler.getData(for: callbackId) as? PartialValueHolder

            if let decodingError = partialValueHolder?.decodingError {
                throw decodingError
            }

            await partialValueHandler.removeCallback(id: callbackId)

            if homeResult.components.isEmpty {
                return partialValueHolder?.currentHome ?? homeResult
            }

            return homeResult
        } catch {
            await partialValueHandler.removeCallback(id: callbackId)
            throw error
        }
    }

    public func processPageImage(response: Response, context: PageContext?) throws -> PlatformImage? {
        let function = try module.findFunction(name: "process_page_image")
        let responsePointer = try store.storeEncoded(response)
        let contextPointer = if let context {
            try store.storeEncoded(context)
        } else {
            Int32(-1)
        }
        defer {
            store.remove(at: responsePointer)
            if contextPointer >= 0 {
                store.remove(at: contextPointer)
            }
        }
        let result: Int32 = try function.call(responsePointer, contextPointer)
        let data = try handleResult(result: result)
        let imageRef = try PostcardDecoder().decode(ImageRef.self, from: data)
        let finalImage = store.fetch(from: imageRef) as? PlatformImage
        store.remove(at: imageRef)
        return finalImage
    }

    public func getSearchFilters() throws -> [Filter] {
        let function = try module.findFunction(name: "get_filters")
        let result: Int32 = try function.call()
        let data = try handleResult(result: result)
        return try PostcardDecoder().decode([Filter].self, from: data)
    }

    public func getSettings() throws -> [Setting] {
        let function = try module.findFunction(name: "get_settings")
        let result: Int32 = try function.call()
        let data = try handleResult(result: result)
        return try PostcardDecoder().decode([Setting].self, from: data)
    }

    public func getListings() throws -> [Listing] {
        let function = try module.findFunction(name: "get_listings")
        let result: Int32 = try function.call()
        let data = try handleResult(result: result)
        return try PostcardDecoder().decode([Listing].self, from: data)
    }

    public func getImageRequest(url: String, context: PageContext?) throws -> URLRequest {
        let function = try module.findFunction(name: "get_image_request")
        let responsePointer = try store.storeEncoded(url)
        let contextPointer = if let context {
            try store.storeEncoded(context)
        } else {
            Int32(-1)
        }
        defer {
            store.remove(at: responsePointer)
            if contextPointer >= 0 {
                store.remove(at: contextPointer)
            }
        }
        let result: Int32 = try function.call(responsePointer, contextPointer)
        let data = try handleResult(result: result)
        let requestPointer = try PostcardDecoder().decode(Int32.self, from: data)
        let finalRequest = (store.fetch(from: requestPointer) as? NetRequest)?.toUrlRequest()
        store.remove(at: requestPointer)
        guard let finalRequest else {
            throw SourceError.missingResult
        }
        return finalRequest
    }

    public func getPageDescription(page: Page) throws -> String? {
        let function = try module.findFunction(name: "get_page_description")
        let codablePage = page.codable(store: store)
        defer {
            if let pointer = codablePage.content.storePointer {
                store.remove(at: pointer)
            }
        }
        let pagePointer = try store.storeEncoded(codablePage)
        defer { store.remove(at: pagePointer) }
        let result: Int32 = try function.call(pagePointer)
        let data = try handleResult(result: result)
        return try PostcardDecoder().decode(String.self, from: data)
    }

    public func getAlternateCovers(manga: Manga) throws -> [String] {
        let function = try module.findFunction(name: "get_alternate_covers")
        let mangaPointer = try store.storeEncoded(manga)
        defer { store.remove(at: mangaPointer) }
        let result: Int32 = try function.call(mangaPointer)
        let data = try handleResult(result: result)
        return try PostcardDecoder().decode([String].self, from: data)
    }

    public func getBaseUrl() throws -> URL? {
        let function = try module.findFunction(name: "get_base_url")
        let result: Int32 = try function.call()
        let data = try handleResult(result: result)
        return try PostcardDecoder().decode(String?.self, from: data).flatMap(URL.init)
    }

    public func handleNotification(notification: String) throws {
        let function = try module.findFunction(name: "handle_notification")
        let urlPointer = try store.storeEncoded(notification)
        defer { store.remove(at: urlPointer) }
        let _: Int32 = try function.call(urlPointer)
    }

    public func handleDeepLink(url: String) throws -> DeepLinkResult? {
        let function = try module.findFunction(name: "handle_deep_link")
        let urlPointer = try store.storeEncoded(url)
        defer { store.remove(at: urlPointer) }
        let result: Int32 = try function.call(urlPointer)
        let data = try handleResult(result: result)
        return try PostcardDecoder().decode(DeepLinkResult?.self, from: data)
    }

    public func handleBasicLogin(key: String, username: String, password: String) throws -> Bool {
        let function = try module.findFunction(name: "handle_basic_login")

        let keyPtr = try store.storeEncoded(key)
        defer { store.remove(at: keyPtr) }
        let usernamePtr = try store.storeEncoded(username)
        defer { store.remove(at: usernamePtr) }
        let passwordPtr = try store.storeEncoded(password)
        defer { store.remove(at: passwordPtr) }

        let result: Int32 = try function.call(keyPtr, usernamePtr, passwordPtr)
        let data = try handleResult(result: result)
        return try PostcardDecoder().decode(Bool.self, from: data)
    }

    public func handleWebLogin(key: String, cookies: [String: String]) throws -> Bool {
        let function = try module.findFunction(name: "handle_web_login")

        let keys = [String](cookies.keys)
        let values = keys.map { cookies[$0] ?? "" }

        let keyPtr = try store.storeEncoded(key)
        defer { store.remove(at: keyPtr) }
        let keysPtr = try store.storeEncoded(keys)
        defer { store.remove(at: keysPtr) }
        let valuesPtr = try store.storeEncoded(values)
        defer { store.remove(at: valuesPtr) }

        let result: Int32 = try function.call(keyPtr, keysPtr, valuesPtr)
        let data = try handleResult(result: result)
        return try PostcardDecoder().decode(Bool.self, from: data)
    }

    public func handleMigration(id: String, kind: IdKind) throws -> String {
        let function = try module.findFunction(name: "handle_id_migration")

        let idPtr = try store.storeEncoded(id)
        defer { store.remove(at: idPtr) }

        let result: Int32 = try function.call(idPtr, Int32(kind.rawValue))
        let data = try handleResult(result: result)
        return try PostcardDecoder().decode(String.self, from: data)
    }

    public func store<T: Sendable>(value: T) -> Int32 {
        store.store(value)
    }

    public func remove(value: Int32) {
        store.remove(at: value)
    }
}

private extension Interpreter {
    func handleResult(result: Int32) throws -> Data {
        // handle source error
        if result < 0 {
            switch result {
                case -2: throw SourceError.unimplemented
                case -3: throw SourceError.networkError
                default: throw SourceError.missingResult
            }
        }

        let pointer = UInt32(result)
        let memory = try module.runtime.memory()
        let length: UInt32 = try memory.readValues(offset: pointer, length: 1)[0]

        // handle source error message
        if length == UInt32.max {
            let stringLength: UInt32 = try memory.readValues(offset: pointer + 8, length: 1)[0] - 12
            let message = try memory.readString(offset: pointer + 12, length: stringLength)
            try freeResult(pointer: result)
            throw SourceError.message(message)
        }

        let data = try memory.readData(offset: pointer + 8, length: length - 8)
        try freeResult(pointer: result)
        return data
    }

    func freeResult(pointer: Int32) throws {
        let function = try module.findFunction(name: "free_result")
        try function.call(pointer)
    }
}
