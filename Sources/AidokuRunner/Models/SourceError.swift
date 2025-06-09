//
//  SourceError.swift
//  AidokuRunner
//
//  Created by Skitty on 5/9/25.
//

import Foundation

public enum SourceError: Error, Equatable {
    case missingResult
    case unimplemented
    case networkError
    case message(String)
}
