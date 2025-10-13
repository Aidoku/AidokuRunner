//
//  Canvas.swift
//  AidokuRunner
//
//  Created by Skitty on 8/17/24.
//

import Foundation
import Wasm3

#if canImport(UIKit)
import UIKit
#else
import AppKit

typealias UIFont = NSFont
#endif

struct Canvas: SourceLibrary {
    static let namespace = "canvas"

    let module: Module
    let store: GlobalStore

    func link() throws {
        try? module.linkFunction(name: "new_context", namespace: Self.namespace, function: newContext)
        try? module.linkFunction(name: "set_transform", namespace: Self.namespace, function: setTransform)
        try? module.linkFunction(name: "draw_image", namespace: Self.namespace, function: drawImage)
        try? module.linkFunction(name: "copy_image", namespace: Self.namespace, function: copyImage)
        try? module.linkFunction(name: "fill", namespace: Self.namespace, function: fill)
        try? module.linkFunction(name: "stroke", namespace: Self.namespace, function: stroke)
        try? module.linkFunction(name: "draw_text", namespace: Self.namespace, function: drawText)
        try? module.linkFunction(name: "get_image", namespace: Self.namespace, function: getImage)

        try? module.linkFunction(name: "new_font", namespace: Self.namespace, function: newFont)
        try? module.linkFunction(name: "system_font", namespace: Self.namespace, function: systemFont)
        try? module.linkFunction(name: "load_font", namespace: Self.namespace, function: loadFont)

        try? module.linkFunction(name: "new_image", namespace: Self.namespace, function: newImage)
        try? module.linkFunction(name: "get_image_data", namespace: Self.namespace, function: getImageData)
        try? module.linkFunction(name: "get_image_width", namespace: Self.namespace, function: getImageWidth)
        try? module.linkFunction(name: "get_image_height", namespace: Self.namespace, function: getImageHeight)
    }

    enum Result: Int32 {
        case success = 0
        case invalidContext = -1
        case invalidImagePointer = -2
        case invalidImage = -3
        case invalidSrcRect = -4
        case invalidResult = -5
        case invalidBounds = -6
        case invalidPath = -7
        case invalidStyle = -8
        case invalidString = -9
        case invalidFont = -10
        case invalidData = -11
        case fontLoadFailed = -12
    }
}

extension Canvas {
    func newContext(width: Float32, height: Float32) -> Int32 {
#if canImport(UIKit)
        guard width > 0, height > 0 else { return Result.invalidBounds.rawValue }
        UIGraphicsBeginImageContext(CGSize(width: CGFloat(width), height: CGFloat(height)))
        guard let context = UIGraphicsGetCurrentContext() else {
            return Result.invalidContext.rawValue
        }
#else
        guard
            let context = NSGraphicsContext(
                bitmapImageRep: NSBitmapImageRep(
                    bitmapDataPlanes: nil,
                    pixelsWide: Int(width),
                    pixelsHigh: Int(height),
                    bitsPerSample: 8,
                    samplesPerPixel: 4,
                    hasAlpha: true,
                    isPlanar: false,
                    colorSpaceName: .deviceRGB,
                    bytesPerRow: 0,
                    bitsPerPixel: 0
                )!
            )?.cgContext
        else {
            return Result.invalidContext.rawValue
        }
#endif
        return store.store(CGContextHolder(context))
    }

    // swiftlint:disable:next function_parameter_count
    func setTransform(
        contextPtr: Int32,
        translateX: Float32,
        translateY: Float32,
        scaleX: Float32,
        scaleY: Float32,
        rotateAngle: Float32,
    ) -> Int32 {
        guard let context = (store.fetch(from: contextPtr) as? CGContextHolder)?.context else {
            return Result.invalidContext.rawValue
        }

        context.restoreGState()
        context.saveGState()

        context.translateBy(x: CGFloat(translateX), y: CGFloat(translateY))
        context.scaleBy(x: CGFloat(scaleX), y: CGFloat(scaleY))
        context.rotate(by: CGFloat(rotateAngle))

        return Result.success.rawValue
    }

