import AppKit
import AVFoundation
import CoreVideo
import ImageIO
import UniformTypeIdentifiers

private struct CopyTestFailure: Error, CustomStringConvertible { let description: String }

@main
struct MediaCopyTests {
    private static var checks = 0
    static func main() {
        setbuf(stdout, nil)
        do { try run(); print("PASS: \(checks) media copy checks") }
        catch { FileHandle.standardError.write(Data("FAIL: \(error)\n".utf8)); exit(1) }
    }

    private static func check(_ value: @autoclosure () throws -> Bool, _ message: String) throws {
        guard try value() else { throw CopyTestFailure(description: message) }
        checks += 1; print("PASS: \(message)")
    }
    private static func fail(_ message: String) -> CopyTestFailure { CopyTestFailure(description: message) }
    @discardableResult
    private static func spin(timeout: Double = 15, _ predicate: () -> Bool) -> Bool {
        let end = Date().addingTimeInterval(timeout)
        while !predicate(), Date() < end { RunLoop.current.run(until: Date().addingTimeInterval(0.01)) }
        return predicate()
    }
    private static func session(_ url: URL) throws -> VideoSession {
        let value = VideoSession(url: url)
        var result: Result<VideoSession, Error>?
        value.prepare { result = $0 }
        guard spin(timeout: 60, { result != nil }) else { value.dispose(); throw fail("session preparation timed out") }
        return try result!.get()
    }
    private static func frame(_ session: VideoSession, at time: Double? = nil) throws -> CGImage {
        var result: Result<CGImage, Error>?, onMain = false
        session.captureCurrentFrame(at: time.map { CMTime(seconds: $0, preferredTimescale: 60_000) }) {
            result = $0; onMain = Thread.isMainThread
        }
        guard spin({ result != nil }) else { throw fail("frame capture timed out") }
        try check(onMain, "video frame callback runs on main")
        return try result!.get()
    }
    private static func rgba(_ image: CGImage, x: Int? = nil, y: Int? = nil) throws -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        guard let context = CGContext(data: &bytes, width: image.width, height: image.height, bitsPerComponent: 8,
            bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { throw fail("sample context") }
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        let offset = ((y ?? image.height / 2) * image.width + (x ?? image.width / 2)) * 4
        return Array(bytes[offset..<offset + 4])
    }
    private static func blue(_ image: CGImage) throws -> Bool {
        let p = try rgba(image); return p[2] > 180 && p[0] < 70 && p[1] < 70
    }
    private static func red(_ image: CGImage) throws -> Bool {
        let p = try rgba(image); return p[0] > 180 && p[1] < 70 && p[2] < 70
    }
    private static func frameNumber(_ image: CGImage) throws -> Int {
        func white(_ p: [UInt8]) -> Bool { p[0] > 200 && p[1] > 200 && p[2] > 200 }
        // Locate the white anchor to normalize Core Video's row orientation.
        let y = white(try rgba(image, x: 148, y: 6)) ? 6 : image.height - 7
        guard white(try rgba(image, x: 148, y: y)) else { throw fail("frame barcode anchor") }
        var number = 0
        for bit in 0..<6 where white(try rgba(image, x: 28 + bit * 16, y: y)) { number |= 1 << bit }
        return number
    }

