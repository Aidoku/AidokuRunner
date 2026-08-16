//
//  WKWebsiteDataStore.swift
//  AidokuRunner
//
//  Created by skitty on 8/16/26.
//

import WebKit

extension WKWebsiteDataStore {
    func clearRecords() async {
        await withCheckedContinuation { continuation in
            fetchDataRecords(ofTypes: Self.allWebsiteDataTypes()) { records in
                for record in records {
                    // swiftlint:disable:next no_empty_block
                    self.removeData(ofTypes: record.dataTypes, for: [record]) {}
                }
                continuation.resume()
            }
        }
    }
}
