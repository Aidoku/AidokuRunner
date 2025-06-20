//
//  Source.swift
//  AidokuRunner
//
//  Created by Skitty on 8/13/23.
//

import Foundation

public final class Source: Sendable {
    public let url: URL?

    public let key: String
    public let name: String
    public let version: Int
    public let languages: [String]
    public let urls: [URL]
    public let contentRating: SourceContentRating

    public let imageUrl: URL?

    public let config: SourceInfo.Configuration?
    private let staticListings: [Listing]
    private let staticFilters: [Filter]
    public let staticSettings: [Setting]

    public let runner: Runner

    public var apiVersion: String { "0.7" }

    public var features: SourceFeatures { runner.features }

    public var partialHomePublisher: SinglePublisher<Home>? {
        runner.partialHomePublisher
    }
    public var partialMangaPublisher: SinglePublisher<Manga>? {
        runner.partialMangaPublisher
    }

    /// Indicates if a source should default to a search page instead of a home/listings page.
    public var onlySearch: Bool {
        !features.providesHome && !hasListings
    }

    /// Indicates if a source contains any listings.
    public var hasListings: Bool {
        features.dynamicListings || !staticListings.isEmpty
    }

    public var supportsArtistSearch: Bool {
        config?.supportsArtistSearch ?? staticFilters.contains {
            if case .text = $0.value {
                $0.id == "artist"
            } else {
                false
            }
        }
    }

    public var supportsAuthorSearch: Bool {
        config?.supportsAuthorSearch ?? staticFilters.contains {
            if case .text = $0.value {
                $0.id == "author"
            } else {
                false
            }
        }
    }

    public init(
        url: URL? = nil,
        key: String,
        name: String,
        version: Int,
        languages: [String] = [],
        urls: [URL] = [],
        contentRating: SourceContentRating,
        imageUrl: URL? = nil,
        config: SourceInfo.Configuration? = nil,
        staticListings: [Listing] = [],
        staticFilters: [Filter] = [],
        staticSettings: [Setting] = [],
        runner: Runner
    ) {
        self.url = url
        self.key = key
        self.name = name
        self.version = version
        self.languages = languages
        self.urls = urls
        self.contentRating = contentRating
        self.imageUrl = imageUrl
        self.config = config
        self.staticListings = staticListings
        self.staticFilters = staticFilters
        self.runner = runner

        let settings = Self.getExtraSettings(config: config, languages: languages, urls: urls) + staticSettings
        self.staticSettings = settings
        loadSettingsDefaults(settings: settings)
    }

    public init(
        url: URL,
        interpreterConfig: InterpreterConfiguration = .init()
    ) async throws {
        guard url.isFileURL else { throw InitError.invalidUrl }
        var isDirectory = ObjCBool(false)
        let fileExists = FileManager.default.fileExists(atPath: url.filePath(), isDirectory: &isDirectory)
        guard fileExists, isDirectory.boolValue else { throw InitError.invalidUrl }

        // load source info from json
        let jsonUrl = url.appending("source.json")
        guard FileManager.default.fileExists(atPath: jsonUrl.filePath()) else {
            throw InitError.missingExecutable
        }
        let decoder = JSONDecoder()
        let sourceInfo = try decoder.decode(SourceInfo.self, from: Data(contentsOf: jsonUrl))

        // initialize source fields
        self.url = url
        key = sourceInfo.info.id
        name = sourceInfo.info.name
        version = sourceInfo.info.version
        languages = sourceInfo.info.languages
        contentRating = sourceInfo.info.contentRating ?? .safe
        imageUrl = url.appending("icon.png")

        var urls: [URL] = []
        if let urlString = sourceInfo.info.url, let baseUrl = URL(string: urlString) {
            urls.append(baseUrl)
        }
        urls.append(contentsOf: (sourceInfo.info.urls ?? []).compactMap { URL(string: $0) })

        config = sourceInfo.config
        staticListings = sourceInfo.listings ?? []

        // load static filters
        let filtersUrl = url.appending("filters.json")
        if FileManager.default.fileExists(atPath: filtersUrl.filePath()) {
            staticFilters = try decoder.decode([Filter].self, from: Data(contentsOf: filtersUrl))
        } else {
            staticFilters = []
        }

        // load static settings
        var staticSettings: [Setting]

        let settingsUrl = url.appending("settings.json")
        if FileManager.default.fileExists(atPath: settingsUrl.filePath()) {
            staticSettings = try decoder.decode([Setting].self, from: Data(contentsOf: settingsUrl))
        } else {
            staticSettings = []
        }

        // load source wasm executable
        let executableUrl = url.appending("main.wasm")
        guard FileManager.default.fileExists(atPath: executableUrl.filePath()) else {
            throw InitError.missingExecutable
        }
        let data = try Data(contentsOf: executableUrl)
        let bytes = [UInt8](data)
        self.runner = try await Interpreter(
            sourceKey: key,
            bytes: bytes,
            config: interpreterConfig
        )

        if runner.features.providesBaseUrl {
            if let baseUrl = try? await runner.getBaseUrl() {
                urls.insert(baseUrl, at: 0)
            }
        }
        self.urls = urls

        let settings = Self.getExtraSettings(config: config, languages: languages, urls: urls) + staticSettings
        self.staticSettings = settings
        loadSettingsDefaults(settings: settings)
    }

