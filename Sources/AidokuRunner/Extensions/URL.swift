//
//  URL.swift
//  AidokuRunner
//
//  Created by Skitty on 8/21/23.
//

import Foundation

extension URL {
    func filePath() -> String {
        if #available(iOS 16.0, macOS 13.0, *) {
            path(percentEncoded: false)
        } else {
            path
        }
    }

    func appending(_ path: String) -> URL {
        if #available(iOS 16.0, macOS 13.0, *) {
            appending(path: path)
        } else {
            appendingPathComponent(path)
        }
    }
}
