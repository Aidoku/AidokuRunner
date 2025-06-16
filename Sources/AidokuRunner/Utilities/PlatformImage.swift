//
//  PlatformImage.swift
//  AidokuRunner
//
//  Created by Skitty on 5/27/25.
//

#if canImport(UIKit)

import UIKit
public typealias PlatformImage = UIImage

public extension UIImage {
    // shim function, so the image of PlatformImage can be accessed at .image for both UIKit and AppKit
    var image: UIImage {
        self
    }
}

#else

import AppKit
public typealias PlatformImage = NSImageFixed

public struct NSImageFixed: @unchecked Sendable, Hashable {
    public let image: NSImage

    public var size: NSSize {
        image.size
    }

    public init(_ image: NSImage) {
        self.image = image
    }

    public init?(data: Data) {
        guard let image = NSImage(data: data) else { return nil }
        self.image = image
    }

    public func pngData() -> Data? {
        guard
            let data = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: data)
        else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
    }
}

#endif