    static func getExtraSettings(config: SourceInfo.Configuration?, languages: [String], urls: [URL]) -> [Setting] {
        var extraSettings: [Setting] = []

        // languages setting
        if languages.count > 1 {
            let preferredLanguages = Locale.preferredLanguages.compactMap { Locale(identifier: $0).languageCode }
            let defaultLanguages = Array(Set(languages).intersection(Set(preferredLanguages)))

            let titles = languages.map {
                Locale.current.localizedString(forIdentifier: $0) ?? $0
            }

            let languageSelectType = config?.languageSelectType ?? .multiple
            let value: Setting.Value = languageSelectType == .single
                ? .select(.init(
                    values: languages,
                    titles: titles,
                    defaultValue: defaultLanguages.first
                ))
                : .multiselect(.init(
                    values: languages,
                    titles: titles,
                    defaultValue: defaultLanguages
                ))

            let setting = Setting(
                key: languageSelectType == .single ? "language" : "languages",
                title: languageSelectType == .single ? "LANGUAGE" : "LANGUAGES",
                notification: nil,
                value: value
            )

            extraSettings.append(Setting(title: setting.title, value: .group(.init(items: [setting]))))
        }

        // base url setting
        if config?.allowsBaseUrlSelect ?? false, urls.count > 1 {
            let setting = Setting(
                key: "url",
                title: "BASE_URL",
                notification: nil,
                value: .select(.init(
                    values: urls.map(\.absoluteString),
                    defaultValue: urls.first?.absoluteString
                ))
            )

            extraSettings.append(Setting(title: setting.title, value: .group(.init(items: [setting]))))
        }
        return extraSettings
    }

    enum InitError: Error {
        case invalidUrl
        case missingInfo
        case missingExecutable
        case invalidBaseUrl
    }

    // swiftlint:disable:next cyclomatic_complexity
    func loadSettingsDefaults(settings: [Setting]) {
        func key(_ key: String) -> String {
            "\(id).\(key)"
        }

        for setting in settings {
            switch setting.value {
                case .select(let value):
                    if let defaultValue = value.defaultValue {
                        SettingsStore.shared.register(key: key(setting.key), default: defaultValue)
                    }
                case .multiselect(let value):
                    if let defaultValue = value.defaultValue {
                        SettingsStore.shared.register(key: key(setting.key), default: defaultValue)
                    }
                case .toggle(let value):
                    if let defaultValue = value.defaultValue {
                        SettingsStore.shared.register(key: key(setting.key), default: defaultValue)
                    }
                case .stepper(let value):
                    if let defaultValue = value.defaultValue {
                        SettingsStore.shared.register(key: key(setting.key), default: defaultValue)
                    }
                case .segment(let value):
                    if let defaultValue = value.defaultValue {
                        SettingsStore.shared.register(key: key(setting.key), default: defaultValue)
                    }
                case .text(let value):
                    if let defaultValue = value.defaultValue {
                        SettingsStore.shared.register(key: key(setting.key), default: defaultValue)
                    }
                case .editableList(let value):
                    if let defaultValue = value.defaultValue {
                        SettingsStore.shared.register(key: key(setting.key), default: defaultValue)
                    }
                case .group(let value):
                    self.loadSettingsDefaults(settings: value.items)
                default:
                    break
            }
        }
    }

    public func matchingGenreFilter(for tag: String) -> FilterValue? {
        if config?.supportsTagSearch ?? false {
            return .select(id: "genre", value: tag)
        }

        for filter in staticFilters {
            if case let .multiselect(genreFilter) = filter.value, genreFilter.isGenre {
                if let index = genreFilter.options.firstIndex(where: { $0 == tag }) {
                    let value = (genreFilter.ids ?? genreFilter.options)[index]
                    return .multiselect(id: filter.id, included: [value], excluded: [])
                }
            } else if case let .select(genreFilter) = filter.value, genreFilter.isGenre {
                if let index = genreFilter.options.firstIndex(where: { $0 == tag }) {
                    let value = (genreFilter.ids ?? genreFilter.options)[index]
                    return .select(id: filter.id, value: value)
                }
            }
        }

        return nil
    }
}

