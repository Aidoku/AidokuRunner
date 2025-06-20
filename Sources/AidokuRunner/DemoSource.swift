//
//  DemoSource.swift
//  AidokuRunner
//
//  Created by Skitty on 12/29/24.
//

import Foundation

public extension Source {
    /// Static source available for demo or testing purposes.
    static func demo() -> Source {
        .init(
            url: nil,
            key: "demo",
            name: "Demo Source",
            version: 1,
            languages: ["en"],
            urls: [],
            contentRating: .safe,
            config: nil,
            staticListings: [
                .init(id: "1", name: "Grid", kind: .default),
                .init(id: "2", name: "Grid 2", kind: .default),
                .init(id: "3", name: "List", kind: .list),
                .init(id: "4", name: "Unimplemented", kind: .default)
            ],
            staticFilters: [
                .init(id: "genre", title: "Genre", value: .multiselect(.init(
                    isGenre: true,
                    canExclude: true,
                    usesTagStyle: true,
                    options: [
                        "Action", "Comedy", "Romance", "SciFi", "Tag 1"
                    ],
                    ids: nil
                )))
            ],
            staticSettings: [
                .init(
                    title: "Settings",
                    value: .group(.init(items: [
                        .init(
                            key: "switch1",
                            title: "Switch 1",
                            value: .toggle(.init())
                        ),
                        .init(
                            key: "switch2",
                            title: "Switch 2",
                            requires: "switch1",
                            refreshes: ["listings"],
                            value: .toggle(.init())
                        ),
                        .init(
                            key: "stepper",
                            title: "Stepper",
                            requiresFalse: "switch1",
                            value: .stepper(.init(minimumValue: 0, maximumValue: 100, stepValue: 5, defaultValue: 50))
                        ),
                        .init(
                            key: "segment",
                            title: "Segment",
                            requiresFalse: "switch1",
                            value: .segment(.init(options: ["One", "Two", "Three"], defaultValue: 1))
                        ),
                        .init(
                            title: "Link",
                            requiresFalse: "switch1",
                            value: .link(.init(url: "https://aidoku.app", external: false))
                        ),
                        .init(
                            title: "Page",
                            requiresFalse: "switch1",
                            value: .page(.init(items: [
                                .init(
                                    title: "Stepper",
                                    value: .stepper(.init(
                                        minimumValue: 0,
                                        maximumValue: 100,
                                        stepValue: 5,
                                        defaultValue: 50
                                    ))
                                )
                            ]))
                        )
                    ]))
                )
            ],
            runner: DemoSourceRunner()
        )
    }
}

final class DemoSourceRunner: Runner, Sendable {
    let features = SourceFeatures(
        providesListings: true,
        providesHome: true,
        providesPageDescriptions: true,
    )

    let partialHomePublisher: SinglePublisher<Home>? = nil
    let partialMangaPublisher: SinglePublisher<Manga>? = .init()

    func getHome() throws -> Home {
        Home(components: [
            .init(
                title: "Big Scroller",
                subtitle: "Subtitle",
                value: .bigScroller(
                    entries: [
                        Manga(
                            sourceKey: "",
                            key: "1",
                            title: "Title 1",
                            authors: ["Author"],
                            description: "Description",
                            tags: ["Tag 1", "Tag 2", "Tag 3"],
                            status: .ongoing
                        ),
                        Manga(sourceKey: "", key: "2", title: "Title 2")
                    ],
                    autoScrollInterval: nil
                )
            ),
            .init(
                title: "Chapter List",
                subtitle: "Subtitle",
                value: .mangaChapterList(
                    pageSize: nil,
                    entries: [
                        MangaWithChapter(
                            manga: Manga(sourceKey: "", key: "2", title: "Title 2"),
                            chapter: Chapter(key: "", chapterNumber: 1, scanlators: ["Test"])
                        )
                    ],
                    listing: .init(id: "3", name: "List", kind: .list)
                )
            ),
            .init(
                title: "Manga List (Paged)",
                value: .mangaList(
                    ranking: false,
                    pageSize: 2,
                    entries: [
                        .init(title: "Title 1", subtitle: "Author", value: .manga(Manga(
                            sourceKey: "",
                            key: "1",
                            title: "Title 1",
                            authors: ["Author"]
                        ))),
                        .init(title: "Title 2", value: .manga(Manga(sourceKey: "", key: "2", title: "Title 2"))),
                        .init(title: "Title 3", value: .manga(Manga(sourceKey: "", key: "3", title: "Title 3"))),
                        .init(title: "Title 4", value: .manga(Manga(sourceKey: "", key: "4", title: "Title 4"))),
                        .init(title: "Title 5", value: .manga(Manga(sourceKey: "", key: "5", title: "Title 5"))),
                        .init(title: "Title 6", value: .manga(Manga(sourceKey: "", key: "6", title: "Title 6")))
                    ],
                    listing: .init(id: "2", name: "List", kind: .list)
                )
            ),
            .init(
                title: "Manga List (Ranking)",
                value: .mangaList(
                    ranking: true,
                    pageSize: nil,
                    entries: [
                        .init(title: "Title 1", subtitle: "Author", value: .manga(Manga(
                            sourceKey: "",
                            key: "1",
                            title: "Title 1",
                            authors: ["Author"]
                        ))),
                        .init(title: "Title 2", value: .manga(Manga(sourceKey: "", key: "2", title: "Title 2"))),
                        .init(title: "Title 3", value: .manga(Manga(sourceKey: "", key: "2", title: "Title 3")))
                    ],
                    listing: nil
                )
            ),
            .init(
                title: "Scroller",
                value: .scroller(
                    entries: [
                        .init(title: "Title 1", value: .manga(Manga(
                            sourceKey: "",
                            key: "1",
                            title: "Title 1",
                            authors: ["Author"]
                        ))),
                        .init(title: "Title 2", value: .manga(Manga(sourceKey: "", key: "2", title: "Title 2"))),
                        .init(title: "Title 3", value: .manga(Manga(sourceKey: "", key: "2", title: "Title 3"))),
                        .init(title: "Title 4", value: .manga(Manga(sourceKey: "", key: "2", title: "Title 4"))),
                        .init(title: "Title 5", value: .manga(Manga(sourceKey: "", key: "2", title: "Title 5")))
                    ],
                    listing: .init(id: "2", name: "List", kind: .list)
                )
            ),
            .init(
                title: "Filters",
                value: .filters([
                    .init(title: "Action", values: [
                        .multiselect(id: "genre", included: ["Action"], excluded: [])
                    ]),
                    .init(title: "Comedy", values: [
                        .multiselect(id: "genre", included: ["Comedy"], excluded: [])
                    ]),
                    .init(title: "Romance", values: [
                        .multiselect(id: "genre", included: ["Romance"], excluded: [])
                    ]),
                    .init(title: "SciFi", values: [
                        .multiselect(id: "genre", included: ["SciFi"], excluded: [])
                    ]),
                    .init(title: "Tag 1", values: [
                        .multiselect(id: "genre", included: ["Tag 1"], excluded: [])
                    ]),
                    .init(title: "Tag 2", values: [
                        .multiselect(id: "genre", included: ["Tag 2"], excluded: [])
                    ]),
                    .init(title: "Tag 3", values: [
                        .multiselect(id: "genre", included: ["Tag 3"], excluded: [])
                    ])
                ])
            ),
            .init(
                title: "Links",
                value: .links([
                    .init(title: "URL", value: .url("https://aidoku.app")),
                    .init(title: "Manga", value: .manga(.init(sourceKey: "", key: "1", title: "Title 1"))),
                    .init(title: "Listing", value: .listing(.init(id: "2", name: "List", kind: .list)))
                ])
            )
        ])
    }

