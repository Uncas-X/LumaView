import AppKit
import Foundation
import ImageIO

private struct PerformanceFailure: Error { let message: String }
@main struct PhotoshopPerformanceTests {
    static var checks = 0
    static func check(_ value: @autoclosure () -> Bool, _ message: String) throws {
        guard value() else { throw PerformanceFailure(message: message) }
        checks += 1
    }
    static func pixels(_ image: CGImage) throws -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        try bytes.withUnsafeMutableBytes { pointer in
            guard let context = CGContext(data: pointer.baseAddress, width: image.width, height: image.height,
                                          bitsPerComponent: 8, bytesPerRow: image.width * 4,
                                          space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else { throw PerformanceFailure(message: "bitmap") }
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        }
        return bytes
    }
    static func main() {
        do { try run() } catch { fputs("FAIL: \(error)\n", stderr); exit(1) }
    }
    static func run() throws {
        let root = URL(fileURLWithPath: CommandLine.arguments[1])
        func url(_ name: String) -> URL { root.appendingPathComponent(name) }
        let raw = try pixels(PhotoshopImage.render(url: url("literal-raw.psb")).image)
        var elapsed: [String: Double] = [:]
        for name in ["literal-128.psb", "literal-1.psb"] {
            let start = ProcessInfo.processInfo.systemUptime
            let preview = try PhotoshopImage.render(url: url(name))
            elapsed[name] = ProcessInfo.processInfo.systemUptime - start
            try check(preview.image.width == 1024 && preview.image.height == 384, "literal dimensions \(name)")
            let actual = try pixels(preview.image)
            try check(actual == raw, "small/large literal runs equal raw composite \(name)")
        }
        // One-byte literal runs used to cause millions of FileHandle syscalls.
        // A generous floor avoids unstable timing failures on a fast machine.
        let one = elapsed["literal-1.psb"]!, block = elapsed["literal-128.psb"]!
        try check(one < max(2.0, block * 12), "PackBits marker density cannot trigger syscall scaling")
        print(String(format: "TIMING: literal 1-byte %.4fs, 128-byte %.4fs", one, block))
        for name in ["boundary-literal.psb", "boundary-run.psb", "boundary-payload.psb"] {
            let preview = try PhotoshopImage.render(url: url(name))
            let actual = try pixels(preview.image)
            try check(preview.image.width == 130 && preview.image.height == 1, "64 KiB boundary dimensions \(name)")
            try check(stride(from: 0, to: actual.count, by: 4).allSatisfy {
                zip(actual[$0..<($0+4)], [201,43,91,255]).allSatisfy { abs(Int($0)-$1) <= 1 }
            }, "64 KiB boundary samples and trailing no-ops \(name)")
        }
        let start = ProcessInfo.processInfo.systemUptime
        let embedded = try PhotoshopImage.thumbnail(url: url("embedded.psb"), maxPixelDimension: 256)
        let thumbElapsed = ProcessInfo.processInfo.systemUptime - start
        let thumbPixels = try pixels(embedded.image)
        try check(embedded.image.width == 64 && embedded.image.height == 48, "embedded JPEG used at native dimensions")
        try check(thumbPixels[1] > 200 && thumbPixels[0] < 40 && thumbPixels[2] < 60, "embedded thumbnail has its own known green pixels")
        try check(thumbElapsed < 2.0, "embedded thumbnail avoids decoding slow composite")
        try check(embedded.header.width == 128 && embedded.header.height == 96, "thumbnail preserves original document dimensions")
        print(String(format: "TIMING: embedded thumbnail %.4fs", thumbElapsed))
        let composite = try PhotoshopImage.render(url: url("composite.psb"))
        let compositePixels = try pixels(composite.image)
        let embeddedMain = try PhotoshopImage.render(url: url("embedded.psb"))
        let embeddedMainPixels = try pixels(embeddedMain.image)
        try check(embeddedMainPixels == compositePixels, "main image always uses full-quality composite instead of saved thumbnail")
        for name in ["bad-jpeg.psb", "wrong-dimensions.psb", "wrong-depth.psb", "wrong-format.psb", "legacy-thumbnail.psb"] {
            let fallback = try PhotoshopImage.thumbnail(url: url(name), maxPixelDimension: 256)
            let fallbackPixels = try pixels(fallback.image)
            try check(fallbackPixels == compositePixels, "bad/unsupported embedded resource falls back to composite \(name)")
        }
        for name in ["portrait-alpha-a.psb", "portrait-alpha-b.psb"] {
            let file = url(name)
            let header = try PhotoshopImage.inspect(url: file)
            for dimension in [1, 255, 256, 512] {
                let preview = try PhotoshopImage.thumbnail(url: file, maxPixelDimension: dimension)
                let expectedWidth = max(1, Int(Double(header.width) * Double(dimension) / Double(header.height)))
                try check(abs(preview.image.width - expectedWidth) <= 1 && abs(preview.image.height - dimension) <= 1,
                          "portrait alpha downsample dimensions \(name) \(dimension): actual \(preview.image.width) × \(preview.image.height), expected \(expectedWidth) × \(dimension)")
                let actual = try pixels(preview.image)
                try check(stride(from: 0, to: actual.count, by: 4).allSatisfy {
                    zip(actual[$0..<($0+4)], [64,16,32,64]).allSatisfy { abs(Int($0)-$1) <= 1 }
                }, "portrait alpha and image sizes agree \(name) \(dimension)")
            }
        }
        let profile = try Data(contentsOf: url("GenericRGB.icc"))
        guard let expectedSpace = CGColorSpace(iccData: profile as CFData) else {
            throw PerformanceFailure(message: "system Generic RGB profile unavailable")
        }
        for baseName in ["portrait-alpha-a.psb", "portrait-alpha-b.psb"] {
            let profiled = try PhotoshopImage.thumbnail(url: url("icc-" + baseName), maxPixelDimension: 256)
            let baseline = try PhotoshopImage.thumbnail(url: url(baseName), maxPixelDimension: 256)
            guard let expectedImage = baseline.image.copy(colorSpace: expectedSpace) else {
                throw PerformanceFailure(message: "reference profile assignment failed")
            }
            try check(profiled.image.width == baseline.image.width && profiled.image.height == baseline.image.height,
                      "embedded ICC cannot make portrait thumbnail disappear \(baseName)")
            try check(profiled.image.colorSpace.map { CFEqual($0, expectedSpace) } == true,
                      "fallback retains original RGB profile \(baseName)")
            let actual = try pixels(profiled.image), expected = try pixels(expectedImage)
            try check(zip(actual, expected).allSatisfy { abs(Int($0)-Int($1)) <= 1 },
                      "profiled thumbnail preserves known RGB colors and transparency \(baseName)")
        }
        let invalidNative = CGImageSourceCreateWithURL(url("invalid-icc-native.psd") as CFURL, nil)
            .flatMap { CGImageSourceCreateThumbnailAtIndex($0, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: 256,
                kCGImageSourceShouldCacheImmediately: true
            ] as CFDictionary) }
        do {
            _ = try PhotoshopImage.thumbnail(url: url("invalid-icc.psb"), maxPixelDimension: 256)
            try check(invalidNative != nil, "invalid ICC must not be silently removed when native decode failed")
        } catch is PhotoshopImage.Failure {
            try check(invalidNative == nil, "invalid ICC failure is restricted to failing native decode")
        }
        for name in ["literal-truncated.psb", "run-truncated.psb", "run-overflow.psb", "run-underflow.psb", "nop-empty.psb", "extra-output.psb", "file-truncated.psb"] {
            do {
                _ = try PhotoshopImage.render(url: url(name))
                throw PerformanceFailure(message: "accepted invalid PackBits \(name)")
            } catch is PhotoshopImage.Failure { checks += 1 }
        }
        var cancellationChecks = 0
        let cancelStart = ProcessInfo.processInfo.systemUptime
        do {
            _ = try PhotoshopImage.render(url: url("cancel-noop.psb"), isCancelled: {
                cancellationChecks += 1
                return cancellationChecks >= 6
            })
            throw PerformanceFailure(message: "long no-op row ignored cancellation")
        } catch PhotoshopImage.Failure.cancelled {
            try check(cancellationChecks == 6, "cancellation checked inside buffered no-op row")
            try check(ProcessInfo.processInfo.systemUptime - cancelStart < 1.0, "no-op row cancellation is prompt")
        }
        do {
            _ = try PhotoshopImage.thumbnail(url: url("embedded.psb"), isCancelled: { true })
            throw PerformanceFailure(message: "embedded thumbnail ignored cancellation")
        } catch PhotoshopImage.Failure.cancelled { checks += 1 }
        for path in CommandLine.arguments.dropFirst(2) {
            let file = URL(fileURLWithPath: path)
            let before = try FileManager.default.attributesOfItem(atPath: path)
            let inspectedAt = ProcessInfo.processInfo.systemUptime
            let header = try PhotoshopImage.inspect(url: file)
            let inspected = ProcessInfo.processInfo.systemUptime - inspectedAt
            let thumbnailAt = ProcessInfo.processInfo.systemUptime
            let thumbnail = try PhotoshopImage.thumbnail(url: file)
            let thumbnailElapsed = ProcessInfo.processInfo.systemUptime - thumbnailAt
            let renderAt = ProcessInfo.processInfo.systemUptime
            let preview = try PhotoshopImage.render(url: file)
            let renderElapsed = ProcessInfo.processInfo.systemUptime - renderAt
            let after = try FileManager.default.attributesOfItem(atPath: path)
            try check(before[.size] as? NSNumber == after[.size] as? NSNumber && before[.modificationDate] as? Date == after[.modificationDate] as? Date, "original remains unchanged \(file.lastPathComponent)")
            let report: [String: Any] = ["file": file.lastPathComponent, "width": header.width, "height": header.height,
                "inspect_seconds": inspected, "thumbnail_seconds": thumbnailElapsed, "render_seconds": renderElapsed,
                "thumbnail_width": thumbnail.image.width, "thumbnail_height": thumbnail.image.height,
                "preview_width": preview.image.width, "preview_height": preview.image.height]
            let data = try JSONSerialization.data(withJSONObject: report, options: [.sortedKeys])
            print("BENCHMARK: " + String(decoding: data, as: UTF8.self))
        }
        print("PASS: \(checks) Photoshop performance and embedded-thumbnail checks")
    }
}