    // swiftlint:disable:next function_parameter_count
    func drawImage(
        contextPtr: Int32,
        imagePtr: Int32,
        dstX: Float32,
        dstY: Float32,
        dstWidth: Float32,
        dstHeight: Float32
    ) -> Int32 {
        guard let context = (store.fetch(from: contextPtr) as? CGContextHolder)?.context else {
            return Result.invalidContext.rawValue
        }
        guard let image = store.fetchImage(from: imagePtr) else {
            return Result.invalidImagePointer.rawValue
        }
#if canImport(UIKit)
        guard let cgImage = image.cgImage else {
            return Result.invalidImage.rawValue
        }
#else
        guard
            let imageData = image.image.tiffRepresentation,
            let bitmapImageRep = NSBitmapImageRep(data: imageData),
            let cgImage = bitmapImageRep.cgImage
        else {
            return Result.invalidImage.rawValue
        }
#endif
        let dstRect = CGRect(x: CGFloat(dstX), y: CGFloat(dstY), width: CGFloat(dstWidth), height: CGFloat(dstHeight))
        context.saveGState()
        context.flipVertically()
        context.draw(
            cgImage,
            in: dstRect.adjustForFlippedCoordinates(imageHeight: CGFloat(cgImage.height))
        )
        context.restoreGState()
        return Result.success.rawValue
    }

    // swiftlint:disable:next function_parameter_count
    func copyImage(
        contextPtr: Int32,
        imagePtr: Int32,
        srcX: Float32,
        srcY: Float32,
        srcWidth: Float32,
        srcHeight: Float32,
        dstX: Float32,
        dstY: Float32,
        dstWidth: Float32,
        dstHeight: Float32
    ) -> Int32 {
        guard let context = (store.fetch(from: contextPtr) as? CGContextHolder)?.context else {
            return Result.invalidContext.rawValue
        }
        guard let image = store.fetchImage(from: imagePtr) else {
            return Result.invalidImagePointer.rawValue
        }
#if canImport(UIKit)
        guard let cgImage = image.cgImage else {
            return Result.invalidImage.rawValue
        }
#else
        guard
            let imageData = image.image.tiffRepresentation,
            let bitmapImageRep = NSBitmapImageRep(data: imageData),
            let cgImage = bitmapImageRep.cgImage
        else {
            return Result.invalidImage.rawValue
        }
#endif
        let srcRect = CGRect(x: CGFloat(srcX), y: CGFloat(srcY), width: CGFloat(srcWidth), height: CGFloat(srcHeight))
        let dstRect = CGRect(x: CGFloat(dstX), y: CGFloat(dstY), width: CGFloat(dstWidth), height: CGFloat(dstHeight))
        guard let srcImage = cgImage.cropping(to: srcRect) else {
            return Result.invalidSrcRect.rawValue
        }
        context.saveGState()
        context.flipVertically()
        context.draw(
            srcImage,
            in: dstRect.adjustForFlippedCoordinates(imageHeight: CGFloat(cgImage.height))
        )
        context.restoreGState()
        return Result.success.rawValue
    }

    // swiftlint:disable:next function_parameter_count
    func fill(
        memory: Memory,
        contextPtr: Int32,
        pathPtr: Int32,
        r: Float32,
        g: Float32,
        b: Float32,
        a: Float32
    ) -> Int32 {
        guard let context = (store.fetch(from: contextPtr) as? CGContextHolder)?.context else {
            return Result.invalidContext.rawValue
        }
        guard
            let pathLen: UInt32 = try? memory.readValues(offset: UInt32(pathPtr), length: 1)[0],
            let pathData = try? memory.readData(offset: UInt32(pathPtr) + 8, length: pathLen - 8),
            let path = try? PostcardDecoder().decode(Path.self, from: pathData)
        else {
            return Result.invalidPath.rawValue
        }

        let color = Color(red: r, green: g, blue: b, alpha: a)
        path.fill(in: context, color: color)

        return Result.success.rawValue
    }

