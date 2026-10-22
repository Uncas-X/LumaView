import AppKit
import AVFoundation
import ImageIO
import UniformTypeIdentifiers

private struct AudioTestFailure: Error, CustomStringConvertible { let description: String }
private final class AudioTestBox<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: Value?
    var value: Value? { lock.lock(); defer { lock.unlock() }; return stored }
    func set(_ value: Value) { lock.lock(); stored = value; lock.unlock() }
}

@main
struct AudioWaveformTests {
    private static var checks = 0

    static func main() {
        setbuf(stdout, nil)
        do { try run(); print("PASS: \(checks) audio waveform, cover, duration and cancellation checks") }
        catch { FileHandle.standardError.write(Data("FAIL: \(error)\n".utf8)); exit(1) }
    }

    private static func check(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        guard condition() else { throw AudioTestFailure(description: message) }
        checks += 1; print("PASS: \(message)")
    }

    private static func spin(timeout: Double = 20, _ predicate: () -> Bool) -> Bool {
        let end = Date().addingTimeInterval(timeout)
        while !predicate(), Date() < end { RunLoop.current.run(until: Date().addingTimeInterval(0.01)) }
        return predicate()
    }

    private static func generated(_ url: URL, bins: Int = 1200) throws -> AudioWaveform {
        let result = AudioTestBox<Result<AudioWaveform, Error>>()
        let task = Task.detached {
            do {
                let value = try await AudioWaveformGenerator.generate(url: url, binCount: bins)
                result.set(.success(value))
            } catch { result.set(.failure(error)) }
        }
        guard spin({ result.value != nil }) else { task.cancel(); throw AudioTestFailure(description: "waveform timed out") }
        return try result.value!.get()
    }

    private static func session(_ url: URL) throws -> VideoSession {
        let value = VideoSession(url: url)
        var result: Result<VideoSession, Error>?
        value.prepare { result = $0 }
        guard spin(timeout: 60, { result != nil }) else { value.dispose(); throw AudioTestFailure(description: "audio session timed out") }
        return try result!.get()
    }

    private static func writeWAV(_ url: URL, seconds: Double, silent: Bool = false, stereo: Bool = true) throws {
        let rate = 8_000, channels = stereo ? 2 : 1, frames = Int(seconds * Double(rate))
        var data = Data()
        func text(_ value: String) { data.append(contentsOf: value.utf8) }
        func u16(_ value: UInt16) { var value = value.littleEndian; withUnsafeBytes(of: &value) { data.append(contentsOf: $0) } }
        func u32(_ value: UInt32) { var value = value.littleEndian; withUnsafeBytes(of: &value) { data.append(contentsOf: $0) } }
        text("RIFF"); u32(UInt32(36 + frames * channels * 2)); text("WAVEfmt "); u32(16)
        u16(1); u16(UInt16(channels)); u32(UInt32(rate)); u32(UInt32(rate * channels * 2))
        u16(UInt16(channels * 2)); u16(16); text("data"); u32(UInt32(frames * channels * 2))
        for frame in 0..<frames {
            let amplitude = silent ? 0 : (frame < frames / 2 ? 0.15 : 0.8)
            let sample = Int16((sin(Double(frame) * 2 * .pi * 440 / Double(rate)) * amplitude * 32767).rounded())
            u16(UInt16(bitPattern: sample))
            if stereo { u16(UInt16(bitPattern: -sample)) }
        }
        try data.write(to: url)
    }

    private static func fixtureCommand(_ arguments: [String]) throws {
        let path = ProcessInfo.processInfo.environment["LUMAVIEW_TEST_FFMPEG"]
            ?? ["/usr/local/bin/ffmpeg", "/opt/homebrew/bin/ffmpeg"].first(where: FileManager.default.isExecutableFile(atPath:))
        guard let path else { throw AudioTestFailure(description: "Set LUMAVIEW_TEST_FFMPEG to a fixture encoder with AAC, MP3, FLAC and Opus support") }
        let task = Process(); task.executableURL = URL(fileURLWithPath: path)
        task.arguments = ["-hide_banner", "-loglevel", "error", "-nostdin", "-y"] + arguments
        task.standardInput = FileHandle.nullDevice; task.standardOutput = FileHandle.nullDevice
        try task.run(); task.waitUntilExit()
        guard task.terminationStatus == 0 else { throw AudioTestFailure(description: "fixture encoder failed: \(arguments.last ?? "")") }
    }

