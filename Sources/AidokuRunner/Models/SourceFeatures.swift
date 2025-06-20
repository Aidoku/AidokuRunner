//
//  SourceFeatures.swift
//  AidokuRunner
//
//  Created by Skitty on 5/27/25.
//

import Foundation

public struct SourceFeatures: Sendable {
    public let providesListings: Bool
    public let providesHome: Bool
    public let dynamicFilters: Bool
    public let dynamicSettings: Bool
    public let dynamicListings: Bool
    public let processesPages: Bool
    public let providesImageRequests: Bool
    public let providesPageDescriptions: Bool
    public let providesAlternateCovers: Bool
    public let providesBaseUrl: Bool
    public let handlesNotifications: Bool
    public let handlesDeepLinks: Bool
    public let handlesBasicLogin: Bool
    public let handlesWebLogin: Bool
    public let handlesMigration: Bool

    public init(
        providesListings: Bool = false,
        providesHome: Bool = false,
        dynamicFilters: Bool = false,
        dynamicSettings: Bool = false,
        dynamicListings: Bool = false,
        processesPages: Bool = false,
        providesImageRequests: Bool = false,
        providesPageDescriptions: Bool = false,
        providesAlternateCovers: Bool = false,
        providesBaseUrl: Bool = false,
        handlesNotifications: Bool = false,
        handlesDeepLinks: Bool = false,
        handlesBasicLogin: Bool = false,
        handlesWebLogin: Bool = false,
        handlesMigration: Bool = false
    ) {
        self.providesListings = providesListings
        self.providesHome = providesHome
        self.dynamicFilters = dynamicFilters
        self.dynamicSettings = dynamicSettings
        self.dynamicListings = dynamicListings
        self.processesPages = processesPages
        self.providesImageRequests = providesImageRequests
        self.providesPageDescriptions = providesPageDescriptions
        self.providesAlternateCovers = providesAlternateCovers
        self.providesBaseUrl = providesBaseUrl
        self.handlesNotifications = handlesNotifications
        self.handlesDeepLinks = handlesDeepLinks
        self.handlesBasicLogin = handlesBasicLogin
        self.handlesWebLogin = handlesWebLogin
        self.handlesMigration = handlesMigration
    }
}
