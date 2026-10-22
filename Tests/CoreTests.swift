import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

private struct TestFailure: Error, CustomStringConvertible {
    let description: String
}

@main
struct CoreTests {
    private static var checks = 0

    static func main() {
        do { try run() }
        catch {
            FileHandle.standardError.write(Data("FAIL: \(error)\n".utf8))
            exit(1)
        }
    }

    private static func run() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("LumaViewCoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let red = try makeImage(width: 40, height: 20, color: CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        let green = try makeImage(width: 40, height: 20, color: CGColor(red: 0, green: 1, blue: 0, alpha: 1))
        let two = root.appendingPathComponent("photo2.png")
        let ten = root.appendingPathComponent("photo10.png")
        let one = root.appendingPathComponent("photo1.jpg")
        try writeImage(red, to: two, type: UTType.png.identifier)
        try writeImage(red, to: ten, type: UTType.png.identifier)
        try writeImage(red, to: one, type: UTType.jpeg.identifier)
        try Data("not an image".utf8).write(to: root.appendingPathComponent("notes.txt"))
        try writeImage(red, to: root.appendingPathComponent(".hidden.png"), type: UTType.png.identifier)
        let subfolder = root.appendingPathComponent("nested", isDirectory: true)
        try FileManager.default.createDirectory(at: subfolder, withIntermediateDirectories: true)
        try writeImage(red, to: subfolder.appendingPathComponent("nested.png"), type: UTType.png.identifier)

        let folder = try ImageLibrary.collect(from: [root])
        try check(folder.items.map(\.name) == ["photo1.jpg", "photo2.png", "photo10.png"], "natural sort, hidden/non-image exclusion and no recursion")
        try check(folder.selectedIndex == 0, "folder initially selects first image")
        let single = try ImageLibrary.collect(from: [ten])
        try check(single.items.count == 3 && single.selectedIndex == 2, "single image expands siblings and preserves selected image")
        let multiple = try ImageLibrary.collect(from: [ten, two, ten])
        try check(multiple.items.map(\.name) == ["photo2.png", "photo10.png"] && multiple.selectedIndex == 1, "explicit images deduplicated and first selected image retained")
        let mixed = try ImageLibrary.collect(from: [root.appendingPathComponent("notes.txt"), two, ten])
        try check(mixed.items.count == 2 && mixed.selectedIndex == 0, "mixed unsupported files ignored")
        let link = root.appendingPathComponent("alias.png")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: two)
        let aliased = try ImageLibrary.collect(from: [two, link])
        try check(aliased.items.count == 1, "symlink aliases deduplicated")
        try FileManager.default.removeItem(at: link)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 100)], ofItemAtPath: one.path)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 200)], ofItemAtPath: two.path)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 300)], ofItemAtPath: ten.path)
        let modified = try ImageLibrary.collect(from: [root], sort: .modified)
        try check(modified.items.map(\.name) == ["photo10.png", "photo2.png", "photo1.jpg"], "modified sort newest first")
        let empty = root.appendingPathComponent("empty", isDirectory: true)
        try FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)
        do {
            _ = try ImageLibrary.collect(from: [empty])
            throw TestFailure(description: "empty directory should report no images")
        } catch ImageLoadError.noImages { checks += 1 }

        let loader = ImageLoader()
        let plain = try load(two, using: loader)
        try check(plain.pixelSize == CGSize(width: 40, height: 20), "full original pixel dimensions retained")
        try check(plain.frameCount == 1 && plain.frame(at: 1) == nil, "still image has one frame")
        try check(!plain.metadata.isEmpty, "metadata is populated")
        let orientationURL = root.appendingPathComponent("orientation.jpg")
        try writeImage(red, to: orientationURL, type: UTType.jpeg.identifier, properties: [kCGImagePropertyOrientation: 6])
        let oriented = try load(orientationURL, using: loader)
        try check(oriented.image.width == 20 && oriented.image.height == 40, "EXIF orientation 6 rotates pixels into display orientation")

        // Exercise actual system encoders and decoders, rather than accepting
        // extensions alone as evidence of format support.
        let destinations = Set(CGImageDestinationCopyTypeIdentifiers() as! [String])
        for (extensionName, type) in [("heic", "public.heic"), ("tiff", "public.tiff"), ("bmp", "com.microsoft.bmp")] {
            guard destinations.contains(type) else {
                print("SKIP: \(extensionName) encoder unavailable on this macOS installation")
                continue
            }
            let url = root.appendingPathComponent("native-format.\(extensionName)")
            do { try writeImage(red, to: url, type: type) }
            catch {
                // Some virtualized/sandboxed Macs advertise HEIC encoding but
                // cannot access the required IOSurface encoder service.
                guard extensionName == "heic" else { throw error }
                let systemDirectory = URL(fileURLWithPath: "/System/Library/Desktop Pictures", isDirectory: true)
                let systemSamples = (try? FileManager.default.contentsOfDirectory(at: systemDirectory, includingPropertiesForKeys: nil)) ?? []
                guard let sample = systemSamples.sorted(by: { $0.path < $1.path }).first(where: { $0.pathExtension.lowercased() == "heic" }),
                      let source = CGImageSourceCreateWithURL(sample as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary),
                      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
                      let width = properties[kCGImagePropertyPixelWidth as String] as? Int,
                      let height = properties[kCGImagePropertyPixelHeight as String] as? Int else {
                    print("SKIP: HEIC encoder unavailable and no native system HEIC fixture present")
                    continue
                }
                let decoded = try load(sample, using: loader)
                try check(ImageLibrary.isSupported(sample), "HEIC system fixture is recognized")
                try check(decoded.pixelSize == CGSize(width: width, height: height)
                          && decoded.image.width <= width && decoded.image.height <= height, "native HEIC fixture retains original dimensions with a bounded preview")
                print("PASS: native HEIC decode of \(width)×\(height) system fixture (encoder unavailable)")
                continue
            }
            try check(ImageLibrary.isSupported(url), "\(extensionName) recognized as a system image format")
            let decoded = try load(url, using: loader)
            try check(decoded.image.width == 40 && decoded.image.height == 20, "\(extensionName) native full-resolution round trip")
            let pixel = try sample(decoded.image)
            try check(pixel[0] > 200 && pixel[1] < 50, "\(extensionName) decoded color content")
            print("PASS: native \(extensionName.uppercased()) encode/decode")
        }

        let gifURL = root.appendingPathComponent("animated.gif")
        guard let gif = CGImageDestinationCreateWithURL(gifURL as CFURL, UTType.gif.identifier as CFString, 2, nil) else { throw TestFailure(description: "create GIF") }
        CGImageDestinationSetProperties(gif, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
        CGImageDestinationAddImage(gif, red, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 0.12]] as CFDictionary)
        CGImageDestinationAddImage(gif, green, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 0.25]] as CFDictionary)
        try check(CGImageDestinationFinalize(gif), "GIF fixture written")
        let animated = try load(gifURL, using: loader)
        try check(animated.frameCount == 2, "animated GIF frame count")
        try check(abs(animated.frameDuration(at: 0) - 0.12) < 0.001 && abs(animated.frameDuration(at: 1) - 0.25) < 0.001, "GIF individual frame timings")
        let secondFrame = animated.frame(at: 1)
        try check(secondFrame != nil, "animated frame decoded on demand")
        if let secondFrame = secondFrame {
            let pixel = try sample(secondFrame)
            try check(pixel[1] > 200 && pixel[0] < 50, "second GIF frame is green, not the initial red frame")
        }
        try check(animated.frame(at: 1) === secondFrame, "decoded animation frame cache reused")
        // This optimized GIF stores a 10x10 patch at (7,3) and then a
        // 23x17 patch. ImageIO must composite them into the 40x20 canvas.
        let optimizedGIF = Data(base64Encoded: "R0lGODlhKAAUAIEAAP8AAAAAAAAAAAAAACH/C05FVFNDQVBFMi4wAwEAAAAh+QQEDAAAACwAAAAAKAAUAAAIMAABCBxIsKDBgwgTKlzIsKHDhxAjSpxIsaLFixgzatzIsaPHjyBDihxJsqTJkxQDAgAh+QQFGQACACwHAAMACgAKAIH/AAAAgAAAAAAAAAAIEgADCBxIsKDBgwgTKlzIsGHCgAAh+QQFHgACACwHAAMAFwARAIH/AAAAAP8AAAAAAAAITgABCBxIUIDBgwgPElwIIKFDgwwLPkwYceBEihUbXlSYcSPHih4hdjQYoKTJkxk1CjjJMkDKgy1PhlwZs+TMmjZD4gxwE2fPmj9jBm0ZEAA7")!
        let partialURL = root.appendingPathComponent("optimized-patches.gif")
        try optimizedGIF.write(to: partialURL)
        let partial = try load(partialURL, using: loader)
        guard let partialFrame = partial.frame(at: 1), let lastFrame = partial.frame(at: 2) else { throw TestFailure(description: "partial GIF frames decode") }
        try check(partialFrame.width == 40 && partialFrame.height == 20 && lastFrame.width == 40 && lastFrame.height == 20, "optimized GIF frames retain full logical canvas")
        let retained = try sample(partialFrame, x: 0, y: 0)
        let greenPatch = try sample(partialFrame, x: 10, y: 8)
        let restored = try sample(lastFrame, x: 10, y: 8)
        let bluePatch = try sample(lastFrame, x: 25, y: 15)
        try check(retained[0] == 255 && retained[3] == 255 && greenPatch[1] >= 120 && greenPatch[0] < 10, "optimized GIF composes a partial green patch over opaque red")
        try check(restored[0] == 255 && restored[1] < 10 && bluePatch[2] == 255, "optimized GIF later frame restores old patch and composites new one")
        var malformedGIF = optimizedGIF
        malformedGIF.replaceSubrange(6..<10, with: [UInt8](repeating: 255, count: 4))
        malformedGIF.removeSubrange(13..<malformedGIF.count) // Huge declared canvas with no image data.
        let hugeURL = root.appendingPathComponent("malformed-huge-canvas.gif")
        try malformedGIF.write(to: hugeURL)
        do {
            _ = try load(hugeURL, using: loader)
            throw TestFailure(description: "malformed 65535x65535 GIF must not be decoded")
        } catch ImageLoadError.invalidImage { checks += 1 }
          catch ImageLoadError.decodeFailed { checks += 1 }
        try check(partial.frame(at: -1) == nil && partial.frame(at: Int.max) == nil, "out-of-range animation frames are rejected")
        try check(partial.frameDuration(at: -1) == 0.1 && partial.frameDuration(at: Int.max) == 0.1, "out-of-range timing uses safe default")
        let invalid = root.appendingPathComponent("broken.png")
        try Data("this is not a png".utf8).write(to: invalid)
        do {
            _ = try load(invalid, using: loader)
            throw TestFailure(description: "invalid image should fail")
        } catch ImageLoadError.invalidImage { checks += 1 }
        var thumbFinished = false
        var thumb: NSImage?
        loader.thumbnail(orientationURL) { image in thumb = image; thumbFinished = true }
        try pump(until: { thumbFinished })
        try check(thumb != nil && thumb!.size.height > thumb!.size.width, "thumbnail respects EXIF orientation")
        var staleCalled = false
        loader.load(two) { _ in staleCalled = true }
        loader.cancelPending()
        _ = try load(ten, using: loader)
        try check(!staleCalled, "cancelPending suppresses stale main-queue callback")
        loader.prefetch([one, two])
        loader.cancelPending()
        try largeRasterPreview(in: root, loader: loader)
        try vectorPreviews(in: root, loader: loader, embeddedPNG: two)
        try expandedMediaDiscovery(in: root, loader: loader)
        print("PASS: \(checks) image library / loading checks")
    }

    private static func largeRasterPreview(in root: URL, loader: ImageLoader) throws {
        let url = root.appendingPathComponent("160-megapixel-oriented.tiff")
        let width = 16_000, height = 10_000, byteCount = width / 8 * height
        // A valid one-bit TIFF is only 20 MB on disk and needs no 640 MB fixture
        // canvas. Its 160 MP logical image exceeds the former rejection limit.
        let tags: [(UInt16, UInt16, UInt32)] = [
            (256, 4, UInt32(width)), (257, 4, UInt32(height)), (258, 3, 1), (259, 3, 1), (262, 3, 1),
            (273, 4, 134), (274, 3, 6), (277, 3, 1), (278, 4, UInt32(height)), (279, 4, UInt32(byteCount))
        ]
        var data = Data([0x49, 0x49, 42, 0, 8, 0, 0, 0])
        func word(_ value: UInt16) { var value = value.littleEndian; withUnsafeBytes(of: &value) { data.append(contentsOf: $0) } }
        func dword(_ value: UInt32) { var value = value.littleEndian; withUnsafeBytes(of: &value) { data.append(contentsOf: $0) } }
        word(UInt16(tags.count))
        for (tag, type, value) in tags { word(tag); word(type); dword(1); dword(value) }
        dword(0)
        data.append(Data(repeating: 0, count: byteCount))
        try data.write(to: url)
        let loaded = try load(url, using: loader)
        try check(loaded.pixelSize == CGSize(width: height, height: width), "160 MP source is accepted and original dimensions follow TIFF orientation")
        try check(loaded.isDownsampledPreview && !loaded.isVectorPreview, "large raster explicitly reports a downsampled preview")
        try check(loaded.image.width * loaded.image.height <= 32_000_000 && max(loaded.image.width, loaded.image.height) <= 8192,
                  "large raster preview is bounded by working pixel count and longest side")
        try check(loaded.previewPixelSize == CGSize(width: loaded.image.width, height: loaded.image.height)
                  && loaded.image.height > loaded.image.width, "preview dimensions and oriented aspect agree")
        try check(loaded.metadata.contains { $0.0 == "大图预览" } && loaded.metadata.contains { $0.0 == "尺寸" && $0.1.contains("16000") },
                  "large raster metadata distinguishes original dimensions from preview detail")
    }

    private static func vectorPreviews(in root: URL, loader: ImageLoader, embeddedPNG: URL) throws {
        let svgURL = root.appendingPathComponent("sample.svg")
        let svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"200\" height=\"100\" viewBox=\"0 0 200 100\"><rect width=\"100\" height=\"100\" fill=\"red\"/><rect x=\"100\" width=\"100\" height=\"100\" fill=\"lime\"/></svg>"
        try Data(svg.utf8).write(to: svgURL)
        let original = try Data(contentsOf: svgURL)
        let svgLoaded = try load(svgURL, using: loader)
        try check(ImageLibrary.isSupported(svgURL) && ImageItem(url: svgURL).isVector, "SVG is discovered as a vector document")
        try check(svgLoaded.isVectorPreview && !svgLoaded.isDownsampledPreview && svgLoaded.frameCount == 1,
                  "SVG has a single explicitly identified vector preview")
        try check(svgLoaded.image.width == 4096 && svgLoaded.image.height == 2048, "SVG renders at a clear 4096-pixel preview rather than its tiny intrinsic canvas")
        let svgLeft = try sample(svgLoaded.image, x: 512, y: 512), svgRight = try sample(svgLoaded.image, x: 3584, y: 512)
        try check(svgLeft[0] > 230 && svgLeft[1] < 20 && svgRight[1] > 230 && svgRight[0] < 20,
                  "native SVG rendering preserves asymmetric colored content")
        let unchangedSVG = try Data(contentsOf: svgURL)
        try check(unchangedSVG == original, "SVG preview leaves source bytes unchanged")
        let thumbnail = try VectorRenderer.render(url: svgURL, maxPixelDimension: 256)
        try check(thumbnail.image.width == 256 && thumbnail.image.height == 128, "vector renderer supports bounded thumbnail sizes")

        let embeddedURL = root.appendingPathComponent("embedded.svg")
        let payload = try Data(contentsOf: embeddedPNG).base64EncodedString()
        try Data("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"40\" height=\"20\"><image width=\"40\" height=\"20\" href=\"data:image/png;base64,\(payload)\"/></svg>".utf8).write(to: embeddedURL)
        let embedded = try VectorRenderer.render(url: embeddedURL, maxPixelDimension: 128)
        let embeddedColor = try sample(embedded.image)
        try check(embeddedColor[0] > 200 && embeddedColor[1] < 50, "offline SVG permits real embedded raster data")
        let gradientURL = root.appendingPathComponent("gradient.svg")
        try Data("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"100\" height=\"100\"><defs><linearGradient id=\"g\"><stop offset=\"0\" stop-color=\"red\"/><stop offset=\"1\" stop-color=\"blue\"/></linearGradient></defs><rect width=\"100\" height=\"100\" fill=\"url(#g)\"/></svg>".utf8).write(to: gradientURL)
        let gradient = try VectorRenderer.render(url: gradientURL, maxPixelDimension: 64)
        try check(gradient.image.width == 64, "offline SVG permits internal gradient references")
        let blockedSources = [
            "<svg xmlns=\"http://www.w3.org/2000/svg\"><image href=\"https://example.invalid/track.png\"/></svg>",
            "<svg xmlns=\"http://www.w3.org/2000/svg\"><image href=\"file:///etc/passwd\"/></svg>",
            "<svg xmlns=\"http://www.w3.org/2000/svg\"><script>alert(1)</script></svg>",
            "<!DOCTYPE svg [<!ENTITY secret SYSTEM 'file:///etc/passwd'>]><svg xmlns=\"http://www.w3.org/2000/svg\">&secret;</svg>",
            "<svg xmlns=\"http://www.w3.org/2000/svg\"><style>@import url(https://example.invalid/theme.css);</style></svg>"
        ]
        for (index, source) in blockedSources.enumerated() {
            let url = root.appendingPathComponent("blocked-\(index).svg")
            try Data(source.utf8).write(to: url)
            do { _ = try VectorRenderer.render(url: url); throw TestFailure(description: "unsafe SVG source must be refused offline") }
            catch VectorRenderError.unsafeSVG { checks += 1 }
        }

        let pdfURL = root.appendingPathComponent("vector.pdf")
        var box = CGRect(x: 0, y: 0, width: 200, height: 100)
        guard let consumer = CGDataConsumer(url: pdfURL as CFURL), let context = CGContext(consumer: consumer, mediaBox: &box, nil) else {
            throw TestFailure(description: "PDF fixture context")
        }
        for color in [CGColor(red: 0, green: 0, blue: 1, alpha: 1), CGColor(red: 1, green: 0, blue: 0, alpha: 1)] {
            context.beginPDFPage(nil); context.setFillColor(color); context.fill(box); context.endPDFPage()
        }
        context.closePDF()
        let pdf = try load(pdfURL, using: loader)
        try check(pdf.isVectorPreview && pdf.frameCount == 1 && pdf.metadata.contains { $0.0 == "页面" && $0.1.contains("2") },
                  "multipage PDF previews the first page with a visible page count")
        let pdfPixel = try sample(pdf.image)
        try check(pdfPixel[2] > 230 && pdfPixel[0] < 20, "PDF first-page vector content is actually rendered")
        let aiURL = root.appendingPathComponent("compatible.ai")
        try FileManager.default.copyItem(at: pdfURL, to: aiURL)
        let ai = try load(aiURL, using: loader)
        let aiPixel = try sample(ai.image)
        try check(ai.isVectorPreview && aiPixel[2] > 230 && ai.metadata.contains { $0.1.contains("PDF 兼容") },
                  "PDF-compatible Illustrator files render without changing their extension")
    }

    private static func expandedMediaDiscovery(in root: URL, loader: ImageLoader) throws {
        for name in ["clip.mkv", "song.flac", "art.svg", "design.ai", "document.pdf"] {
            let item = ImageItem(url: root.appendingPathComponent(name))
            try check(ImageLibrary.isSupported(item.url), "shared media catalog discovers \(name)")
        }
        let audioURL = root.appendingPathComponent("song.flac")
        let audio = ImageItem(url: audioURL), video = ImageItem(url: root.appendingPathComponent("clip.mkv"))
        try check(audio.isAudio && audio.isTimeBased && !audio.isVideo && video.isVideo && video.isTimeBased,
                  "image items distinguish audio, video and time-based media")
        var completed = false
        var icon: NSImage?
        loader.thumbnail(audioURL) { icon = $0; completed = true }
        try pump(until: { completed })
        try check(icon != nil, "audio receives a local artwork icon without invoking an image decoder")
    }

    private static func check(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        guard condition() else { throw TestFailure(description: message) }
        checks += 1
    }

    private static func pump(until completed: () -> Bool) throws {
        let deadline = Date().addingTimeInterval(15)
        while !completed() && Date() < deadline {
            _ = RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.01))
        }
        guard completed() else { throw TestFailure(description: "timed out waiting for main-queue image completion") }
    }

    private static func load(_ url: URL, using loader: ImageLoader) throws -> LoadedImage {
        var result: Result<LoadedImage, Error>?
        var onMain = false
        loader.load(url) { value in result = value; onMain = Thread.isMainThread }
        try pump(until: { result != nil })
        try check(onMain, "load completion delivered on main thread")
        return try result!.get()
    }

    private static func makeImage(width: Int, height: Int, color: CGColor) throws -> CGImage {
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { throw TestFailure(description: "fixture context") }
        context.setFillColor(color)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        guard let image = context.makeImage() else { throw TestFailure(description: "fixture image") }
        return image
    }

    private static func writeImage(_ image: CGImage, to url: URL, type: String, properties: [CFString: Any] = [:]) throws {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, type as CFString, 1, nil) else { throw TestFailure(description: "fixture destination") }
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw TestFailure(description: "fixture write") }
    }

    private static func sample(_ image: CGImage) throws -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: 4)
        try bytes.withUnsafeMutableBytes { pointer in
            guard let context = CGContext(data: pointer.baseAddress, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { throw TestFailure(description: "sample context") }
            context.draw(image, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        return bytes
    }

    private static func sample(_ image: CGImage, x: Int, y: Int) throws -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        try bytes.withUnsafeMutableBytes { pointer in
            guard let context = CGContext(data: pointer.baseAddress, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { throw TestFailure(description: "pixel sample context") }
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        }
        let offset = (y * image.width + x) * 4
        return Array(bytes[offset..<(offset + 4)])
    }
}
