import AppKit
import Foundation
import ImageIO

private struct CheckFailure: Error { let message: String }
@main struct PhotoshopImageTests {
    static var checks = 0
    static func check(_ value: @autoclosure () -> Bool, _ message: String) throws {
        guard value() else { throw CheckFailure(message: message) }
        checks += 1
    }
    static func pixels(_ image: CGImage) throws -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        try bytes.withUnsafeMutableBytes { pointer in
            guard let context = CGContext(data: pointer.baseAddress, width: image.width, height: image.height,
                                          bitsPerComponent: 8, bytesPerRow: image.width * 4,
                                          space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { throw CheckFailure(message: "bitmap") }
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        }
        return bytes
    }
    static func main() {
        do { try run() } catch { fputs("FAIL: \(error)\n", stderr); exit(1) }
    }
    static func run() throws {
        let root = URL(fileURLWithPath: CommandLine.arguments[1])
        let fixtures = try JSONSerialization.jsonObject(with: Data(contentsOf: root.appendingPathComponent("manifest.json"))) as! [[String: Any]]
        var reference: [String: [UInt8]] = [:]
        for fixture in fixtures {
            let name = fixture["name"] as! String, compression = fixture["compression"] as! Int
            let key = ["version", "mode", "channels", "depth"].map { String(fixture[$0] as! Int) }.joined(separator: "-")
            let preview = try PhotoshopImage.render(url: root.appendingPathComponent(name), maxPixelDimension: 512)
            try check(preview.header.width == 5 && preview.header.height == 3 && preview.image.width == 5 && preview.image.height == 3, "dimensions \(name)")
            let bytes = try pixels(preview.image)
            if compression == 0 { reference[key] = bytes }
            else {
                let expected = reference[key]!
                try check(zip(bytes, expected).allSatisfy { abs(Int($0)-Int($1)) <= 1 }, "decoded pixels match raw \(name)")
            }
            try check(stride(from: 3, to: bytes.count, by: 4).allSatisfy { bytes[$0] == 255 },
                      "no-layer samples do not mistake extra channels for transparency \(name)")
        }
        let alphaFixtures = try JSONSerialization.jsonObject(with: Data(contentsOf: root.appendingPathComponent("alpha-manifest.json"))) as! [[String: Any]]
        var alphaReference: [String: [UInt8]] = [:]
        for fixture in alphaFixtures {
            let name = fixture["name"] as! String, merged = fixture["merged"] as! Bool
            let preview = try PhotoshopImage.render(url: root.appendingPathComponent(name))
            try check(preview.header.hasMergedTransparency == merged, "layer sign or global marker \(name)")
            let bytes = try pixels(preview.image)
            try check(stride(from: 3, to: bytes.count, by: 4).allSatisfy { merged ? abs(Int(bytes[$0]) - 64) <= 1 : bytes[$0] == 255 },
                      "user alpha is opaque; merged alpha remains transparent \(name)")
            if fixture["depth"] as! Int == 8 && fixture["mode"] as! Int == 3 {
                let expected: [UInt8] = merged ? [64, 16, 32, 64] : [255, 64, 128, 255]
                try check(zip(bytes.prefix(4), expected).allSatisfy { abs(Int($0)-Int($1)) <= 1 },
                          "known white-matted foreground and saved selection retain correct colors \(name)")
            }
            let key = ["version", "mode", "depth"].map { String(fixture[$0] as! Int) }.joined(separator: "-") + "-\(merged)"
            if let expected = alphaReference[key] {
                try check(zip(bytes, expected).allSatisfy { abs(Int($0)-Int($1)) <= 1 }, "alpha output agrees across encodings and marker placements \(name)")
            } else { alphaReference[key] = bytes }
        }
        for suffix in ["psd", "psb"] {
            let bitmap = try PhotoshopImage.render(url: root.appendingPathComponent("bitmap-rle.\(suffix)"))
            try check(bitmap.image.width == 8 && bitmap.image.height == 1, "native 1-bit PackBits retained \(suffix)")
        }
        let large = try PhotoshopImage.render(url: root.appendingPathComponent("large.psb"), maxPixelDimension: 8192)
        try check(large.header.width == 300_000 && large.header.height == 128, "original PSB dimensions preserved")
        try check(large.image.width == 8192 && large.image.height <= 4, "large PSB preview allocation bounded")
        let largePixels = try pixels(large.image)
        try check(largePixels.allSatisfy { $0 == 255 }, "large PackBits rows decode white")
        let thumbnail = try PhotoshopImage.render(url: root.appendingPathComponent("large.psb"), maxPixelDimension: 256)
        try check(thumbnail.image.width == 256, "PSB thumbnail bound")
        let bad = try JSONSerialization.jsonObject(with: Data(contentsOf: root.appendingPathComponent("bad.json"))) as! [String]
        for name in bad {
            do { _ = try PhotoshopImage.render(url: root.appendingPathComponent(name)); throw CheckFailure(message: "accepted invalid \(name)") }
            catch is PhotoshopImage.Failure { checks += 1 }
        }
        do {
            _ = try PhotoshopImage.render(url: root.appendingPathComponent("v2-m3-c3-d8-z3.psb"), isCancelled: { true })
            throw CheckFailure(message: "cancelled decode completed")
        } catch PhotoshopImage.Failure.cancelled { checks += 1 }
        var cancellationChecks = 0
        do {
            _ = try PhotoshopImage.render(url: root.appendingPathComponent("long-noop-row.psb"), isCancelled: {
                cancellationChecks += 1
                return cancellationChecks >= 5
            })
            throw CheckFailure(message: "long PackBits no-op row did not cancel")
        } catch PhotoshopImage.Failure.cancelled {
            try check(cancellationChecks == 5, "cancellation checked inside a single PackBits row")
        }
        let psb = root.appendingPathComponent("v2-m3-c4-d16-z3.psb").standardizedFileURL
        try check(ImageLibrary.isSupported(psb), "PSB participates in file discovery")
        let format = MediaFormats.associationFormats.first { $0.id == "psd" }
        try check(format?.extensions == ["psd", "psb"], "Photoshop default-format group includes PSB")
        let files = try ImageLibrary.collect(from: [psb])
        try check(files.items[files.selectedIndex].url == psb, "opening PSB retains selection in folder")
        let loader = ImageLoader()
        var loaded: Result<LoadedImage, Error>?
        loader.load(psb) { loaded = $0 }
        let deadline = Date().addingTimeInterval(20)
        while loaded == nil && Date() < deadline { RunLoop.main.run(until: Date().addingTimeInterval(0.01)) }
        guard let result = loaded else { throw CheckFailure(message: "main image load timed out") }
        let image = try result.get()
        try check(image.pixelSize == CGSize(width: 5, height: 3) && image.image.width == 5, "main image uses ZIP prediction decode")
        try check(image.metadata.contains { $0.0 == "格式" && $0.1 == "Photoshop PSB" }, "PSB metadata")
        var thumb: NSImage?, completed = false
        _ = loader.thumbnail(psb) { thumb = $0; completed = true }
        while !completed && Date() < deadline { RunLoop.main.run(until: Date().addingTimeInterval(0.01)) }
        try check(thumb != nil, "PSB thumbnail pipeline")
        loaded = nil
        loader.load(root.appendingPathComponent("large.psb")) { loaded = $0 }
        while loaded == nil && Date() < deadline { RunLoop.main.run(until: Date().addingTimeInterval(0.01)) }
        guard let largeResult = loaded else { throw CheckFailure(message: "large main load timed out") }
        let largeImage = try largeResult.get()
        try check(largeImage.pixelSize == CGSize(width: 300_000, height: 128) && largeImage.isDownsampledPreview,
                  "main image preserves true PSB dimensions and marks bounded preview")
        print("PASS: \(checks) Photoshop composite checks; \(fixtures.count) codec combinations and \(alphaFixtures.count) layer-alpha cases")
    }
}
