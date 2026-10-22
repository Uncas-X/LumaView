import AppKit
import Foundation
import ImageIO
import CryptoKit

private struct CompatibilityFailure: Error { let message: String }

@main
struct VectorCompatibilityTests {
    private static var checks = 0

    static func main() throws {
        setbuf(stdout, nil)
        _ = NSApplication.shared
        let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let fixtures = FileManager.default.temporaryDirectory.appendingPathComponent("LumaViewVectorCompatibility-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: fixtures, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: fixtures) }
        let graphic = #"<svg xmlns="http://www.w3.org/2000/svg" width="100" height="50"><rect width="100" height="50" fill="rgb(255,0,0)"/></svg>"#
        let declaration = #"<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">"#
        let valid = [
            graphic,
            #"<?xml version="1.0" standalone="no"?>"# + declaration + graphic,
            declaration.replacingOccurrences(of: "\"", with: "'") + graphic,
            declaration.replacingOccurrences(of: "http://", with: "https://") + graphic,
            #"<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.0//EN" "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">"# + graphic,
            #"<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1 Basic//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11-basic.dtd">"# + graphic,
            #"<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1 Tiny//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11-tiny.dtd">"# + graphic
        ]
        for (index, text) in valid.enumerated() {
            let url = fixtures.appendingPathComponent("allowed-\(index).svg")
            try Data(text.utf8).write(to: url)
            let rendered = try VectorRenderer.render(url: url, maxPixelDimension: 200)
            let pixel = NSBitmapImageRep(cgImage: rendered.image).colorAt(x: 100, y: 50)?.usingColorSpace(.sRGB)
            try check(rendered.image.width == 200 && rendered.image.height == 100 && (pixel?.redComponent ?? 0) > 0.95 && (pixel?.greenComponent ?? 1) < 0.25,
                      "SVG declaration variant \(index) renders actual red vector content")
            let page = try DocumentMedia(url: url).page(at: 0)
            try check(page.isVector && page.rasterImage == nil && page.size == CGSize(width: 100, height: 50),
                      "SVG declaration variant \(index) retains original vector representation")
        }
        let denied = [
            declaration.replacingOccurrences(of: "www.w3.org", with: "attacker.invalid") + graphic,
            declaration.replacingOccurrences(of: "-//W3C//DTD SVG 1.1//EN", with: "custom") + graphic,
            #"<!DOCTYPE svg SYSTEM "file:///etc/passwd">"# + graphic,
            #"<!DOCTYPE svg [<!ENTITY value "unsafe">]>"# + graphic,
            #"<!DOCTYPE svg [<!ENTITY value SYSTEM "file:///etc/passwd">]>"# + graphic,
            declaration.replacingOccurrences(of: ">", with: " [ ]>") + graphic,
            declaration + declaration + graphic,
            #"<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd""# + graphic,
            declaration + graphic.replacingOccurrences(of: "</svg>", with: #"<script>alert(1)</script></svg>"#),
            declaration + graphic.replacingOccurrences(of: "</svg>", with: #"<image href="https://attacker.invalid/a.png"/></svg>"#),
            declaration + graphic.replacingOccurrences(of: "</svg>", with: #"<image href="file:///tmp/private.png"/></svg>"#),
            declaration + graphic.replacingOccurrences(of: "</svg>", with: #"<style><![CDATA[rect { fill: url(https://attacker.invalid/a.svg); }]]></style></svg>"#),
            declaration + graphic.replacingOccurrences(of: "<rect", with: #"<rect onload="alert(1)""#),
            declaration + graphic.replacingOccurrences(of: "</svg>", with: #"<foreignObject width="10" height="10"/></svg>"#)
        ]
        for (index, text) in denied.enumerated() {
            let url = fixtures.appendingPathComponent("denied-\(index).svg")
            try Data(text.utf8).write(to: url)
            do {
                _ = try VectorRenderer.validatedSVGImage(url: url)
                throw CompatibilityFailure(message: "unsafe SVG \(index) accepted")
            } catch VectorRenderError.unsafeSVG {
                try check(true, "SVG unsafe declaration or active/external resource \(index) is rejected")
            }
        }

        let tiff = try makeTIFF()
        let dos = makeEPS(tiff: tiff)
        guard let preview = EmbeddedEPSPreview.load(data: dos, maxPixelDimension: 64) else { throw CompatibilityFailure(message: "valid EPS preview missing") }
        try check(preview.size == CGSize(width: 120, height: 80) && preview.image.width == 64 && (42...43).contains(preview.image.height),
                  "DOS EPS preview reports native pixel size and bounded thumbnail")
        try check(EmbeddedEPSPreview.load(data: dos, maxPixelDimension: 4096)?.image.width == 120,
                  "embedded low-resolution bitmap is never spuriously upsampled")
        let previewColor = NSBitmapImageRep(cgImage: preview.image).colorAt(x: 32, y: 20)?.usingColorSpace(.sRGB)
        try check((previewColor?.blueComponent ?? 0) > 0.95 && (previewColor?.redComponent ?? 1) < 0.25,
                  "embedded TIFF decodes real pixel content")
        for little in [true, false] {
            for alpha in [1, 2] {
                let paletteData = try makePaletteTIFF(littleEndian: little, alpha: alpha)
                guard let palettePreview = EmbeddedEPSPreview.load(data: makeEPS(tiff: paletteData)) else {
                    throw CompatibilityFailure(message: "palette/alpha TIFF could not load")
                }
                let bitmap = NSBitmapImageRep(cgImage: palettePreview.image)
                let red = bitmap.colorAt(x: 0, y: 0)?.usingColorSpace(.sRGB)
                let green = bitmap.colorAt(x: 1, y: 0)?.usingColorSpace(.sRGB)
                let blue = bitmap.colorAt(x: 2, y: 0)?.usingColorSpace(.sRGB)
                try check(palettePreview.image.width == 4 && palettePreview.image.height == 2,
                          "palette+alpha TIFF \(little)/\(alpha) retains complete image dimensions")
                try check((red?.redComponent ?? 0) > 0.9 && (red?.greenComponent ?? 1) < 0.2 &&
                          (green?.greenComponent ?? 0) > 0.9 && (green?.blueComponent ?? 1) < 0.2 &&
                          (blue?.blueComponent ?? 0) > 0.9 && (blue?.redComponent ?? 1) < 0.2,
                          "palette+alpha TIFF \(little)/\(alpha) preserves RGB columns without interleaved stripe corruption")
                try check(abs((green?.alphaComponent ?? 0) - (alpha == 2 ? 128.0 / 255.0 : 1)) < 0.02,
                          "palette+alpha TIFF \(little)/\(alpha) preserves alpha semantics")
            }
        }
        for (index, corrupt) in [
            Data(dos.prefix(29)),
            replacing(dos, offset: 0, value: 0),
            replacing(dos, offset: 20, value: UInt32.max),
            replacing(dos, offset: 24, value: UInt32.max),
            replacing(dos, offset: 20, value: 10),
            replacing(dos, offset: 24, value: 0),
            replacing(dos, offset: 4, value: UInt32.max),
            replacing(dos, offset: 8, value: UInt32.max),
            replacing(dos, offset: 20, value: 30),
            replacing(dos, offset: 30, value: 0),
            makeEPS(tiff: Data("not a tiff".utf8))
        ].enumerated() {
            try check(EmbeddedEPSPreview.load(data: corrupt) == nil, "malformed EPS section \(index) fails safely")
        }
        let epsURL = fixtures.appendingPathComponent("embedded.eps")
        try dos.write(to: epsURL)
        let epsDocument = try DocumentMedia(url: epsURL)
        let epsPage = try epsDocument.page(at: 0)
        try check(!epsDocument.isVector && epsDocument.format.contains("TIFF") && epsPage.rasterImage != nil && epsPage.size == preview.size,
                  "EPS document exposes honest bitmap-preview format and source dimensions")
        let epsThumbnail = try VectorRenderer.render(url: epsURL, maxPixelDimension: 60)
        try check(epsThumbnail.image.width == 60 && epsThumbnail.format.contains("TIFF") && epsThumbnail.originalSize == preview.size,
                  "file filmstrip uses the same embedded EPS preview fallback")
        var asynchronous: Result<DocumentPage, Error>?
        epsDocument.loadPage(at: 0) { asynchronous = $0 }
        try wait { asynchronous != nil }
        try check(try asynchronous!.get().presentationPreview != nil, "EPS page publishes complete bitmap through normal asynchronous document path")
        var pageThumbnail: CGImage?
        epsDocument.thumbnail(at: 0, maxPixelDimension: 40) { pageThumbnail = $0 }
        try wait { pageThumbnail != nil }
        try check(pageThumbnail?.width == 40, "EPS page thumbnail uses bounded document pipeline")

        for path in CommandLine.arguments.dropFirst(2) {
            let url = URL(fileURLWithPath: path)
            let before = SHA256.hash(data: try Data(contentsOf: url))
            let document = try DocumentMedia(url: url)
            let page = try document.page(at: 0)
            let rendered = try page.preview(maxPixelDimension: 1200)
            try png(rendered, to: output.appendingPathComponent(url.deletingPathExtension().lastPathComponent + "-preview.png"))
            let thumbnail = try VectorRenderer.render(url: url, maxPixelDimension: 160)
            try check(max(thumbnail.image.width, thumbnail.image.height) <= 160, "attached \(url.lastPathComponent) file thumbnail renders")
            try check(document.isVector, "attached \(url.lastPathComponent) retains original vector content")
            try check(before == SHA256.hash(data: try Data(contentsOf: url)), "attached \(url.lastPathComponent) remains byte-for-byte unchanged")
            print("INFO \(url.lastPathComponent): \(document.format), \(Int(page.size.width)) × \(Int(page.size.height)), native PDF=\(CGPDFDocument(url as CFURL) != nil), native NSImage=\(NSImage(contentsOf: url) != nil)")
        }
        print("PASS: \(checks) vector compatibility checks")
    }

    private static func check(_ condition: Bool, _ message: String) throws {
        guard condition else { throw CompatibilityFailure(message: message) }
        checks += 1
        print("PASS \(message)")
    }

    private static func makeTIFF() throws -> Data {
        guard let context = CGContext(data: nil, width: 120, height: 80, bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw CompatibilityFailure(message: "fixture context unavailable")
        }
        context.setFillColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 120, height: 80))
        let data = NSMutableData()
        guard let image = context.makeImage(), let destination = CGImageDestinationCreateWithData(data, "public.tiff" as CFString, 1, nil) else {
            throw CompatibilityFailure(message: "TIFF fixture unavailable")
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw CompatibilityFailure(message: "TIFF fixture finalize failed") }
        return data as Data
    }

    private static func makeEPS(tiff: Data) -> Data {
        let ps = Data("%!PS-Adobe-3.0 EPSF-3.0\n%%BoundingBox: 0 0 120 80\nLumaViewInvalidPostScriptOperator\n%%EOF\n".utf8)
        var header = Data(repeating: 0, count: 30)
        header.replaceSubrange(0..<4, with: [0xC5, 0xD0, 0xD3, 0xC6])
        header = replacing(header, offset: 4, value: 30)
        header = replacing(header, offset: 8, value: UInt32(ps.count))
        header = replacing(header, offset: 20, value: UInt32(30 + ps.count))
        header = replacing(header, offset: 24, value: UInt32(tiff.count))
        header[28] = 0xFF; header[29] = 0xFF
        return header + ps + tiff
    }

    private static func makePaletteTIFF(littleEndian little: Bool, alpha: Int) throws -> Data {
        func number(_ value: Int, _ width: Int) -> Data {
            Data((0..<width).map { UInt8((value >> ((little ? $0 : width - 1 - $0) * 8)) & 0xFF) })
        }
        let tags = 13, ifd = 8, payload = ifd + 2 + tags * 12 + 4
        let paletteStart = payload + 16, offsetsStart = paletteStart + 1536, countsStart = offsetsStart + 8
        var bytes = Data(little ? [0x49, 0x49, 42, 0] : [0x4D, 0x4D, 0, 42]) + number(ifd, 4) + number(tags, 2)
        for (tag, type, count, value) in [
            (256, 3, 1, 4), (257, 3, 1, 2), (258, 3, 1, 8), (259, 3, 1, 1),
            (262, 3, 1, 3), (273, 4, 2, offsetsStart), (274, 3, 1, 1), (277, 3, 1, 2),
            (278, 4, 1, 1), (279, 4, 2, countsStart), (284, 3, 1, 1), (320, 3, 768, paletteStart), (338, 3, 1, alpha)
        ] {
            bytes += number(tag, 2) + number(type, 2) + number(count, 4)
            bytes += type == 3 && count == 1 ? number(value, 2) + Data([0, 0]) : number(value, 4)
        }
        bytes += number(0, 4)
        let row: [UInt8] = [1, 255, 2, alpha == 2 ? 128 : 255, 3, 255, 4, 255]
        bytes += Data(row + row)
        for component in 0..<3 {
            for index in 0..<256 { bytes += number(index == component + 1 || index == 4 ? 65535 : 0, 2) }
        }
        bytes += number(payload, 4) + number(payload + 8, 4) + number(8, 4) + number(8, 4)
        return bytes
    }

    private static func replacing(_ data: Data, offset: Int, value: UInt32) -> Data {
        var copy = data
        copy.replaceSubrange(offset..<(offset + 4), with: (0..<4).map { UInt8((value >> ($0 * 8)) & 0xFF) })
        return copy
    }

    private static func png(_ image: CGImage, to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
            throw CompatibilityFailure(message: "PNG destination unavailable")
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw CompatibilityFailure(message: "PNG write failed") }
    }

    private static func wait(_ condition: () -> Bool) throws {
        let deadline = Date().addingTimeInterval(10)
        while !condition(), Date() < deadline { RunLoop.current.run(until: Date().addingTimeInterval(0.01)) }
        if !condition() { throw CompatibilityFailure(message: "async preview timed out") }
    }
}
