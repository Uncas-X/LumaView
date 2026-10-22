import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

private struct ThumbnailRequestTestFailure: Error, CustomStringConvertible {
    let description: String
}

/// Uses generated local fixtures and real decoders; never opens a window.
@main struct ThumbnailRequestTests {
    private static var checks = 0

    static func main() {
        setbuf(stdout, nil)
        do { try run(); print("\(checks) thumbnail request cancellation checks passed") }
        catch { FileHandle.standardError.write(Data("FAIL: \(error)\n".utf8)); exit(1) }
    }

    private static func check(_ okay: Bool, _ name: String) throws {
        guard okay else { throw ThumbnailRequestTestFailure(description: name) }
        checks += 1; print("PASS \(name)")
    }

    private static func spin(_ timeout: Double, until done: () -> Bool) -> Bool {
        let end = Date().addingTimeInterval(timeout)
        while !done() && Date() < end { RunLoop.current.run(until: Date().addingTimeInterval(0.005)) }
        return done()
    }

    private static func writePNG(_ url: URL) throws {
        guard let context = CGContext(data: nil, width: 96, height: 64, bitsPerComponent: 8, bytesPerRow: 384,
                                      space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
              let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw ThumbnailRequestTestFailure(description: "cannot create PNG fixture")
        }
        context.setFillColor(CGColor(red: 0.8, green: 0.2, blue: 0.1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 96, height: 64))
        guard let image = context.makeImage() else { throw ThumbnailRequestTestFailure(description: "cannot render PNG fixture") }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw ThumbnailRequestTestFailure(description: "cannot write PNG fixture") }
    }

    private static func writeWAV(_ url: URL) throws {
        let rate = 8_000, frames = rate * 2
        var data = Data()
        func text(_ value: String) { data.append(contentsOf: value.utf8) }
        func u16(_ value: UInt16) { var value = value.littleEndian; withUnsafeBytes(of: &value) { data.append(contentsOf: $0) } }
        func u32(_ value: UInt32) { var value = value.littleEndian; withUnsafeBytes(of: &value) { data.append(contentsOf: $0) } }
        text("RIFF"); u32(UInt32(36 + frames * 2)); text("WAVEfmt "); u32(16)
        u16(1); u16(1); u32(UInt32(rate)); u32(UInt32(rate * 2)); u16(2); u16(16)
        text("data"); u32(UInt32(frames * 2))
        for frame in 0..<frames {
            let sample = Int16((sin(Double(frame) * 2 * .pi * 440 / Double(rate)) * 8_000).rounded())
            u16(UInt16(bitPattern: sample))
        }
        try data.write(to: url)
    }

    private static func encode(_ arguments: [String]) throws {
        guard let tools = ProcessInfo.processInfo.environment["LUMAVIEW_MEDIA_TOOLS"] else {
            throw ThumbnailRequestTestFailure(description: "LUMAVIEW_MEDIA_TOOLS must point to bundled FFmpeg")
        }
        let task = Process()
        task.executableURL = URL(fileURLWithPath: tools).appendingPathComponent("ffmpeg")
        task.arguments = ["-hide_banner", "-loglevel", "error", "-nostdin", "-y"] + arguments
        task.standardInput = FileHandle.nullDevice; task.standardOutput = FileHandle.nullDevice
        try task.run(); task.waitUntilExit()
        guard task.terminationStatus == 0 else { throw ThumbnailRequestTestFailure(description: "fixture encoder failed") }
    }

    private static func run() throws {
        let fixtures = FileManager.default.temporaryDirectory.appendingPathComponent("lumaview-thumbnail-request-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: fixtures, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: fixtures) }
        let image = fixtures.appendingPathComponent("image.png")
        let video = fixtures.appendingPathComponent("video.mp4")
        let compatible = fixtures.appendingPathComponent("video.mkv")
        let audio = fixtures.appendingPathComponent("tone.wav")
        try writePNG(image); try writeWAV(audio)
        try encode(["-loop", "1", "-i", image.path, "-t", "2", "-r", "2", "-c:v", "mpeg4", "-q:v", "8", "-an", video.path])
        try encode(["-i", video.path, "-c:v", "copy", "-an", compatible.path])

        let request = ThumbnailRequest()
        var cancellations = 0, deliveries = 0
        request.onCancel { cancellations += 1 }; request.cancel(); request.cancel()
        request.onCancel { cancellations += 1 }; request.finish { deliveries += 1 }
        try check(request.isCancelled && cancellations == 2 && deliveries == 0,
                  "ticket cancellation is idempotent, late handlers run, delivery is suppressed")
        let reentrant = ThumbnailRequest()
        reentrant.finish { reentrant.cancel(); deliveries += 1 }
        reentrant.finish { deliveries += 1 }
        try check(deliveries == 1, "completion is once-only and permits reentrant cancellation")
        let loader = ImageLoader()
        var baseline: NSImage?
        var callbackOnMain = false
        loader.thumbnail(image) { baseline = $0; callbackOnMain = Thread.isMainThread }
        try check(spin(10) { baseline != nil } && callbackOnMain,
                  "real raster thumbnail completes on main with an unretained ticket")
        var cancelledCallbacks = 0
        let hit = loader.thumbnail(image) { _ in cancelledCallbacks += 1 }
        hit.cancel()
        _ = spin(0.15) { false }
        try check(cancelledCallbacks == 0, "cancelled cache-hit delivery never reaches consumer")
        for (name, url) in [("native video", video), ("compatibility video", compatible), ("native audio", audio)] {
            let fresh = ImageLoader()
            var tickets: [ThumbnailRequest] = []
            for _ in 0..<40 { tickets.append(fresh.thumbnail(url) { _ in cancelledCallbacks += 1 }) }
            // Let native/compatibility workers start without draining main's
            // completion queue, then cancel both active and queued work.
            Thread.sleep(forTimeInterval: 0.02)
            tickets.forEach { $0.cancel() }
            var final: NSImage?
            let start = Date()
            fresh.thumbnail(image) { final = $0 }
            try check(spin(5) { final != nil }, "\(name): 40 cancelled requests release queue for visible raster")
            try check(Date().timeIntervalSince(start) < 5 && cancelledCallbacks == 0,
                      "\(name): cancellation suppresses all stale callbacks")
            var survivor: NSImage?
            fresh.thumbnail(url) { survivor = $0 }
            try check(spin(40) { survivor != nil }, "\(name): independent same-URL request survives")
        }
    }
}