public extension Source {
    func getSearchMangaList(query: String?, page: Int, filters: [FilterValue]) async throws -> MangaPageResult {
        var result = try await runner.getSearchMangaList(query: query, page: page, filters: filters)
        result.setSourceKey(key)
        return result
    }

    func getMangaUpdate(manga: Manga, needsDetails: Bool, needsChapters: Bool) async throws -> Manga {
        var manga = try await runner.getMangaUpdate(
            manga: manga,
            needsDetails: needsDetails,
            needsChapters: needsChapters
        )

        manga.sourceKey = key

        // set default language for chapters
        if languages.count == 1, let language = languages.first, let chapters = manga.chapters {
            for chapterIdx in chapters.indices {
                manga.chapters?[chapterIdx].language = chapters[chapterIdx].language ?? language
            }
        }

        return manga
    }

    func getPageList(manga: Manga, chapter: Chapter) async throws -> [Page] {
        try await runner.getPageList(manga: manga, chapter: chapter)
    }

    func getMangaList(listing: Listing, page: Int) async throws -> MangaPageResult {
        guard runner.features.providesListings else {
            throw SourceError.unimplemented
        }
        var result = try await runner.getMangaList(listing: listing, page: page)
        result.setSourceKey(key)
        return result
    }

    func getHome() async throws -> Home {
        guard runner.features.providesHome else {
            throw SourceError.unimplemented
        }
        return try await runner.getHome()
    }

    func processPageImage(response: Response, context: PageContext?) async throws -> PlatformImage? {
        if runner.features.processesPages {
            try await runner.processPageImage(response: response, context: context)
        } else {
            nil
        }
    }

    func getListings() async throws -> [Listing] {
        if runner.features.dynamicListings {
            staticListings + (try await runner.getListings())
        } else {
            staticListings
        }
    }

    func getSearchFilters() async throws -> [Filter] {
        if runner.features.dynamicFilters {
            staticFilters + (try await runner.getSearchFilters())
        } else {
            staticFilters
        }
    }

    func getSettings() async throws -> [Setting] {
        if runner.features.dynamicSettings {
            let newSettings = try await runner.getSettings()
            loadSettingsDefaults(settings: newSettings)
            return staticSettings + newSettings
        }
        return staticSettings
    }

    func getImageRequest(url: String, context: PageContext?) async throws -> URLRequest {
        guard runner.features.providesImageRequests else {
            throw SourceError.unimplemented
        }
        return try await runner.getImageRequest(url: url, context: context)
    }

    func getPageDescription(page: Page) async throws -> String? {
        if let description = page.description {
            return description
        }
        if !runner.features.providesPageDescriptions {
            return nil
        }
        return try await runner.getPageDescription(page: page)
    }

    func getAlternateCovers(manga: Manga) async throws -> [String] {
        if runner.features.providesAlternateCovers {
            try await runner.getAlternateCovers(manga: manga)
        } else {
            []
        }
    }

    func getBaseUrl() async throws -> URL? {
        if runner.features.providesBaseUrl {
            try await runner.getBaseUrl()
        } else {
            nil
        }
    }

    func handleNotification(notification: String) async throws {
        if runner.features.handlesNotifications {
            try await runner.handleNotification(notification: notification)
        }
    }

    func handleDeepLink(url: String) async throws -> DeepLinkResult? {
        if runner.features.handlesDeepLinks {
            try await runner.handleDeepLink(url: url)
        } else {
            nil
        }
    }

    func handleBasicLogin(key: String, username: String, password: String) async throws -> Bool {
        if runner.features.handlesBasicLogin {
            try await runner.handleBasicLogin(key: key, username: username, password: password)
        } else {
            true
        }
    }

    func handleWebLogin(key: String, cookies: [String: String]) async throws -> Bool {
        if runner.features.handlesWebLogin {
            try await runner.handleWebLogin(key: key, cookies: cookies)
        } else {
            true
        }
    }

    func handleMigration(id: String, kind: IdKind) async throws -> String? {
        if runner.features.handlesMigration {
            try await runner.handleMigration(id: id, kind: kind)
        } else {
            nil
        }
    }
}

public extension Source {
    func store<T: Sendable>(value: T) async throws -> Int32 {
        try await runner.store(value: value)
    }

    func remove(value: Int32) async throws {
        try await runner.remove(value: value)
    }
}

extension Source: Identifiable {
    public var id: String { key }
}