    func stroke(
        memory: Memory,
        contextPtr: Int32,
        pathPtr: Int32,
        stylePtr: Int32,
    ) -> Int32 {
        guard let context = (store.fetch(from: contextPtr) as? CGContextHolder)?.context else {
            return Result.invalidContext.rawValue
        }
        guard
            let pathLen: UInt32 = try? memory.readValues(offset: UInt32(pathPtr), length: 1)[0],
            let pathData = try? memory.readData(offset: UInt32(pathPtr) + 8, length: pathLen - 8),
            let path = try? PostcardDecoder().decode(Path.self, from: pathData)
        else {
            return Result.invalidPath.rawValue
        }
        guard
            let styleLen: UInt32 = try? memory.readValues(offset: UInt32(stylePtr), length: 1)[0],
            let styleData = try? memory.readData(offset: UInt32(stylePtr) + 8, length: styleLen - 8),
            let style = try? PostcardDecoder().decode(StrokeStyle.self, from: styleData)
        else {
            return Result.invalidStyle.rawValue
        }

        path.stroke(in: context, style: style)

        return Result.success.rawValue
    }

    // swiftlint:disable:next function_parameter_count
    func drawText(
        memory: Memory,
        contextPtr: Int32,
        textPtr: Int32,
        textLen: Int32,
        size: Float32,
        x: Float32,
        y: Float32,
        fontPtr: Int32,
        r: Float32,
        g: Float32,
        b: Float32,
        a: Float32
    ) -> Int32 {
        guard let context = (store.fetch(from: contextPtr) as? CGContextHolder)?.context else {
            return Result.invalidContext.rawValue
        }
        guard let font = store.fetch(from: fontPtr) as? UIFont else {
            return Result.invalidFont.rawValue
        }
        guard
            textPtr >= 0, textLen >= 0,
            let string = try? memory.readString(offset: UInt32(textPtr), length: UInt32(textLen))
        else {
            return Result.invalidString.rawValue
        }

        let color = Color(red: r, green: g, blue: b, alpha: a)

        context.saveGState()

        context.flipVertically()

        let text = NSAttributedString(string: string, attributes: [
            .foregroundColor: color.into(),
            .font: font.withSize(CGFloat(size))
        ])
        let line = CTLineCreateWithAttributedString(text)
        let stringRect = CTLineGetImageBounds(line, context)
        context.textPosition = CGPoint(
            x: CGFloat(x),
            y: CGFloat(context.height) - CGFloat(y) - stringRect.height
        )
        CTLineDraw(line, context)

        context.restoreGState()

        return Result.success.rawValue
    }

    func getImage(contextPtr: Int32) -> Int32 {
        guard let context = (store.fetch(from: contextPtr) as? CGContextHolder)?.context else {
            return Result.invalidContext.rawValue
        }
#if canImport(UIKit)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let image else {
            return Result.invalidResult.rawValue
        }
        return store.store(image)
#else
        let cgImage = context.makeImage()
        if let cgImage {
            let image = NSImage(cgImage: cgImage, size: CGSize(width: context.width, height: context.height))
            return store.store(image)
        } else {
            return Result.invalidResult.rawValue
        }
#endif
    }
}

// MARK: Fonts
extension Canvas {
    func newFont(memory: Memory, namePtr: Int32, nameLen: Int32) -> Int32 {
        guard
            namePtr >= 0, nameLen >= 0,
            let name = try? memory.readString(offset: UInt32(namePtr), length: UInt32(nameLen))
        else {
            return Result.invalidString.rawValue
        }
        guard let font = UIFont(name: name, size: UIFont.systemFontSize) else {
            return Result.invalidFont.rawValue
        }
        return store.store(font)
    }

    enum FontWeight: UInt8 {
        case ultraLight = 0
        case thin
        case light
        case regular
        case medium
        case semibold
        case bold
        case heavy
        case black

        func into() -> UIFont.Weight {
            switch self {
                case .ultraLight: .ultraLight
                case .thin: .thin
                case .light: .light
                case .regular: .regular
                case .medium: .medium
                case .semibold: .semibold
                case .bold: .bold
                case .heavy: .heavy
                case .black: .black
            }
        }
    }