    func getMangaList(listing: Listing, page _: Int) async throws -> MangaPageResult {
        if listing.id == "1" {
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
        if listing.id == "4" {
            throw SourceError.unimplemented
        }
        return MangaPageResult(
            entries: (1...20).map {
                Manga(
                    sourceKey: "demo",
                    key: "\($0)",
                    title: "Title \($0)",
                    cover: "https://aidoku.app/images/icon.png"
                )
            },
            hasNextPage: false
        )
    }

    func getSearchMangaList(
        query: String?,
        page: Int,
        filters _: [FilterValue]
    ) throws -> MangaPageResult {
        let offset = (page - 1) * 20
        return MangaPageResult(
            entries: {
                if let query, !query.isEmpty {
                    [
                        Manga(
                            sourceKey: "demo",
                            key: query,
                            title: query,
                            authors: ["Author"]
                        )
                    ]
                } else {
                    (offset + 1...offset + 20).map {
                        Manga(
                            sourceKey: "demo",
                            key: "\($0)",
                            title: "Title \($0)"
                        )
                    }
                }
            }(),
            hasNextPage: !(query?.isEmpty ?? true)
        )
    }

    func getMangaUpdate(manga: Manga, needsDetails: Bool, needsChapters: Bool) async throws -> Manga {
        var manga = manga

        if needsDetails {
            try? await Task.sleep(nanoseconds: 500_000_000)

            manga.title = "Title \(manga.key)"
            manga.authors = ["Author"]
            manga.artists = ["Artist"]
            manga.description = "Description"
            manga.url = URL(string: "https://aidoku.app")
            manga.tags = ["Tag 1", "Tag 2", "Tag 3"]
            manga.status = .ongoing
            manga.contentRating = .safe
            manga.viewer = .leftToRight
            manga.updateStrategy = .never

            await partialMangaPublisher?.send(manga)
        }

        if needsChapters {
            manga.chapters = [
                .init(
                    key: "3",
                    chapterNumber: 3,
                    scanlators: ["Test"],
                    thumbnail: "https://aidoku.app/images/icon.png"
                ),
                .init(key: "2", title: "Title", chapterNumber: 2, volumeNumber: 1, scanlators: ["Test"]),
                .init(key: "1", chapterNumber: 1, volumeNumber: 1),
                .init(key: "0", volumeNumber: 1)
            ]
        }

        return manga
    }

    func getPageList(manga _: Manga, chapter: Chapter) throws -> [Page] {
        if chapter.id == "3" {
            // text only chapter
            [
                .init(
                    content: .text("# Title\nThis is a text only chapter."),
                    hasDescription: true
                )
            ]
        } else {
            [
                // page that errors
                .init(
                    content: .url(url: URL(string: "https://example.com")!, context: nil),
                    hasDescription: true,
                    description: "Test Description"
                ),
                // regular image page
                .init(
                    content: .url(url: URL(string: "https://aidoku.app/images/icon.png")!, context: nil)
                ),
                // text page
                .init(
                    content: .text("[Text page](https://aidoku.app)"),
                    hasDescription: true
                )
            ]
        }
    }

    func getPageDescription(page _: Page) throws -> String? {
        "Description"
    }
}