    private static func run() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("LumaView-Audio-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        var accumulator = AudioWaveformGenerator.Accumulator(binCount: 4, duration: 1)
        [Float](repeating: 0, count: 8).withUnsafeBufferPointer {
            accumulator.consume(samples: $0, channels: 2, sampleRate: 4, startTime: 0)
        }
        try check(accumulator.peaks == [0, 0, 0, 0], "silence produces a zero envelope")
        let stereo: [Float] = [0.2, -0.8, -1.5, 0.3, .nan, .infinity, 0.4, -0.4]
        stereo.withUnsafeBufferPointer { accumulator.consume(samples: $0, channels: 2, sampleRate: 4, startTime: 0) }
        try check(accumulator.peaks == [0.8, 1, 0, 0.4], "envelope combines stereo peaks without phase cancellation, clamps clipping and ignores invalid samples")
        var split = AudioWaveformGenerator.Accumulator(binCount: 4, duration: 1)
        Array(stereo.prefix(3)).withUnsafeBufferPointer { split.consume(samples: $0, channels: 2, sampleRate: 4, startTime: 0) }
        Array(stereo.dropFirst(3)).withUnsafeBufferPointer { split.consume(samples: $0, interleavedOffset: 3, channels: 2, sampleRate: 4, startTime: 0) }
        try check(split.peaks == accumulator.peaks, "chunk boundaries preserve interleaved frame positions")
        try check(AudioWaveformGenerator.Accumulator(binCount: Int.max, duration: 1).peaks.count == 4096, "overview has a fixed maximum bin budget")

        let tone = directory.appendingPathComponent("tone.wav"), silent = directory.appendingPathComponent("silence.wav")
        try writeWAV(tone, seconds: 4)
        try writeWAV(silent, seconds: 1, silent: true, stereo: false)
        let actual = try generated(tone)
        try check(actual.peaks.count == 1200 && abs(actual.duration - 4) < 0.01, "native waveform decodes the requested number of bins and original duration")
        let quiet = actual.peaks[0..<600].reduce(0, +) / 600
        let loud = actual.peaks[600..<1200].reduce(0, +) / 600
        try check(quiet > 0.1 && quiet < 0.2 && loud > 0.7 && loud < 0.9, "real WAV envelope preserves its quiet and loud halves")
        let silentWaveform = try generated(silent)
        try check(silentWaveform.peaks.allSatisfy { $0 == 0 }, "decoded silent WAV is flat")
        try check(AudioArtwork.make(for: tone, waveform: actual) != nil, "true sample envelope renders as the audio display image")
        try check(AudioArtwork.make(for: tone) != nil, "loading fallback remains available")
        try check(AudioArtwork.decodeCover(Data("invalid cover".utf8)) == nil, "invalid cover bytes fail gracefully")
        if let largeContext = CGContext(data: nil, width: 4096, height: 1024, bitsPerComponent: 8, bytesPerRow: 4096 * 4,
                                        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
           let image = largeContext.makeImage() {
            let bytes = NSMutableData()
            let destination = CGImageDestinationCreateWithData(bytes, UTType.png.identifier as CFString, 1, nil)!
            CGImageDestinationAddImage(destination, image, nil)
            _ = CGImageDestinationFinalize(destination)
            let reduced = AudioArtwork.decodeCover(bytes as Data)
            try check(reduced?.width == 2048 && reduced?.height == 512, "large embedded cover is decoded to a bounded 2048-pixel preview")
        } else { throw AudioTestFailure(description: "large cover fixture") }

        let cover = directory.appendingPathComponent("cover.png")
        guard let context = CGContext(data: nil, width: 120, height: 80, bitsPerComponent: 8, bytesPerRow: 480,
                                      space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
              let destination = CGImageDestinationCreateWithURL(cover as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw AudioTestFailure(description: "cover context")
        }
        context.setFillColor(CGColor(red: 1, green: 0.2, blue: 0.1, alpha: 1)); context.fill(CGRect(x: 0, y: 0, width: 120, height: 80))
        CGImageDestinationAddImage(destination, context.makeImage()!, nil)
        guard CGImageDestinationFinalize(destination) else { throw AudioTestFailure(description: "cover PNG") }
        for (ext, codec) in [("m4a", "aac"), ("mp3", "libmp3lame"), ("flac", "flac")] {
            let file = directory.appendingPathComponent("covered.\(ext)")
            try fixtureCommand(["-i", tone.path, "-i", cover.path, "-map", "0:a:0", "-map", "1:v:0", "-c:a", codec,
                                "-c:v", "copy", "-disposition:v:0", "attached_pic", file.path])
            let opened = try session(file)
            defer { opened.dispose() }
            try check(opened.isAudioOnly, "\(ext.uppercased()) embedded album art is not mistaken for a video track")
            try check(spin({ opened.audioCover != nil }), "\(ext.uppercased()) audio session delivers its original embedded album cover")
            let image = opened.audioCover!
            try check(image.width <= 2048 && image.height <= 2048 && abs(Double(image.width) / Double(image.height) - 1.5) < 0.01,
                      "\(ext.uppercased()) cover decoding preserves aspect ratio within the size budget")
            opened.dispose()
            if ext == "flac" {
                var fallback: CGImage?, completed = false
                let job = CompatibilityMedia.audioCover(url: file) { fallback = $0; completed = true }
                try check(spin({ completed }) && fallback != nil, "bundled FFmpeg extracts an attached FLAC cover from the original file")
                job.cancel()
            }
        }

        let opus = directory.appendingPathComponent("non-native.ogg")
        try fixtureCommand(["-i", tone.path, "-c:a", "libopus", opus.path])
        let loader = ImageLoader()
        for file in [tone, opus] {
            var completed = false, value: NSImage?, seconds: Double?
            loader.thumbnail(file) { value = $0; seconds = loader.videoDuration(for: file); completed = true }
            try check(spin(timeout: 40, { completed }) && value != nil, "\(file.pathExtension) audio thumbnail loads without selecting the file")
            try check(seconds.map { abs($0 - 4) < 0.1 } == true, "\(file.pathExtension) duration is stored before filmstrip thumbnail completion")
        }
        let converted = try session(opus)
        defer { converted.dispose() }
        try check(spin({ converted.audioWaveform != nil }), "compatibility audio generates its waveform from the prepared playback asset")
        try check(converted.audioWaveform!.peaks.contains { $0 > 0.5 }, "compatibility waveform contains the actual audio samples")
        converted.dispose()

        let cancelled = AudioTestBox<Bool>()
        let cancelTask = Task.detached {
            do { _ = try await AudioWaveformGenerator.generate(url: tone) }
            catch is CancellationError { cancelled.set(true) }
            catch { }
        }
        cancelTask.cancel()
        try check(spin({ cancelled.value == true }), "cancelling a waveform task stops decoding with CancellationError")
        let longAudio = directory.appendingPathComponent("cancellation.wav")
        try writeWAV(longAudio, seconds: 60)
        for iteration in 0..<12 {
            let completed = AudioTestBox<Bool>()
            let pending = Task.detached {
                do { _ = try await AudioWaveformGenerator.generate(url: longAudio) }
                catch { }
                completed.set(true)
            }
            // Sweep metadata loading, startReading and live PCM decoding. The
            // old unsynchronized cancelReading path could crash Core Media.
            RunLoop.current.run(until: Date().addingTimeInterval(Double(iteration % 6) * 0.002))
            pending.cancel()
            try check(spin({ completed.value == true }), "waveform cancellation safely completes during reader startup/decoding (\(iteration + 1)/12)")
        }
        let immediatelyDisposed = VideoSession(url: tone)
        var visualAfterDispose = false
        immediatelyDisposed.onAudioVisualChanged = { visualAfterDispose = true }
        immediatelyDisposed.prepare { _ in }
        immediatelyDisposed.dispose()
        RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        try check(!visualAfterDispose, "disposed session suppresses stale cover and waveform updates")

        var coverAfterCancel = false
        let cancelledCover = CompatibilityMedia.audioCover(url: directory.appendingPathComponent("covered.flac")) { _ in coverAfterCancel = true }
        cancelledCover.cancel()
        RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        try check(!coverAfterCancel, "cancelled cover extraction does not deliver a stale callback")
    }
}
