import AppKit
import AVFoundation
import ImageIO
import QuartzCore
import UniformTypeIdentifiers

/// Opt-in tests exercise the actual viewer, native mouse routing and bundled
/// decoder. Fixtures are generated locally and playback stays muted throughout.
func runAudioVisualSelfTests(_ viewer: ViewerController, output: URL) {
    var report: [String] = [], failures = 0
    func check(_ condition: @autoclosure () -> Bool, _ message: String) {
        let passed = condition()
        report.append("\(passed ? "PASS" : "FAIL") \(message)")
        if !passed { failures += 1 }
    }
    @discardableResult
    func spin(_ condition: () -> Bool, timeout: Double = 15) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            CATransaction.flush()
            if condition() { return true }
            RunLoop.main.run(until: Date().addingTimeInterval(0.015))
        } while Date() < deadline
        return condition()
    }
    func error(_ message: String) -> NSError {
        NSError(domain: "LumaView.AudioVisualSelfTest", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }
    func writeWAV(_ url: URL) throws {
        let rate = 16_000, frames = rate * 12
        var data = Data()
        func text(_ value: String) { data.append(contentsOf: value.utf8) }
        func u16(_ value: UInt16) { var little = value.littleEndian; withUnsafeBytes(of: &little) { data.append(contentsOf: $0) } }
        func u32(_ value: UInt32) { var little = value.littleEndian; withUnsafeBytes(of: &little) { data.append(contentsOf: $0) } }
        text("RIFF"); u32(UInt32(36 + frames * 2)); text("WAVEfmt "); u32(16)
        u16(1); u16(1); u32(UInt32(rate)); u32(UInt32(rate * 2)); u16(2); u16(16)
        text("data"); u32(UInt32(frames * 2))
        for frame in 0..<frames {
            let t = Double(frame) / Double(rate)
            let envelope = 0.12 + 0.72 * pow(abs(sin(t * 0.9)), 2)
            let sample = Int16((sin(t * .pi * 2 * 440) * envelope * 32767).rounded())
            u16(UInt16(bitPattern: sample))
        }
        try data.write(to: url, options: .atomic)
    }
    func writeImage(_ url: URL, cover: Bool) throws {
        let width = cover ? 720 : 960, height = cover ? 720 : 540
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                      bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { throw error("image fixture context") }
        let bounds = CGRect(x: 0, y: 0, width: width, height: height)
        context.setFillColor(CGColor(red: 0.06, green: 0.13, blue: 0.21, alpha: 1)); context.fill(bounds)
        context.setFillColor(CGColor(red: cover ? 0.98 : 0.27, green: cover ? 0.64 : 0.75, blue: 0.35, alpha: 1))
        context.fillEllipse(in: CGRect(x: width / 5, y: height / 3, width: width * 3 / 5, height: width * 3 / 5))
        context.setFillColor(CGColor(red: 0.06, green: 0.13, blue: 0.21, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height / 3))
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        (cover ? "LUMA / SOUND" : "STILL / PHOTO" as NSString).draw(at: NSPoint(x: 55, y: 130), withAttributes: [
            .font: NSFont.systemFont(ofSize: 42, weight: .semibold), .foregroundColor: NSColor.white
        ])
        (cover ? "NIGHT FLIGHT   /   STUDIO SESSION" : "AUDIO SWITCHING TEST" as NSString).draw(at: NSPoint(x: 57, y: 85), withAttributes: [
            .font: NSFont.systemFont(ofSize: 16, weight: .medium), .foregroundColor: NSColor(white: 0.65, alpha: 1)
        ])
        NSGraphicsContext.restoreGraphicsState()
        guard let image = context.makeImage(), let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw error("image fixture output")
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw error("image fixture PNG") }
    }
    func encodeFixture(_ arguments: [String], name: String) throws {
        guard let tools = Bundle.main.resourceURL?.appendingPathComponent("MediaTools") else { throw error("bundled tools unavailable") }
        let log = output.appendingPathComponent(name + "-fixture.log")
        FileManager.default.createFile(atPath: log.path, contents: nil)
        let handle = try FileHandle(forWritingTo: log)
        defer { try? handle.close() }
        let process = Process(); process.executableURL = tools.appendingPathComponent("ffmpeg")
        process.arguments = ["-hide_banner", "-loglevel", "error", "-nostdin", "-protocol_whitelist", "file,pipe"] + arguments
        process.standardInput = FileHandle.nullDevice; process.standardOutput = handle; process.standardError = handle
        try process.run()
        guard spin({ !process.isRunning }, timeout: 30) else { process.terminate(); throw error("\(name) fixture conversion timed out") }
        guard process.terminationStatus == 0 else { throw error("\(name) fixture conversion failed: \((try? String(contentsOf: log, encoding: .utf8)) ?? "")") }
    }
    var eventNumber = 7_000
    func click(_ view: NSView, point: NSPoint? = nil) -> Bool {
        guard let window = viewer.window, window.isVisible, !viewer.isClosing else { return false }
        viewer.revealChrome(); viewer.root.layoutSubtreeIfNeeded(); window.display(); CATransaction.flush()
        let location = view.convert(point ?? NSPoint(x: view.bounds.midX, y: view.bounds.midY), to: nil)
        let hit = viewer.root.hitTest(viewer.root.convert(location, from: nil))
        guard hit === view || hit?.isDescendant(of: view) == true else { return false }
        eventNumber += 2
        let time = ProcessInfo.processInfo.systemUptime
        guard let down = NSEvent.mouseEvent(with: .leftMouseDown, location: location, modifierFlags: [], timestamp: time,
                    windowNumber: window.windowNumber, context: nil, eventNumber: eventNumber, clickCount: 1, pressure: 1),
              let up = NSEvent.mouseEvent(with: .leftMouseUp, location: location, modifierFlags: [], timestamp: time + 0.001,
                    windowNumber: window.windowNumber, context: nil, eventNumber: eventNumber + 1, clickCount: 1, pressure: 0) else { return false }
        NSApp.postEvent(up, atStart: true); window.sendEvent(down)
        while let event = NSApp.nextEvent(matching: .leftMouseUp, until: Date(), inMode: .default, dequeue: true) {
            if event.windowNumber == window.windowNumber { window.sendEvent(event) } else { NSApp.sendEvent(event) }
        }
        return true
    }
    func clickFile(_ url: URL) -> Bool {
        guard let index = viewer.items.firstIndex(where: { $0.url == url }) else { return false }
        let capacity = max(1, Int((viewer.strip.bounds.width - 24) / 72))
        let first = max(0, min(viewer.selectedIndex - capacity / 2, viewer.items.count - capacity))
        let count = min(capacity, viewer.items.count)
        guard index >= first, index < first + count else { return false }
        return click(viewer.strip, point: NSPoint(x: (viewer.strip.bounds.width - CGFloat(count) * 72) / 2 + CGFloat(index - first) * 72 + 35, y: 35))
    }
    func ready(_ url: URL) -> Bool {
        viewer.currentURL == url && viewer.video?.isAudioOnly == true && viewer.videoSeekSlider.isEnabled
            && viewer.canvas.image != nil && viewer.window?.isVisible == true && !viewer.isClosing
    }
    func screenshot(_ name: String, view: NSView? = nil) {
        viewer.revealChrome(); spin({ false }, timeout: 0.35); viewer.window?.display(); CATransaction.flush()
        let target = view ?? viewer.root
        if let bitmap = target.bitmapImageRepForCachingDisplay(in: target.bounds) {
            target.cacheDisplay(in: target.bounds, to: bitmap)
            if let data = bitmap.representation(using: .png, properties: [:]) {
                try? data.write(to: output.appendingPathComponent(name), options: .atomic)
                check(data.count > 1_000, "Render \(name)")
                return
            }
        }
        check(false, "Render \(name)")
    }
    do {
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let fixtures = output.appendingPathComponent("audio-visual-fixtures", isDirectory: true)
        try FileManager.default.createDirectory(at: fixtures, withIntermediateDirectories: true)
        let covered = fixtures.appendingPathComponent("01-专辑封面.m4a")
        let waveform = fixtures.appendingPathComponent("02-真实波形.wav")
        let unselected = fixtures.appendingPathComponent("03-未选中音频.wav")
        let still = fixtures.appendingPathComponent("04-普通图片.png")
        let video = fixtures.appendingPathComponent("05-视频角标.mp4")
        let cover = fixtures.appendingPathComponent("cover-fixture.png")
        try writeWAV(waveform); try writeWAV(unselected)
        try writeImage(cover, cover: true); try writeImage(still, cover: false)
        try encodeFixture(["-i", waveform.path, "-i", cover.path, "-map", "0:a:0", "-map", "1:v:0",
                           "-c:a", "aac", "-c:v", "copy", "-disposition:v:0", "attached_pic", "-y", covered.path], name: "audio-cover")
        // A real twelve-second movie supplies the neighboring video thumbnail
        // and duration, so the badge screenshot exercises both loader paths.
        try encodeFixture(["-loop", "1", "-i", still.path, "-t", "12", "-r", "1", "-c:v", "mpeg4",
                           "-q:v", "8", "-an", "-y", video.path], name: "video-badge")
        viewer.stopSlideshow(); viewer.showFilmstrip = true; viewer.sort = .name
        viewer.videoVolumeSlider.doubleValue = 0; viewer.changeVideoVolume(viewer.videoVolumeSlider)
        viewer.open([covered, waveform, unselected, still, video])
        check(spin({ ready(covered) && viewer.video?.audioCover != nil }), "Viewer loads audio and its embedded cover")
        check(viewer.canvas.image === viewer.video?.audioCover, "Main canvas displays the original album cover in preference to a waveform card")
        func findLayer(_ name: String, in layer: CALayer?) -> CALayer? {
            guard let layer else { return nil }
            if layer.name == name { return layer }
            return layer.sublayers?.compactMap { findLayer(name, in: $0) }.first
        }
        let currentPhotoLayer = findLayer("photo-current", in: viewer.canvas.layer)
        let shownCover = currentPhotoLayer?.frame
        let bitmapBounds = findLayer("photo-bitmap", in: currentPhotoLayer)?.bounds
        let originalCover = viewer.video?.audioCover
        check(shownCover.map { rect in
            guard let originalCover, let bitmapBounds, rect.height > 0, bitmapBounds.height > 0 else { return false }
            let expected = CGFloat(originalCover.width) / CGFloat(originalCover.height)
            return abs(rect.width / rect.height - expected) < 0.001
                && abs(bitmapBounds.width / bitmapBounds.height - expected) < 0.001
        } == true, "Composited cover geometry keeps the album aspect ratio after replacing a rectangular loading card")
        check(viewer.video?.audioWaveform == nil, "A covered audio file avoids unnecessary full-file waveform decoding")
        check(viewer.video?.player.volume == 0, "Audio visual tests keep playback muted")
        check(spin({ viewer.loader.videoDuration(for: unselected) != nil }), "Unselected audio obtains its duration during filmstrip loading")
        check(viewer.currentURL == covered && abs((viewer.loader.videoDuration(for: unselected) ?? 0) - 12) < 0.1,
              "Unselected duration is accurate without changing the selected file")
        check(spin({ viewer.loader.videoDuration(for: video) != nil })
              && abs((viewer.loader.videoDuration(for: video) ?? 0) - 12) < 0.1 && viewer.currentURL == covered,
              "Neighboring video obtains its actual duration alongside unselected audio")
        screenshot("audio-video-duration-badges.png", view: viewer.strip)
        check((viewer.buttons["mediaPlay"]?.frame.minY ?? 0) > viewer.strip.frame.maxY,
              "Independent audio transport stays above the file thumbnails")
        viewer.video?.pause(); screenshot("audio-album-cover.png")

        check(clickFile(waveform), "A real filmstrip click selects uncovered audio")
        check(spin({ ready(waveform) && viewer.video?.audioWaveform != nil }), "Uncovered audio obtains its sample-derived waveform in the viewer")
        check(viewer.video?.audioCover == nil && (viewer.video?.audioWaveform?.peaks.max() ?? 0) > 0.7,
              "Uncovered audio uses its real amplitude envelope")
        let displayedBytes = viewer.canvas.image?.dataProvider?.data
        let fallbackBytes = AudioArtwork.make(for: waveform)?.dataProvider?.data
        check(displayedBytes != nil && fallbackBytes != nil && (displayedBytes! as Data) != (fallbackBytes! as Data),
              "Rendered waveform replaces the loading music-note placeholder")
        viewer.video?.pause(); screenshot("audio-real-waveform.png")
        if let play = viewer.buttons["mediaPlay"], let stop = viewer.buttons["mediaStop"] {
            check(click(play) && spin({ viewer.video?.isPlaying == true }), "Independent audio play button starts playback")
            check(click(stop) && spin({ viewer.video?.isPlaying == false && (viewer.video?.currentTime ?? 99) < 0.05 }),
                  "Independent audio stop button pauses and returns to the beginning")
            check(!viewer.isPlaying, "Audio transport does not start slideshow playback")
        } else { check(false, "Independent audio controls exist") }

        var retired: [VideoSession] = []
        let switches = [covered, waveform, unselected, covered, waveform, unselected, covered, waveform, still]
        for (index, file) in switches.enumerated() {
            if let session = viewer.video { retired.append(session) }
            check(clickFile(file), "Rapid real thumbnail switch remains routable (\(index + 1)/\(switches.count))")
            spin({ false }, timeout: 0.012)
        }
        check(spin({ viewer.currentURL == still && viewer.loaded != nil && viewer.video == nil }), "Rapid audio switching finishes on the requested still image")
        let finalImage = viewer.canvas.image
        spin({ false }, timeout: 0.8)
        check(viewer.currentURL == still && viewer.canvas.image === finalImage, "Late audio cover/waveform callbacks do not overwrite the next file")
        check(retired.allSatisfy { !$0.isPlaying && $0.player.rate == 0 }, "Retired audio sessions remain stopped after rapid switching")
        check(viewer.window?.isVisible == true && !viewer.isClosing, "Viewer remains open after audio thumbnail switching")
        screenshot("audio-switch-final-photo.png")

        check(clickFile(waveform) && spin({ ready(waveform) && viewer.video?.audioWaveform != nil }), "Waveform view can be reopened after rapid switching")
        let closing = viewer.video
        viewer.closeViewer()
        check(spin({ viewer.window?.isVisible == false }, timeout: 3) && closing?.player.rate == 0,
              "Closing waveform playback stops audio and completes the viewer transition")
    } catch { check(false, "Unexpected audio visual test error: \(error)") }
    report.append("\n\(report.count - failures) passed, \(failures) failed")
    let text = report.joined(separator: "\n") + "\n"
    try? text.write(to: output.appendingPathComponent("audio-visual-test-results.txt"), atomically: true, encoding: .utf8)
    print(text); fflush(stdout)
    exit(failures == 0 ? 0 : 1)
}
