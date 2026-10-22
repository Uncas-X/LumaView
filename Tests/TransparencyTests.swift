import AppKit
import ImageIO
import QuartzCore
import UniformTypeIdentifiers

private struct TransparencyFailure: Error, CustomStringConvertible { let description: String }

/// Pixel regressions for image transparency, including separately attached Quartz
/// masks: alphaInfo alone cannot describe the visible shape of those CGImages.
@main struct TransparencyTests {
    private static var checks = 0
    private static let side = 400
    private static var output: URL!

    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        var failure: Error?
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { _ in
            do { try run() } catch { failure = error }
            app.stop(nil)
            if let event = NSEvent.otherEvent(with: .applicationDefined, location: .zero, modifierFlags: [], timestamp: 0,
                                              windowNumber: 0, context: nil, subtype: 0, data1: 0, data2: 0) {
                app.postEvent(event, atStart: true)
            }
        }
        app.run()
        if let failure { fputs("FAIL: \(failure)\n", stderr); exit(1) }
    }

    private static func run() throws {
        output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 800, height: 800),
                              styleMask: [.borderless], backing: .buffered, defer: false)
        let canvas = PhotoCanvas(frame: NSRect(x: 0, y: 0, width: 800, height: 800))
        canvas.animationsEnabled = false
        canvas.backgroundMode = .light
        window.contentView = canvas
        window.orderFrontRegardless()
        defer { window.orderOut(nil) }
        let size = CGSize(width: CGFloat(side) * window.backingScaleFactor, height: CGFloat(side) * window.backingScaleFactor)
        let ring = try makeImage(style: .ring)
        let empty = try makeImage(style: .empty)
        let disk = try makeImage(style: .disk)
        var fixtures: [(String, CGImage)] = [("rgba", ring), ("soft-mask", try makeMaskedImage())]
        for (name, type) in [("png", UTType.png.identifier), ("gif", UTType.gif.identifier)] {
            let url = output.appendingPathComponent("transparent-ring.\(name)")
            guard let destination = CGImageDestinationCreateWithURL(url as CFURL, type as CFString, 1, nil) else {
                throw TransparencyFailure(description: "create \(name) fixture")
            }
            CGImageDestinationAddImage(destination, ring, nil)
            guard CGImageDestinationFinalize(destination),
                  let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let decoded = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                throw TransparencyFailure(description: "decode \(name) fixture")
            }
            fixtures.append((name, decoded))
        }
        for version in [1, 2] {
            let name = version == 1 ? "psd" : "psb"
            let url = output.appendingPathComponent("transparent-ring.\(name)")
            try writePhotoshop(url, version: version)
            let decoded = try PhotoshopImage.render(url: url, maxPixelDimension: side)
            try check(decoded.header.hasMergedTransparency, "\(name) fixture declares actual composite transparency")
            fixtures.append((name, decoded.image))
        }
        try check(fixtures[1].1.alphaInfo == .noneSkipLast || fixtures[1].1.alphaInfo == .none,
                  "separate image mask exercises transparency without an alphaInfo alpha-channel case")

        for (name, fixture) in fixtures {
            canvas.setImage(fixture, pixelSize: size, animated: false)
            refresh(canvas)
            for layers in [false, true] {
                let path = layers ? "layers" : "draw"
                let image = try render(canvas, layers: layers)
                try writePNG(image, name: "\(name)-\(path).png")
                try ringChecks(image, context: "\(name) \(path)")
            }
        }

        // An image with every pixel transparent still counts as open media. It
        // must not reintroduce a welcome texture, checkerboard, frame or shadow.
        canvas.setImage(empty, pixelSize: size, animated: false)
        refresh(canvas)
        for layers in [false, true] {
            let image = try render(canvas, layers: layers)
            try check(image.maximumDifference(in: CGRect(x: 1, y: 1, width: 798, height: 798), from: image.pixel(10, 10)) == 0,
                      "fully transparent \(layers ? "layers" : "draw") image leaves only the viewer background")
        }

        // GIF/APNG frame updates take the reset:false route. The opaque shape
        // changes without replacing the layer, resetting zoom or leaving a mask.
        canvas.setImage(ring, pixelSize: size, animated: false)
        canvas.zoomBy(1.2)
        canvas.rotate(1)
        let zoom = canvas.zoom, current = try currentLayer(canvas)
        canvas.setImage(disk, pixelSize: size, reset: false, animated: false)
        refresh(canvas)
        try check(try currentLayer(canvas) === current && canvas.zoom == zoom && canvas.quarterTurns == 1,
                  "frame alpha replacement preserves the current transform and texture layer")
        for layers in [false, true] {
            let image = try render(canvas, layers: layers)
            try check(image.pixel(400, 445)[0] > 200 && image.pixel(400, 445)[1] < 100,
                      "replacement frame fills the previous transparent hole in \(layers ? "layers" : "draw")")
        }
        canvas.setImage(empty, pixelSize: size, reset: false, animated: false)
        refresh(canvas)
        for layers in [false, true] {
            let image = try render(canvas, layers: layers)
            try check(image.maximumDifference(in: CGRect(x: 1, y: 1, width: 798, height: 798), from: image.pixel(10, 10)) == 0,
                      "fully transparent animation frame clears prior image and contour shadow in \(layers ? "layers" : "draw")")
        }
        canvas.setImage(ring, pixelSize: size, animated: false)
        canvas.zoomBy(1.2)
        canvas.rotate(1)
        refresh(canvas)
        for layers in [false, true] {
            let image = try render(canvas, layers: layers)
            let baseline = image.pixel(10, 10)
            try check(image.maximumDifference(in: CGRect(x: 168, y: 213, width: 32, height: 32), from: baseline) <= 1,
                      "rotated and zoomed transparent corner stays clear in \(layers ? "layers" : "draw")")
            try check(image.maximumDifference(in: CGRect(x: 398, y: 443, width: 4, height: 4), from: baseline) <= 2,
                      "rotated and zoomed center hole stays transparent in \(layers ? "layers" : "draw")")
            try check(image.darkPixelCount(in: CGRect(x: 260, y: 305, width: 280, height: 280), baseline: baseline) > 100,
                      "rotated and zoomed opaque contour retains a visible shadow in \(layers ? "layers" : "draw")")
        }

        // Rapid file switches use a snapshot of the outgoing composition. Verify
        // that the settled result and the live incoming texture keep transparency.
        canvas.animationsEnabled = true
        canvas.setImage(disk, pixelSize: size, animated: true)
        pump(0.045)
        canvas.setImage(ring, pixelSize: size, animated: true)
        canvas.setImage(try makeMaskedImage(), pixelSize: size, reset: false, animated: false)
        pump(0.4)
        refresh(canvas)
        try check(!canvas.isAnimating, "rapid transparent transitions settle and release the outgoing composition")
        for layers in [false, true] {
            try ringChecks(try render(canvas, layers: layers), context: "transition \(layers ? "layers" : "draw")")
        }
        canvas.backgroundMode = .translucent
        canvas.setImage(ring, pixelSize: size, animated: false)
        refresh(canvas)
        for layers in [false, true] {
            let image = try render(canvas, layers: layers)
            try check(image.maximumDifference(in: CGRect(x: 205, y: 250, width: 42, height: 42), from: image.pixel(10, 10)) <= 1,
                      "translucent viewer mode preserves clear margins in \(layers ? "layers" : "draw")")
            try check(image.pixel(400, 445)[3] < 100,
                      "translucent viewer mode leaves the center hole translucent in \(layers ? "layers" : "draw")")
        }
        print("PASS: \(checks) image transparency / contour shadow / animation checks")
    }

    private static func ringChecks(_ image: Pixels, context: String) throws {
        let baseline = image.pixel(10, 10)
        // Fixture rectangle is (200,245)-(600,645). There is 100 pt of clear
        // space before its round content, making former rectangular shadows and
        // checker fills independently observable around the whole outer edge.
        for rect in [CGRect(x: 196, y: 241, width: 55, height: 408), CGRect(x: 549, y: 241, width: 55, height: 408),
                     CGRect(x: 196, y: 241, width: 408, height: 55), CGRect(x: 196, y: 594, width: 408, height: 55)] {
            try check(image.maximumDifference(in: rect, from: baseline) <= 1,
                      "\(context): clear canvas margin has no checker fill, border or rectangular shadow")
        }
        try check(image.maximumDifference(in: CGRect(x: 397, y: 442, width: 6, height: 6), from: baseline) <= 2,
                  "\(context): center of shape's hole reveals the viewer background")
        let filled = image.pixel(400, 525)
        try check(filled[0] > 200 && filled[1] < 100 && filled[2] < 120,
                  "\(context): opaque image pixels keep their own colors")
        try check(image.darkPixelCount(in: CGRect(x: 275, y: 320, width: 30, height: 250), baseline: baseline) > 30,
                  "\(context): shadow follows the exterior round contour")
        try check(image.darkPixelCount(in: CGRect(x: 365, y: 410, width: 70, height: 70), baseline: baseline) > 30,
                  "\(context): shadow also follows the inner transparent hole")
    }

    private enum Style { case ring, disk, empty }
    private static func rgba(style: Style) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: side * side * 4)
        for y in 0..<side {
            for x in 0..<side {
                let radius = hypot(Double(x) + 0.5 - 200, Double(y) + 0.5 - 200)
                let opaque = style != .empty && ((radius <= 100 && (style == .disk || radius >= 45)) ||
                                                (x >= 285 && x < 320 && y >= 185 && y < 215))
                if opaque {
                    let i = (y * side + x) * 4
                    bytes[i] = 235; bytes[i + 1] = 40; bytes[i + 2] = 72; bytes[i + 3] = 255
                }
            }
        }
        return bytes
    }
    private static func makeImage(style: Style) throws -> CGImage {
        guard let provider = CGDataProvider(data: Data(rgba(style: style)) as CFData),
              let image = CGImage(width: side, height: side, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: side * 4,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                                  provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else {
            throw TransparencyFailure(description: "RGBA fixture")
        }
        return image
    }
    private static func makeMaskedImage() throws -> CGImage {
        var base = [UInt8](repeating: 0, count: side * side * 4)
        let source = rgba(style: .ring)
        var inverse = [UInt8](repeating: 0, count: side * side)
        for i in 0..<(side * side) {
            base[i * 4] = 235; base[i * 4 + 1] = 40; base[i * 4 + 2] = 72
            inverse[i] = 255 - source[i * 4 + 3]
        }
        guard let provider = CGDataProvider(data: Data(base) as CFData),
              let image = CGImage(width: side, height: side, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: side * 4,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                                  provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent),
              let maskProvider = CGDataProvider(data: Data(inverse) as CFData),
              let mask = CGImage(maskWidth: side, height: side, bitsPerComponent: 8, bitsPerPixel: 8,
                                 bytesPerRow: side, provider: maskProvider, decode: nil, shouldInterpolate: true),
              let masked = image.masking(mask) else { throw TransparencyFailure(description: "separate Quartz mask fixture") }
        return masked
    }
    private static func writePhotoshop(_ url: URL, version: Int) throws {
        func be(_ n: Int, _ bytes: Int) -> Data {
            Data((0..<bytes).reversed().map { UInt8(truncatingIfNeeded: UInt64(n) >> ($0 * 8)) })
        }
        let lengthBytes = version == 2 ? 8 : 4
        var layers = Data(repeating: 0, count: lengthBytes + 4)
        layers.append(Data("8BIMMtrn".utf8)); layers.append(be(0, lengthBytes))
        var bytes = Data("8BPS".utf8)
        bytes.append(be(version, 2)); bytes.append(Data(repeating: 0, count: 6))
        bytes.append(be(4, 2)); bytes.append(be(side, 4)); bytes.append(be(side, 4))
        bytes.append(be(8, 2)); bytes.append(be(3, 2)); bytes.append(be(0, 4)); bytes.append(be(0, 4))
        bytes.append(be(layers.count, lengthBytes)); bytes.append(layers); bytes.append(be(0, 2))
        let source = rgba(style: .ring)
        for channel in 0..<4 {
            for i in 0..<(side * side) {
                // Photoshop composites are white-matted before their explicit
                // alpha plane; transparent pixels therefore have white RGB.
                bytes.append(channel == 3 ? source[i * 4 + 3] : (source[i * 4 + 3] == 0 ? 255 : source[i * 4 + channel]))
            }
        }
        try bytes.write(to: url)
    }

    private struct Pixels {
        let bytes: [UInt8]
        let width = 800, height = 800
        func pixel(_ x: Int, _ y: Int) -> [UInt8] {
            let i = ((height - 1 - y) * width + x) * 4
            return Array(bytes[i..<(i + 4)])
        }
        func maximumDifference(in rect: CGRect, from baseline: [UInt8]) -> Int {
            var maximum = 0
            for y in Int(rect.minY)..<Int(rect.maxY) {
                for x in Int(rect.minX)..<Int(rect.maxX) {
                    let actual = pixel(x, y)
                    for channel in 0..<4 { maximum = max(maximum, abs(Int(actual[channel]) - Int(baseline[channel]))) }
                }
            }
            return maximum
        }
        func darkPixelCount(in rect: CGRect, baseline: [UInt8]) -> Int {
            var count = 0
            for y in Int(rect.minY)..<Int(rect.maxY) {
                for x in Int(rect.minX)..<Int(rect.maxX) {
                    let actual = pixel(x, y)
                    // Neutral darkening distinguishes the shadow from red image
                    // pixels and checks the visual result, not layer properties.
                    if abs(Int(actual[0]) - Int(actual[1])) <= 3 && abs(Int(actual[1]) - Int(actual[2])) <= 4 &&
                        Int(actual[0]) <= Int(baseline[0]) - 3 { count += 1 }
                }
            }
            return count
        }
    }
    private static func render(_ canvas: PhotoCanvas, layers: Bool) throws -> Pixels {
        var bytes = [UInt8](repeating: 0, count: 800 * 800 * 4)
        try bytes.withUnsafeMutableBytes { storage in
            guard let context = CGContext(data: storage.baseAddress, width: 800, height: 800, bitsPerComponent: 8,
                                          bytesPerRow: 3200, space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
                throw TransparencyFailure(description: "snapshot context")
            }
            NSGraphicsContext.saveGraphicsState()
            defer { NSGraphicsContext.restoreGraphicsState() }
            NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
            if layers { canvas.layer?.render(in: context) }
            else { canvas.draw(canvas.bounds) }
        }
        return Pixels(bytes: bytes)
    }
    private static func writePNG(_ pixels: Pixels, name: String) throws {
        guard let provider = CGDataProvider(data: Data(pixels.bytes) as CFData),
              let image = CGImage(width: 800, height: 800, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 3200,
                                  space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                                  provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent),
              let destination = CGImageDestinationCreateWithURL(output.appendingPathComponent(name) as CFURL, UTType.png.identifier as CFString, 1, nil)
        else { throw TransparencyFailure(description: "snapshot PNG") }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw TransparencyFailure(description: "save snapshot PNG") }
    }
    private static func currentLayer(_ canvas: PhotoCanvas) throws -> CALayer {
        guard let current = canvas.layer?.sublayers?.first(where: { $0.name == "photo-host" })?.sublayers?.first(where: { $0.name == "photo-current" }) else {
            throw TransparencyFailure(description: "current media layer")
        }
        return current
    }
    private static func refresh(_ canvas: PhotoCanvas) { canvas.updateLayer(); canvas.displayIfNeeded(); CATransaction.flush(); pump(0.02) }
    private static func pump(_ duration: TimeInterval) {
        let end = Date().addingTimeInterval(duration)
        while Date() < end { CATransaction.flush(); RunLoop.main.run(until: Date().addingTimeInterval(0.005)) }
    }
    private static func check(_ condition: @autoclosure () throws -> Bool, _ message: String) throws {
        guard try condition() else { throw TransparencyFailure(description: message) }
        checks += 1
    }
}