    private static func writeVideo(_ url: URL, portrait: Bool = false) throws {
        let width = 160, height = 96, count = 60, fps: Int32 = 30
        let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: width, AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 400_000,
                AVVideoMaxKeyFrameIntervalKey: count, AVVideoAllowFrameReorderingKey: false]])
        if portrait { input.transform = CGAffineTransform(a: 0, b: 1, c: -1, d: 0, tx: CGFloat(height), ty: 0) }
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: width, kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferCGImageCompatibilityKey as String: true, kCVPixelBufferCGBitmapContextCompatibilityKey as String: true])
        guard writer.canAdd(input) else { throw fail("video input") }
        writer.add(input)
        guard writer.startWriting() else { throw writer.error ?? fail("start video writer") }
        writer.startSession(atSourceTime: .zero)
        for index in 0..<count {
            guard spin({ input.isReadyForMoreMediaData || writer.status == .failed }), writer.status == .writing,
                  let pool = adaptor.pixelBufferPool else { throw writer.error ?? fail("video writer readiness") }
            var optionalBuffer: CVPixelBuffer?
            guard CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &optionalBuffer) == kCVReturnSuccess,
                  let buffer = optionalBuffer else { throw fail("video buffer") }
            CVPixelBufferLockBaseAddress(buffer, [])
            guard let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else { throw fail("video context") }
            context.setFillColor(index < count / 2 ? NSColor.red.cgColor : NSColor.blue.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            context.setFillColor(NSColor.white.cgColor); context.fill(CGRect(x: 0, y: 0, width: 20, height: 20))
            context.setFillColor(NSColor.green.cgColor); context.fill(CGRect(x: width - 20, y: height - 20, width: 20, height: 20))
            // Frame-index barcode: assertions can distinguish exact frames even
            // when an adjacent keyframe has the same overall scene color.
            for bit in 0..<6 {
                context.setFillColor(index & (1 << bit) != 0 ? NSColor.white.cgColor : NSColor.black.cgColor)
                context.fill(CGRect(x: 24 + bit * 16, y: 2, width: 8, height: 8))
            }
            context.setFillColor(NSColor.white.cgColor); context.fill(CGRect(x: 140, y: 2, width: 16, height: 8))
            CVPixelBufferUnlockBaseAddress(buffer, [])
            guard adaptor.append(buffer, withPresentationTime: CMTime(value: Int64(index), timescale: fps)) else { throw writer.error ?? fail("append frame") }
        }
        input.markAsFinished(); writer.endSession(atSourceTime: CMTime(value: Int64(count), timescale: fps))
        var finished = false
        writer.finishWriting { DispatchQueue.main.async { finished = true } }
        guard spin({ finished }), writer.status == .completed else { throw writer.error ?? fail("finish video") }
    }
    private static func remux(_ source: URL, to output: URL) throws {
        guard let tools = ProcessInfo.processInfo.environment["LUMAVIEW_MEDIA_TOOLS"] else { throw fail("bundled fixture tool path") }
        let process = Process(); process.executableURL = URL(fileURLWithPath: tools).appendingPathComponent("ffmpeg")
        process.arguments = ["-hide_banner", "-loglevel", "error", "-nostdin", "-y", "-i", source.path, "-c", "copy", output.path]
        process.standardInput = FileHandle.nullDevice; process.standardOutput = FileHandle.nullDevice
        try process.run(); process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw fail("MKV fixture remux") }
    }
    private static func addAudioTail(_ video: URL, audio: URL, output: URL) throws {
        guard let tools = ProcessInfo.processInfo.environment["LUMAVIEW_MEDIA_TOOLS"] else { throw fail("bundled fixture tool path") }
        let process = Process(); process.executableURL = URL(fileURLWithPath: tools).appendingPathComponent("ffmpeg")
        process.arguments = ["-hide_banner", "-loglevel", "error", "-nostdin", "-y", "-i", video.path,
            "-stream_loop", "3", "-i", audio.path, "-map", "0:v", "-map", "1:a", "-c:v", "copy", "-c:a", "aac", output.path]
        process.standardInput = FileHandle.nullDevice; process.standardOutput = FileHandle.nullDevice
        try process.run(); process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw fail("long audio tail fixture") }
    }
    private static func writeAudio(_ url: URL) throws {
        var data = Data()
        func text(_ value: String) { data.append(contentsOf: value.utf8) }
        func u16(_ value: UInt16) { var v = value.littleEndian; withUnsafeBytes(of: &v) { data.append(contentsOf: $0) } }
        func u32(_ value: UInt32) { var v = value.littleEndian; withUnsafeBytes(of: &v) { data.append(contentsOf: $0) } }
        text("RIFF"); u32(36 + 16_000); text("WAVEfmt "); u32(16); u16(1); u16(1); u32(8_000)
        u32(16_000); u16(2); u16(16); text("data"); u32(16_000); data.append(Data(count: 16_000))
        try data.write(to: url)
    }

    private static func run() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("LumaView-MediaCopy-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let context = CGContext(data: nil, width: 4, height: 2, bitsPerComponent: 8, bytesPerRow: 16,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.setFillColor(NSColor.red.cgColor); context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        context.setFillColor(NSColor.blue.withAlphaComponent(0.5).cgColor); context.fill(CGRect(x: 2, y: 0, width: 2, height: 2))
        let image = context.makeImage()!
        try check(MediaCopy.rotated(image, quarterTurns: 0) === image, "unrotated copy preserves original image object")
        try check(MediaCopy.rotated(image, quarterTurns: 4) === image, "complete rotation preserves original pixels")
        let rotated = MediaCopy.rotated(image, quarterTurns: 1)!
        try check(rotated.width == 2 && rotated.height == 4, "clockwise quarter-turn swaps pixel dimensions")
        let top = try rgba(rotated, x: 0, y: 0), bottom = try rgba(rotated, x: 0, y: 3)
        try check(top[0] == 255 && bottom[2] > 120 && bottom[3] > 120 && bottom[3] < 135, "clockwise rotation preserves orientation and transparent pixels")
        let restored = MediaCopy.rotated(rotated, quarterTurns: -1)!
        try check(restored.width == image.width && restored.height == image.height && (try rgba(restored, x: 3, y: 1)) == (try rgba(image, x: 3, y: 1)), "negative rotation restores image dimensions and alpha")
        for type in [UTType.png, .tiff] {
            let data = MediaCopy.encodedImage(rotated, type: type)
            let source = data.flatMap { CGImageSourceCreateWithData($0 as CFData, nil) }
            let decoded = source.flatMap { CGImageSourceCreateImageAtIndex($0, 0, nil) }
            try check(decoded?.width == 2 && decoded?.height == 4, "\(type.preferredFilenameExtension!) data carries actual rotated pixel dimensions")
            try check(decoded != nil && (try rgba(decoded!, x: 0, y: 3))[3] == bottom[3], "\(type.preferredFilenameExtension!) encoding retains alpha without UI background")
        }
        let landscapeURL = directory.appendingPathComponent("landscape.mov")
        let portraitURL = directory.appendingPathComponent("portrait.mov")
        try writeVideo(landscapeURL); try writeVideo(portraitURL, portrait: true)
        let unprepared = VideoSession(url: landscapeURL)
        var unpreparedFailure = false
        unprepared.captureCurrentFrame { if case .failure = $0 { unpreparedFailure = true } }
        try check(unpreparedFailure, "copy before preparation returns a recoverable error")
        unprepared.dispose()
        let video = try session(landscapeURL)
        defer { video.dispose() }
        let first = try frame(video)
        try check(first.width == 160 && first.height == 96 && (try red(first)), "first video frame has native dimensions and image pixels")
        video.seek(to: 1.234)
        try check(spin { abs(video.currentTime - 1.234) < 0.01 }, "paused seek reaches non-keyframe timestamp")
        let pausedTime = video.currentTime, pausedFrame = try frame(video)
        try check(try blue(pausedFrame), "paused non-keyframe capture contains the requested blue scene")
        let preciseNumber = try frameNumber(pausedFrame)
        try check(preciseNumber == 37, "precise capture selects frame 37, not earlier same-scene keyframe (got \(preciseNumber))")
        try check(video.player.rate == 0 && !video.isPlaying && abs(video.currentTime - pausedTime) < 0.001, "copy preserves paused playback position and state")
        let earlier = try frame(video, at: 0.234)
        try check(try red(earlier), "explicit menu-open timestamp captures earlier frame instead of current progress")
        let earlyNumber = try frameNumber(earlier)
        try check(earlyNumber == 7, "explicit fractional timestamp selects frame 7 rather than frame zero (got \(earlyNumber))")
        try check(abs(video.currentTime - pausedTime) < 0.001, "explicit frame extraction never seeks the player")
        video.play()
        try check(spin { video.currentTime > 1.4 && video.isPlaying }, "video starts playback for in-motion capture")
        let moving = try frame(video, at: 0.4)
        try check(try red(moving), "playing capture honors frozen context-menu timestamp")
        try check(video.isPlaying && video.player.rate > 0, "capture does not pause ongoing playback")
        video.pause(); video.seek(to: video.duration)
        try check(spin { video.currentTime >= video.duration - 0.001 }, "seek reaches exclusive video endpoint")
        let ended = try frame(video)
        try check(try blue(ended), "copy at playback end returns the final frame")
        try check(video.player.rate == 0 && !video.isPlaying && video.currentTime >= video.duration - 0.001, "end-of-video capture does not restart playback")
        var cancelledCallback = false
        video.captureCurrentFrame(at: .zero) { _ in cancelledCallback = true }
        video.cancelFrameCapture(); spin(timeout: 0.2) { false }
        try check(!cancelledCallback, "cancelled frame request never delivers a late completion")
        var oldCallback = false, newest: Result<CGImage, Error>?
        video.captureCurrentFrame(at: .zero) { _ in oldCallback = true }
        video.captureCurrentFrame(at: CMTime(seconds: 1.3, preferredTimescale: 600)) { newest = $0 }
        try check(spin { newest != nil }, "new frame request completes after superseding earlier request")
        try check(!oldCallback && (try blue(newest!.get())), "superseded frame cannot replace newer copy pixels")
        var backgroundCallback = false, backgroundMain = false
        DispatchQueue.global().async {
            video.captureCurrentFrame(at: .zero) { _ in backgroundCallback = true; backgroundMain = Thread.isMainThread }
        }
        try check(spin { backgroundCallback } && backgroundMain, "background caller is marshalled to main for frame completion")
        let portrait = try session(portraitURL)
        let portraitFrame = try frame(portrait, at: 1.234)
        try check(portraitFrame.width == 96 && portraitFrame.height == 160, "video preferred transform is applied to copied portrait dimensions")
        try check(try blue(portraitFrame), "rotated video copies genuine decoded video pixels")
        portrait.dispose()
        let mkvURL = directory.appendingPathComponent("compatibility.mkv")
        try remux(landscapeURL, to: mkvURL)
        let compatibility = try session(mkvURL)
        try check(compatibility.usedCompatibilityDecoder && (compatibility.player.currentItem?.asset as? AVURLAsset)?.url != mkvURL, "MKV session owns a different actual compatible playback asset")
        let compatibleFrame = try frame(compatibility, at: 1.234)
        try check(try blue(compatibleFrame), "compatibility video frame uses actual player-item asset")
        compatibility.dispose()
        let audioURL = directory.appendingPathComponent("audio.wav"); try writeAudio(audioURL)
        let audio = try session(audioURL)
        var audioFailure = false
        audio.captureCurrentFrame { if case .failure(VideoFrameCaptureError.audioOnly) = $0 { audioFailure = true } }
        try check(audio.isAudioOnly && audioFailure, "audio-only media rejects video-frame copying")
        audio.dispose()
        let tailURL = directory.appendingPathComponent("long-audio-tail.mov")
        try addAudioTail(landscapeURL, audio: audioURL, output: tailURL)
        let tail = try session(tailURL)
        try check(tail.duration > 3, "fixture audio continues after two-second video track")
        tail.seek(to: 3.25)
        try check(spin { abs(tail.currentTime - 3.25) < 0.01 }, "player seeks into remaining audio after final video frame")
        let tailFrame = try frame(tail)
        try check(try frameNumber(tailFrame) == 59, "copy during audio tail returns final actual video frame 59")
        try check(!tail.isPlaying && tail.player.rate == 0 && abs(tail.currentTime - 3.25) < 0.01, "copying final video frame preserves later audio timeline")
        tail.dispose()
        var disposedCallback = false
        video.captureCurrentFrame(at: .zero) { _ in disposedCallback = true }
        video.dispose(); spin(timeout: 0.2) { false }
        try check(!disposedCallback, "closing session cancels frame extraction before completion")
    }
}
