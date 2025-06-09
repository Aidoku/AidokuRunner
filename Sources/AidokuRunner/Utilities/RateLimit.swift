//
//  RateLimit.swift
//  AidokuRunner
//
//  Created by Skitty on 2/6/25.
//

import Foundation

actor RateLimit {
    var permits = 0
    var period = 0

    private var currentPeriodStart = 0
    var requestsInPeriod = 0

    var isEnabled: Bool {
        permits > 0 && period > 0
    }

    var inPeriod: Bool {
        let now = Int(Date().timeIntervalSince1970)
        return now - currentPeriodStart < period
    }

    var atLimit: Bool {
        inPeriod && requestsInPeriod >= permits
    }

    var nextPeriodStart: Int {
        currentPeriodStart + period
    }

    func set(permits: Int, period: Int) {
        self.permits = permits
        self.period = period
    }

    func incRequest() -> Bool {
        guard isEnabled else { return true }
        if atLimit {
            return false
        }
        if !inPeriod {
            resetPeriod()
        }
        requestsInPeriod += 1
        return true
    }

    private func resetPeriod() {
        currentPeriodStart = Int(Date().timeIntervalSince1970)
        requestsInPeriod = 0
    }
}