    func systemFont(weight: Int32) -> Int32 {
        let weight = FontWeight(rawValue: UInt8(weight)) ?? .regular
        return store.store(UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: weight.into()))
    }

    func loadFont(memory: Memory, urlPtr: Int32, urlLen: Int32) -> Int32 {
        guard
            urlPtr >= 0, urlLen >= 0,
            let urlString = try? memory.readString(offset: UInt32(urlPtr), length: UInt32(urlLen)),
            let url = URL(string: urlString)
        else {
            return Result.invalidString.rawValue
        }
        guard
            let dataProvider = CGDataProvider(url: url as CFURL),
            let font = CGFont(dataProvider)
        else {
            return Result.fontLoadFailed.rawValue
        }

        CTFontManagerRegisterGraphicsFont(font, nil)

        guard
            let name = font.postScriptName as? String,
            let uiFont = UIFont(name: name, size: UIFont.systemFontSize)
        else {
            return Result.fontLoadFailed.rawValue
        }

        return store.store(uiFont)
    }
}

// MARK: Images
extension Canvas {
    func newImage(memory: Memory, dataPtr: Int32, dataLen: Int32) -> Int32 {
        guard
            dataPtr >= 0, dataLen >= 0,
            let data = try? memory.readData(offset: UInt32(dataPtr), length: UInt32(dataLen))
        else {
            return Result.invalidData.rawValue
        }
        guard let image = PlatformImage(data: data) else {
            return Result.invalidImage.rawValue
        }
        return store.store(image)
    }

    func getImageData(imagePtr: Int32) -> Int32 {
        let result = store.fetch(from: imagePtr)
        guard let image = result as? PlatformImage else {
            // return a copy of the data if this is already raw data
            if let data = result as? Data {
                return store.store(data)
            }
            return Result.invalidImagePointer.rawValue
        }
        guard let data = image.pngData() else {
            return Result.invalidImage.rawValue
        }
        return store.store(data)
    }

    func getImageWidth(imagePtr: Int32) -> Float32 {
        guard let image = store.fetchImage(from: imagePtr) else {
            return Float32(Result.invalidImagePointer.rawValue)
        }
        return Float32(image.size.width)
    }

    func getImageHeight(imagePtr: Int32) -> Float32 {
        guard let image = store.fetchImage(from: imagePtr) else {
            return Float32(Result.invalidImagePointer.rawValue)
        }
        return Float32(image.size.height)
    }
}

// MARK: - Related Structs and Enums

struct Point: Codable {
    let x: Float32
    let y: Float32
}

extension Point {
    func into() -> CGPoint {
        CGPoint(x: CGFloat(x), y: CGFloat(y))
    }
}

enum PathOp {
    case moveTo(Point)
    case lineTo(Point)
    case quadTo(Point, Point)
    case cubicTo(Point, Point, Point)
    case arc(Point, Float32, Float32, Float32)
    case close
}

extension PathOp: Decodable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let type = try container.decode(UInt8.self, forKey: .type)

        switch type {
            case 0:
                let point = try container.decode(Point.self, forKey: .moveTo)
                self = .moveTo(point)
            case 1:
                let point = try container.decode(Point.self, forKey: .lineTo)
                self = .lineTo(point)
            case 2:
                let point1 = try container.decode(Point.self, forKey: .quadTo)
                let point2 = try container.decode(Point.self, forKey: .quadTo)
                self = .quadTo(point1, point2)
            case 3:
                let point1 = try container.decode(Point.self, forKey: .cubicTo)
                let point2 = try container.decode(Point.self, forKey: .cubicTo)
                let point3 = try container.decode(Point.self, forKey: .cubicTo)
                self = .cubicTo(point1, point2, point3)
            case 4:
                let point = try container.decode(Point.self, forKey: .arc)
                let radius = try container.decode(Float32.self, forKey: .arc)
                let startAngle = try container.decode(Float32.self, forKey: .arc)
                let endAngle = try container.decode(Float32.self, forKey: .arc)
                self = .arc(point, radius, startAngle, endAngle)
            case 5:
                self = .close
            default:
                throw DecodingError.dataCorruptedError(
                    forKey: .type,
                    in: container,
                    debugDescription: "Invalid PathOp type \(type)"
                )
        }
    }

    enum CodingKeys: CodingKey {
        case type

        case moveTo
        case lineTo
        case quadTo
        case cubicTo
        case arc
        case close
    }
}

struct Path: Decodable {
    let ops: [PathOp]
}

enum LineCap: UInt8, Codable {
    case round = 0
    case square = 1
    case butt = 2
}

enum LineJoin: UInt8, Codable {
    case round = 0
    case bevel = 1
    case miter = 2
}

struct Color: Codable {
    let red: Float32
    let green: Float32
    let blue: Float32
    let alpha: Float32
}

extension Color {
    func into() -> CGColor {
        .init(
            red: CGFloat(red),
            green: CGFloat(green),
            blue: CGFloat(blue),
            alpha: CGFloat(alpha)
        )
    }
}

struct StrokeStyle: Codable {
    let color: Color
    let width: Float32
    let cap: LineCap
    let join: LineJoin
    let miterLimit: Float32
    let dashArray: [Float32]
    let dashOffset: Float32
}

extension StrokeStyle {
    func addTo(context: CGContext) {
        context.setStrokeColor(color.into())
        context.setLineWidth(CGFloat(width))
        switch cap {
            case .round:
                context.setLineCap(.round)
            case .square:
                context.setLineCap(.square)
            case .butt:
                context.setLineCap(.butt)
        }
        switch join {
            case .round:
                context.setLineJoin(.round)
            case .bevel:
                context.setLineJoin(.bevel)
            case .miter:
                context.setLineJoin(.miter)
        }
        context.setMiterLimit(CGFloat(miterLimit))
        if !dashArray.isEmpty {
            context.setLineDash(phase: CGFloat(dashOffset), lengths: dashArray.map { CGFloat($0) })
        }
    }
}

extension Path {
    func draw(in context: CGContext) {
        var pathOpen = false
        for op in ops {
            if !pathOpen {
                context.beginPath()
                pathOpen = true
            }
            switch op {
                case let .moveTo(point):
                    context.move(to: point.into())
                case let .lineTo(point):
                    context.addLine(to: point.into())
                case let .quadTo(point, point2):
                    context.addQuadCurve(to: point.into(), control: point2.into())
                case let .cubicTo(point, point2, point3):
                    context.addCurve(
                        to: point.into(),
                        control1: point2.into(),
                        control2: point3.into()
                    )
                case let .arc(center, radius, startAngle, sweepAngle):
                    context.addArc(
                        center: center.into(),
                        radius: CGFloat(radius),
                        startAngle: CGFloat(startAngle),
                        endAngle: CGFloat(abs(sweepAngle)),
                        clockwise: sweepAngle >= 0
                    )
                case .close:
                    context.closePath()
                    pathOpen = false
            }
        }
    }

    func stroke(in context: CGContext, style: StrokeStyle) {
        context.saveGState()
        draw(in: context)
        style.addTo(context: context)
        context.strokePath()
        context.restoreGState()
    }

    func fill(in context: CGContext, color: Color) {
        context.saveGState()
        draw(in: context)
        context.setFillColor(color.into())
        context.fillPath()
        context.restoreGState()
    }
}

// MARK: - CoreGraphics Extensions

private extension CGContext {
    func flipVertically() {
        translateBy(x: 0, y: CGFloat(height))
        scaleBy(x: 1, y: -1)
    }
}

private extension CGRect {
    func adjustForFlippedCoordinates(imageHeight: CGFloat) -> CGRect {
        .init(
            x: origin.x,
            y: imageHeight - origin.y - size.height,
            width: size.width,
            height: size.height
        )
    }
}

private class CGContextHolder {
    let context: CGContext

    init(_ context: CGContext) {
        self.context = context
    }
}

private class CGImageHolder {
    let image: CGImage

    init(_ image: CGImage) {
        self.image = image
    }
}
