import AppKit
import AVFoundation
import QuartzCore

/// Additional opt-in integration tests. The regular video suite first creates
/// the native H.264/AAC fixture in the same output directory.
func runExtendedMediaSelfTests(_ viewer: ViewerController, output: URL) {
    var report: [String] = [], diagnostics: [String] = [], failures = 0
    func check(_ condition: @autoclosure () -> Bool, _ message: String) {
        let pass = condition()
        report.append("\(pass ? "PASS" : "FAIL") \(message)")
        if !pass {
            failures += 1
            diagnostics.append("\(message): URL=\(viewer.currentURL?.lastPathComponent ?? "nil"), audio=\(viewer.video?.isAudioOnly.description ?? "nil"), compatibility=\(viewer.video?.usedCompatibilityDecoder.description ?? "nil"), time=\(viewer.video?.currentTime ?? -1), detail=\(viewer.detailLabel.stringValue), toast=\(viewer.toast.stringValue)")
        }
    }
    @discardableResult
    func spin(_ condition: () -> Bool, timeout: TimeInterval = 12) -> Bool {
        let end = Date().addingTimeInterval(timeout)
        repeat {
            CATransaction.flush()
            if condition() { return true }
            RunLoop.main.run(until: Date().addingTimeInterval(0.025))
        } while Date() < end
        return condition()
    }
    func testError(_ message: String) -> NSError {
        NSError(domain: "LumaView.ExtendedMediaSelfTest", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }
    var commandIndex = 0
    func runBundled(_ tool: String, _ arguments: [String]) throws -> URL {
        guard let tools = Bundle.main.resourceURL?.appendingPathComponent("MediaTools"),
              FileManager.default.isExecutableFile(atPath: tools.appendingPathComponent(tool).path) else {
            throw testError("Bundled \(tool) is missing")
        }
        commandIndex += 1
        let log = output.appendingPathComponent("bundled-media-command-\(commandIndex).log")
        FileManager.default.createFile(atPath: log.path, contents: nil)
        let handle = try FileHandle(forWritingTo: log)
        let task = Process()
        task.executableURL = tools.appendingPathComponent(tool); task.arguments = arguments
        task.standardInput = FileHandle.nullDevice; task.standardOutput = handle; task.standardError = handle
        var finished = false, status: Int32 = -1, launchError: Error?
        DispatchQueue.global(qos: .utility).async {
            do {
                try task.run(); task.waitUntilExit()
                let result = task.terminationStatus
                DispatchQueue.main.async { status = result; finished = true }
            } catch { DispatchQueue.main.async { launchError = error; finished = true } }
        }
        let completed = spin({ finished }, timeout: 60)
        if !completed, task.isRunning { task.terminate() }
        try? handle.close()
        if let launchError { throw launchError }
        guard completed, status == 0 else {
            let details = (try? String(contentsOf: log, encoding: .utf8)) ?? ""
            throw testError("Bundled \(tool) failed (\(status)): \(details.suffix(1_024))")
        }
        return log
    }
    func playerLayer(_ layer: CALayer?) -> AVPlayerLayer? {
        guard let layer else { return nil }
        if let video = layer as? AVPlayerLayer, video.player === viewer.video?.player { return video }
        return layer.sublayers?.compactMap { playerLayer($0) }.first
    }
    func ready(_ url: URL) -> Bool {
        guard viewer.currentURL == url, let session = viewer.video, viewer.videoSeekSlider.isEnabled,
              viewer.canvas.hasMedia, viewer.window?.isVisible == true, !viewer.isClosing else { return false }
        if session.isAudioOnly { return viewer.canvas.image != nil }
        return playerLayer(viewer.canvas.layer)?.isReadyForDisplay == true
    }
    var eventNumber = 2_000
    func click(_ view: NSView, at point: NSPoint? = nil) -> Bool {
        guard let window = viewer.window, window.isVisible, !viewer.isClosing else { return false }
        viewer.revealChrome(); viewer.root.layoutSubtreeIfNeeded(); window.display(); CATransaction.flush()
        let location = view.convert(point ?? NSPoint(x: view.bounds.midX, y: view.bounds.midY), to: nil)
        let hit = viewer.root.hitTest(viewer.root.convert(location, from: nil))
        guard hit === view || hit?.isDescendant(of: view) == true else {
            diagnostics.append("Mouse target=\(type(of: view)); actual=\(String(describing: hit))")
            return false
        }
        eventNumber += 2
        let time = ProcessInfo.processInfo.systemUptime
        guard let down = NSEvent.mouseEvent(with: .leftMouseDown, location: location, modifierFlags: [], timestamp: time,
            windowNumber: window.windowNumber, context: nil, eventNumber: eventNumber, clickCount: 1, pressure: 1),
            let up = NSEvent.mouseEvent(with: .leftMouseUp, location: location, modifierFlags: [], timestamp: time + 0.01,
            windowNumber: window.windowNumber, context: nil, eventNumber: eventNumber + 1, clickCount: 1, pressure: 0) else { return false }
        NSApp.postEvent(up, atStart: true); window.sendEvent(down)
        while let event = NSApp.nextEvent(matching: .leftMouseUp, until: Date(), inMode: .default, dequeue: true) {
            if event.windowNumber == window.windowNumber { window.sendEvent(event) } else { NSApp.sendEvent(event) }
        }
        spin({ false }, timeout: 0.1)
        return true
    }
    func clickButton(_ name: String) -> Bool { viewer.buttons[name].map { click($0) } ?? false }
    func selectByThumbnail(_ url: URL) -> Bool {
        guard let index = viewer.items.firstIndex(where: { $0.url == url }) else { return false }
        let capacity = max(1, Int((viewer.strip.bounds.width - 24) / 72))
        let first = max(0, min(viewer.selectedIndex - capacity / 2, viewer.items.count - capacity))
        let count = min(capacity, viewer.items.count)
        guard index >= first, index < first + count else { return false }
        let point = NSPoint(x: (viewer.strip.bounds.width - CGFloat(count) * 72) / 2 + CGFloat(index - first) * 72 + 35, y: 35)
        return click(viewer.strip, at: point)
    }
    func screenshot(_ name: String) {
        CATransaction.flush(); viewer.window?.display()
        if let bitmap = viewer.root.bitmapImageRepForCachingDisplay(in: viewer.root.bounds) {
            viewer.root.cacheDisplay(in: viewer.root.bounds, to: bitmap)
            if let data = bitmap.representation(using: .png, properties: [:]) { try? data.write(to: output.appendingPathComponent(name)) }
        }
    }

    do {
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let fixtures = output.appendingPathComponent("extended-fixtures", isDirectory: true)
        try FileManager.default.createDirectory(at: fixtures, withIntermediateDirectories: true)
        let nativeVideo = fixtures.appendingPathComponent("01-native.mp4")
        let nativeAudio = fixtures.appendingPathComponent("02-native-audio.m4a")
        let still = fixtures.appendingPathComponent("03-photo.jpg")
        for (original, copy) in [("02-video.mp4", nativeVideo), ("01-photo.jpg", still)] {
            let source = output.appendingPathComponent("fixtures").appendingPathComponent(original)
            guard FileManager.default.fileExists(atPath: source.path) else { throw testError("Run --video-self-test before this suite to create \(original)") }
            try? FileManager.default.removeItem(at: copy); try FileManager.default.copyItem(at: source, to: copy)
        }
        for (name, contents) in extendedMediaFixtures {
            guard let bytes = Data(base64Encoded: contents, options: .ignoreUnknownCharacters) else { throw testError("Invalid embedded fixture \(name)") }
            try bytes.write(to: fixtures.appendingPathComponent(name), options: .atomic)
        }
        check(ProcessInfo.processInfo.environment["LUMAVIEW_MEDIA_TOOLS"] == nil,
              "Integration uses bundled media tools without a development override")
        let versionLog = try runBundled("ffmpeg", ["-version"])
        let version = try String(contentsOf: versionLog, encoding: .utf8)
        check(version.contains("ffmpeg version") && !version.contains("--enable-gpl"), "Bundled FFmpeg starts with the expected non-GPL build")
        diagnostics.append(String(version.split(separator: "\n").first ?? ""))
        let nativeArguments = ["-hide_banner", "-loglevel", "error", "-nostdin", "-protocol_whitelist", "file,pipe", "-i", nativeVideo.path]
        _ = try runBundled("ffmpeg", nativeArguments + ["-vn", "-c:a", "copy", "-y", nativeAudio.path])
        let remux = fixtures.appendingPathComponent("04-remux.mkv")
        _ = try runBundled("ffmpeg", nativeArguments + ["-c", "copy", "-y", remux.path])
        let codecFixtures = [
            ("04-remux.mkv", "h264"), ("05-ffv1.avi", "ffv1"),
            ("06-vp9.webm", "vp9"), ("07-av1.mkv", "av1"), ("08-opus.ogg", "opus")
        ]
        for (name, codec) in codecFixtures {
            let source = fixtures.appendingPathComponent(name)
            let probeLog = try runBundled("ffprobe", ["-v", "error", "-protocol_whitelist", "file,pipe", "-show_entries", "stream=codec_name", "-of", "json", source.path])
            let probe = try JSONSerialization.jsonObject(with: Data(contentsOf: probeLog)) as? [String: Any]
            let streams = probe?["streams"] as? [[String: Any]] ?? []
            check(streams.contains { $0["codec_name"] as? String == codec }, "Bundled ffprobe recognizes the \(codec.uppercased()) fixture")
            // Force this run through the bundled decoder even on a Mac that can
            // open the source natively or that already has a production cache.
            let cache = output.appendingPathComponent("compatibility-check-\(codec)-\(UUID().uuidString)")
            let job = CompatibilityMedia(sourceURL: source, cacheDirectory: cache)
            var conversion: Result<CompatibilityMedia.Prepared, Error>?
            Task { @MainActor in
                do { conversion = .success(try await job.prepare { _ in }) }
                catch { conversion = .failure(error) }
            }
            let finished = spin({ conversion != nil }, timeout: 90)
            if !finished { job.cancel() }
            if case .success(let result) = conversion {
                check(result.information.isAudioOnly == (codec == "opus"), "Bundled \(codec.uppercased()) conversion preserves audio/video classification")
                if codec == "h264" { check(result.playbackURL.lastPathComponent.contains("remux"), "H.264 MKV uses a lossless container remux") }
                let session = VideoSession(url: result.playbackURL)
                var prepared: Result<VideoSession, Error>?
                session.prepare { prepared = $0 }
                _ = spin({ prepared != nil }, timeout: 30)
                if case .success = prepared { check(session.duration > 5.5, "Bundled \(codec.uppercased()) output prepares for native playback") }
                else { check(false, "Bundled \(codec.uppercased()) output prepares for native playback"); diagnostics.append(String(describing: prepared)) }
                session.dispose()
            } else {
                check(false, "Bundled \(codec.uppercased()) conversion completes")
                diagnostics.append("\(codec) conversion: \(String(describing: conversion))")
            }
            job.cancel(); try? FileManager.default.removeItem(at: cache)
        }

        // A sparse 9 GB test output takes almost no physical disk space. The
        // mock emits no progress ticks, reproducing a fast final write that the
        // periodic size check cannot catch. Real decoder tests above stay bundled.
        let limitRoot = output.appendingPathComponent("cache-limit-check-\(UUID().uuidString)")
        let mockTools = limitRoot.appendingPathComponent("tools"), limitCache = limitRoot.appendingPathComponent("cache")
        try FileManager.default.createDirectory(at: mockTools, withIntermediateDirectories: true)
        let mockProbe = """
        #!/bin/sh
        printf '%s\\n' '{"streams":[{"index":0,"codec_type":"video","codec_name":"ffv1","width":96,"height":64}],"format":{"duration":"6"}}'
        """
        let mockEncoder = """
        #!/bin/sh
        for media_output in "$@"; do :; done
        /usr/sbin/mkfile -n 9g "$media_output"
        """
        for (name, contents) in [("ffprobe", mockProbe), ("ffmpeg", mockEncoder)] {
            let file = mockTools.appendingPathComponent(name)
            try (contents + "\n").write(to: file, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: file.path)
        }
        let oversized = CompatibilityMedia(sourceURL: nativeVideo, cacheDirectory: limitCache, toolsDirectory: mockTools)
        var sizeResult: Result<CompatibilityMedia.Prepared, Error>?
        Task { @MainActor in
            do { sizeResult = .success(try await oversized.prepare { _ in }) }
            catch { sizeResult = .failure(error) }
        }
        _ = spin({ sizeResult != nil }, timeout: 30)
        var rejectedSize = false
        if case .failure(let error) = sizeResult, case CompatibilityMediaError.insufficientSpace = error { rejectedSize = true }
        check(rejectedSize, "Completed output exceeding 8 GB is rejected even without progress ticks")
        let limitFiles = (try? FileManager.default.contentsOfDirectory(atPath: limitCache.path)) ?? []
        check(limitFiles.isEmpty, "Rejected oversized conversion leaves no cache or partial output")
        oversized.cancel(); try? FileManager.default.removeItem(at: limitRoot)

        viewer.window?.setContentSize(NSSize(width: 1100, height: 760))
        viewer.showFilmstrip = true; viewer.sort = .name; viewer.looping = true; viewer.closeOnBackground = true
        viewer.open([nativeVideo])
        check(spin { ready(nativeVideo) && viewer.video?.usedCompatibilityDecoder == false },
              "Native video is ready before exercising the first-frame retry path")
        let originalLayer = playerLayer(viewer.canvas.layer), originalPlayer = viewer.video?.player
        // Starting after ready intentionally consumes the old observation before
        // reattachment, the same ordering that made a late readiness event race.
        viewer.retryCurrentMediaWithCompatibility()
        check(originalLayer?.player == nil && playerLayer(viewer.canvas.layer) == nil && !viewer.videoSeekSlider.isEnabled,
              "First-frame retry detaches the old layer and disables unprepared controls")
        check(spin({ ready(nativeVideo) && viewer.video?.usedCompatibilityDecoder == true }, timeout: 90)
              && viewer.video?.player === originalPlayer && playerLayer(viewer.canvas.layer) !== originalLayer,
              "First-frame retry reuses the session with a fresh ready player layer")
        let retryURL = (viewer.video?.player.currentItem?.asset as? AVURLAsset)?.url
        check(retryURL != nativeVideo && retryURL?.lastPathComponent.contains("remux") == false,
              "A first-frame failure forces re-encoding instead of copying the same unsupported bitstream")
        viewer.video?.pause()
        viewer.open([nativeAudio])
        check(spin { ready(nativeAudio) }, "Native AAC audio opens with a visible audio card")
        check(viewer.video?.isAudioOnly == true && playerLayer(viewer.canvas.layer) == nil,
              "Audio playback uses the card without a waiting video layer")
        check(viewer.items.count == 8 && viewer.items.contains { $0.url == still }, "Folder scan includes images, videos, and audio together")
        viewer.video?.pause()
        check(clickButton("mediaPlay") && spin { viewer.video?.isPlaying == true && (viewer.video?.currentTime ?? 0) > 0.15 }
              && !viewer.isPlaying, "Real audio play click advances time without starting slideshow")
        check(clickButton("mediaPlay") && viewer.video?.player.rate == 0, "Real audio pause click stops the player")
        viewer.video?.seek(to: 2)
        spin { (viewer.video?.currentTime ?? 0) > 1.8 }
        check(clickButton("mediaStop") && spin { (viewer.video?.currentTime ?? 99) < 0.1 && viewer.video?.player.rate == 0 },
              "Real audio stop click pauses and rewinds to zero")
        check(clickButton("play") && viewer.isPlaying && viewer.video?.isPlaying == true,
              "Audio supports the separate continuous-playback action")
        check(clickButton("mediaPlay") && viewer.video?.player.rate == 0 && viewer.isPlaying,
              "Audio pause does not change the slideshow setting")
        check(clickButton("mediaStop") && spin { (viewer.video?.currentTime ?? 99) < 0.1 } && viewer.isPlaying,
              "Audio stop does not change the slideshow setting")
        _ = clickButton("play")
        check(viewer.videoSeekSlider.frame.minY > viewer.strip.frame.maxY, "Audio transport remains above the thumbnail strip")
        check(clickButton("info") && spin { !viewer.infoPanel.isHidden }, "Audio information panel opens")
        check(viewer.infoText.stringValue.contains("音频") && viewer.infoText.stringValue.contains("时长"), "Audio information identifies its type and duration")
        check(click(viewer.infoText, at: NSPoint(x: 20, y: viewer.infoText.bounds.height - 55)) && !viewer.isClosing,
              "Selecting audio metadata text keeps the viewer open")
        _ = clickButton("closeInfo")
        screenshot("extended-audio-controls.png")
        let oldAudio = viewer.video?.player
        check(selectByThumbnail(still) && spin { viewer.currentURL == still && viewer.loaded != nil && viewer.video == nil },
              "Real thumbnail click switches from audio to an image")
        check(oldAudio?.rate == 0 && viewer.videoSeekSlider.isHidden && viewer.buttons["mediaPlay"]?.isHidden == true,
              "Audio-to-image switch stops the old audio and hides transport controls")

        for (name, _) in codecFixtures {
            let source = fixtures.appendingPathComponent(name)
            check(selectByThumbnail(source) && spin({ ready(source) }, timeout: 90), "Real thumbnail click opens \(name) through the viewer")
            if ready(source) {
                viewer.video?.pause()
                check(viewer.video?.url == source && (viewer.video?.duration ?? 0) > 5.5,
                      "Viewer retains the original URL and full duration for \(name)")
                if name == "08-opus.ogg" { check(viewer.video?.isAudioOnly == true, "OGG/Opus opens as playable audio") }
                else { check(playerLayer(viewer.canvas.layer)?.isReadyForDisplay == true, "Decoded \(name) reaches a real AVPlayerLayer frame") }
            }
        }
        let source = fixtures.appendingPathComponent("05-ffv1.avi")
        _ = selectByThumbnail(source); _ = spin({ ready(source) }, timeout: 90)
        viewer.video?.pause(); screenshot("extended-compatible-video.png")
        let previousPlayer = viewer.video?.player
        viewer.closeViewer()
        check(previousPlayer?.rate == 0 && spin({ viewer.window?.isVisible == false }, timeout: 3),
              "Closing compatible media stops playback and finishes the window transition")
    } catch { check(false, "Unexpected extended media error: \(error)") }
    report.append("\n\(report.count - failures) passed, \(failures) failed")
    let text = (report + diagnostics).joined(separator: "\n") + "\n"
    try? text.write(to: output.appendingPathComponent("extended-media-test-results.txt"), atomically: true, encoding: .utf8)
    print(text); fflush(stdout)
    exit(failures == 0 ? 0 : 1)
}

// Tiny silent fixtures generated specifically for these tests. Embedding them
// makes decoding tests independent of Homebrew and optional encoder libraries.
private let extendedMediaFixtures: [String: String] = [
    "05-ffv1.avi": """
    UklGRlQ6AABBVkkgTElTVGISAABoZHJsYXZpaDgAAABI6AEAqGEAAAAAAAAQCQAAMAAAAAAAAAABAAAAAAAQAGAAAABAAAAAAAAA
    AAAAAAAAAAAAAAAAAExJU1QKEQAAc3RybHN0cmg4AAAAdmlkc0ZGVjEAAAAAAAAAAAAAAAABAAAACAAAAAAAAAAwAAAAuAAAAP//
    //8AAAAAAAAAAGAAQABzdHJmUgAAAFIAAABgAAAAQAAAAAEAGABGRlYxAEgAAAAAAAAAAAAAAAAAAAAAAABWK4TRnAUvQTxgJulc
    N29dG3aXnTrJxCBDHoufVSBRL074oWg7mxcTfANKVU5LGBAAAAQAAAAAAAAAMDBkYwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB2cHJwRAAAAAAAAAAAAAAACAAAAGAAAABAAAAAAgADAGAAAABAAAAAAQAA
    AEAAAABgAAAAQAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAASlVOSwQBAABvZG1sZG1saPgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AExJU1QaAAAASU5GT0lTRlQNAAAATGF2ZjYzLjEuMTAxAABKVU5L+AMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAATElTVLQgAABtb3ZpMDBkY7gAAAD8FYAABpyv//////+f///////4ADKlf//8/////wkf///v////8AAAJgBMlwW0
    Pd6AAAacr///////n///////+AAypX///P////8JH///7/////AAACYAlVH8/JwckwAGnK///////5////////gAMqV///z/////
    CR///+/////wAAAmAH2RsxYQvz0ABpyv//////+f///////4ADKlf//8/////wkf///v////8AAAJgBjKZIrMDBkY6gAAAB8lYAL
    n///////7////////NX///9/////mT/////////gAAAiAGVgtC093oALn///////7////////NX///9/////mT/////////gAAAi
    AIlZBamcHJMLn///////7////////NX///9/////mT/////////gAAAiAF5mjMMQvz0Ln///////7////////NX///9/////mT//
    ///////gAAAiACK/kuwwMGRjqAAAAHyVgDa////////f///////5q/////////5k/////////4AAACIAYc8rtz3egDa////////f
    ///////5q/////////5k/////////4AAACIAjfaaM5wckza////////f///////5q/////////5k/////////4AAACIAWskTWRC/
    PTa////////f///////5q/////////5k/////////4AAACIAJhANdjAwZGOkAAAAfJWANj////////////////NX/////////Mn/
    ////////AAAhABuRgqM93oA2P///////////////81f////////8yf////////8AACEAN9CUP5wckzY////////////////zV///
    //////zJ/////////wAAIQCbw4h7EL89Nj////////////////NX/////////Mn/////////AAAhAPM1/E4wMGRjpAAAAHyVgDW/
    ///////////////zV/////////zJ/////////wAAIQB/LVXJPd6ANb////////////////NX/////////Mn/////////AAAhAFNs
    Q1WcHJM1v///////////////81f////////8yf////////8AACEA/39fERC/PTW////////////////zV/////////zJ////////
    /wAAIQCXiSskMDBkY6QAAAB8lYA1P///////////////81f////////8yf////////8AACEAsCQapT3egDU////////////////z
    V/////////zJ/////////wAAIQCcZQw5nByTNT////////////////NX/////////Mn/////////AAAhADB2EH0Qvz01P///////
    ////////81f////////8yf////////8AACEAWIBkSDAwZGOkAAAAfJWANL////////////////NX/////////Mn/////////AAAh
    AOX+1qY93oA0v///////////////81f////////8yf////////8AACEAyb/AOpwckzS////////////////zV/////////zJ////
    /////wAAIQBlrNx+EL89NL////////////////NX/////////Mn/////////AAAhAA1aqEswMGRjpAAAAHyVgDQ/////////////
    ///zV/////////zJ/////////wAAIQAq95nKPd6AND////////////////NX/////////Mn/////////AAAhAAa2j1acHJM0P///
    ////////////81f////////8yf////////8AACEAqqWTEhC/PTQ////////////////zV/////////zJ/////////wAAIQDCU+cn
    MDBkY6QAAAB8lYAzv///////////////81f////////8yf////////8AACEALId4cj3egDO////////////////zV/////////zJ
    /////////wAAIQAAxm7unByTM7////////////////NX/////////Mn/////////AAAhAKzVcqoQvz0zv///////////////81f/
    ///////8yf////////8AACEAxCMGnzAwZGOkAAAAfJWAMz////////////////NX/////////Mn/////////AAAhAOOONx493oAz
    P///////////////81f////////8yf////////8AACEAz88hgpwckzM////////////////zV/////////zJ/////////wAAIQBj
    3D3GEL89Mz////////////////NX/////////Mn/////////AAAhAAsqSfMwMGRjpAAAAHyVgDK////////////////zV///////
    //zJ/////////wAAIQC2VPsdPd6AMr////////////////NX/////////Mn/////////AAAhAJoV7YGcHJMyv///////////////
    81f////////8yf////////8AACEANgbxxRC/PTK////////////////zV/////////zJ/////////wAAIQBe8IXwMDBkY6QAAAB8
    lYAyP///////////////81f////////8yf////////8AACEAeV20cT3egDI////////////////zV/////////zJ/////////wAA
    IQBVHKLtnByTMj////////////////NX/////////Mn/////////AAAhAPkPvqkQvz0yP///////////////81f////////8yf//
    //////8AACEAkfnKnDAwZGO4AAAA/BWAAAacr///////n///////+AAypX///P////8JH///7/////AAACYATJcFtD3egAAGnK//
    /////5////////gAMqV///z/////CR///+/////wAAAmAJVR/PycHJMABpyv//////+f///////4ADKlf//8/////wkf///v////
    8AAAJgB9kbMWEL89AAacr///////n///////+AAypX///P////8JH///7/////AAACYAYymSKzAwZGOoAAAAfJWAC5///////+//
    //////zV////f////5k/////////4AAAIgBlYLQtPd6AC5///////+////////zV////f////5k/////////4AAAIgCJWQWpnByT
    C5///////+////////zV////f////5k/////////4AAAIgBeZozDEL89C5///////+////////zV////f////5k/////////4AAA
    IgAiv5LsMDBkY6gAAAB8lYA2v///////3///////+av////////+ZP////////+AAAAiAGHPK7c93oA2v///////3///////+av/
    ///////+ZP////////+AAAAiAI32mjOcHJM2v///////3///////+av////////+ZP////////+AAAAiAFrJE1kQvz02v///////
    3///////+av////////+ZP////////+AAAAiACYQDXYwMGRjpAAAAHyVgDY////////////////zV/////////zJ/////////wAA
    IQAbkYKjPd6ANj////////////////NX/////////Mn/////////AAAhADfQlD+cHJM2P///////////////81f////////8yf//
    //////8AACEAm8OIexC/PTY////////////////zV/////////zJ/////////wAAIQDzNfxOMDBkY6QAAAB8lYA1v///////////
    ////81f////////8yf////////8AACEAfy1VyT3egDW////////////////zV/////////zJ/////////wAAIQBTbENVnByTNb//
    //////////////NX/////////Mn/////////AAAhAP9/XxEQvz01v///////////////81f////////8yf////////8AACEAl4kr
    JDAwZGOkAAAAfJWANT////////////////NX/////////Mn/////////AAAhALAkGqU93oA1P///////////////81f////////8
    yf////////8AACEAnGUMOZwckzU////////////////zV/////////zJ/////////wAAIQAwdhB9EL89NT////////////////NX
    /////////Mn/////////AAAhAFiAZEgwMGRjpAAAAHyVgDS////////////////zV/////////zJ/////////wAAIQDl/tamPd6A
    NL////////////////NX/////////Mn/////////AAAhAMm/wDqcHJM0v///////////////81f////////8yf////////8AACEA
    ZazcfhC/PTS////////////////zV/////////zJ/////////wAAIQANWqhLMDBkY6QAAAB8lYA0P///////////////81f/////
    ///8yf////////8AACEAKveZyj3egDQ////////////////zV/////////zJ/////////wAAIQAGto9WnByTND//////////////
    //NX/////////Mn/////////AAAhAKqlkxIQvz00P///////////////81f////////8yf////////8AACEAwlPnJzAwZGOkAAAA
    fJWAM7////////////////NX/////////Mn/////////AAAhACyHeHI93oAzv///////////////81f////////8yf////////8A
    ACEAAMZu7pwckzO////////////////zV/////////zJ/////////wAAIQCs1XKqEL89M7////////////////NX/////////Mn/
    ////////AAAhAMQjBp8wMGRjpAAAAHyVgDM////////////////zV/////////zJ/////////wAAIQDjjjcePd6AMz//////////
    //////NX/////////Mn/////////AAAhAM/PIYKcHJMzP///////////////81f////////8yf////////8AACEAY9w9xhC/PTM/
    ///////////////zV/////////zJ/////////wAAIQALKknzMDBkY6QAAAB8lYAyv///////////////81f////////8yf//////
    //8AACEAtlT7HT3egDK////////////////zV/////////zJ/////////wAAIQCaFe2BnByTMr////////////////NX////////
    /Mn/////////AAAhADYG8cUQvz0yv///////////////81f////////8yf////////8AACEAXvCF8DAwZGOkAAAAfJWAMj//////
    //////////NX/////////Mn/////////AAAhAHldtHE93oAyP///////////////81f////////8yf////////8AACEAVRyi7Zwc
    kzI////////////////zV/////////zJ/////////wAAIQD5D76pEL89Mj////////////////NX/////////Mn/////////AAAh
    AJH5ypwwMGRjuAAAAPwVgAAGnK///////5////////gAMqV///z/////CR///+/////wAAAmAEyXBbQ93oAABpyv//////+f////
    ///4ADKlf//8/////wkf///v////8AAAJgCVUfz8nByTAAacr///////n///////+AAypX///P////8JH///7/////AAACYAfZGz
    FhC/PQAGnK///////5////////gAMqV///z/////CR///+/////wAAAmAGMpkiswMGRjqAAAAHyVgAuf///////v///////81f//
    /3////+ZP////////+AAACIAZWC0LT3egAuf///////v///////81f///3////+ZP////////+AAACIAiVkFqZwckwuf///////v
    ///////81f///3////+ZP////////+AAACIAXmaMwxC/PQuf///////v///////81f///3////+ZP////////+AAACIAIr+S7DAw
    ZGOoAAAAfJWANr///////9////////mr/////////mT/////////gAAAIgBhzyu3Pd6ANr///////9////////mr/////////mT/
    ////////gAAAIgCN9poznByTNr///////9////////mr/////////mT/////////gAAAIgBayRNZEL89Nr///////9////////mr
    /////////mT/////////gAAAIgAmEA12MDBkY6QAAAB8lYA2P///////////////81f////////8yf////////8AACEAG5GCoz3e
    gDY////////////////zV/////////zJ/////////wAAIQA30JQ/nByTNj////////////////NX/////////Mn/////////AAAh
    AJvDiHsQvz02P///////////////81f////////8yf////////8AACEA8zX8TjAwZGOkAAAAfJWANb////////////////NX////
    /////Mn/////////AAAhAH8tVck93oA1v///////////////81f////////8yf////////8AACEAU2xDVZwckzW/////////////
    ///zV/////////zJ/////////wAAIQD/f18REL89Nb////////////////NX/////////Mn/////////AAAhAJeJKyQwMGRjpAAA
    AHyVgDU////////////////zV/////////zJ/////////wAAIQCwJBqlPd6ANT////////////////NX/////////Mn/////////
    AAAhAJxlDDmcHJM1P///////////////81f////////8yf////////8AACEAMHYQfRC/PTU////////////////zV/////////zJ
    /////////wAAIQBYgGRIMDBkY6QAAAB8lYA0v///////////////81f////////8yf////////8AACEA5f7Wpj3egDS/////////
    ///////zV/////////zJ/////////wAAIQDJv8A6nByTNL////////////////NX/////////Mn/////////AAAhAGWs3H4Qvz00
    v///////////////81f////////8yf////////8AACEADVqoSzAwZGOkAAAAfJWAND////////////////NX/////////Mn/////
    ////AAAhACr3mco93oA0P///////////////81f////////8yf////////8AACEABraPVpwckzQ////////////////zV///////
    //zJ/////////wAAIQCqpZMSEL89ND////////////////NX/////////Mn/////////AAAhAMJT5ycwMGRjpAAAAHyVgDO/////
    ///////////zV/////////zJ/////////wAAIQAsh3hyPd6AM7////////////////NX/////////Mn/////////AAAhAADGbu6c
    HJMzv///////////////81f////////8yf////////8AACEArNVyqhC/PTO////////////////zV/////////zJ/////////wAA
    IQDEIwafMDBkY6QAAAB8lYAzP///////////////81f////////8yf////////8AACEA4443Hj3egDM////////////////zV///
    //////zJ/////////wAAIQDPzyGCnByTMz////////////////NX/////////Mn/////////AAAhAGPcPcYQvz0zP///////////
    ////81f////////8yf////////8AACEACypJ8zAwZGOkAAAAfJWAMr////////////////NX/////////Mn/////////AAAhALZU
    +x093oAyv///////////////81f////////8yf////////8AACEAmhXtgZwckzK////////////////zV/////////zJ////////
    /wAAIQA2BvHFEL89Mr////////////////NX/////////Mn/////////AAAhAF7whfAwMGRjpAAAAHyVgDI////////////////z
    V/////////zJ/////////wAAIQB5XbRxPd6AMj////////////////NX/////////Mn/////////AAAhAFUcou2cHJMyP///////
    ////////81f////////8yf////////8AACEA+Q++qRC/PTI////////////////zV/////////zJ/////////wAAIQCR+cqcMDBk
    Y7gAAAD8FYAABpyv//////+f///////4ADKlf//8/////wkf///v////8AAAJgBMlwW0Pd6AAAacr///////n///////+AAypX//
    /P////8JH///7/////AAACYAlVH8/JwckwAGnK///////5////////gAMqV///z/////CR///+/////wAAAmAH2RsxYQvz0ABpyv
    //////+f///////4ADKlf//8/////wkf///v////8AAAJgBjKZIrMDBkY6gAAAB8lYALn///////7////////NX///9/////mT//
    ///////gAAAiAGVgtC093oALn///////7////////NX///9/////mT/////////gAAAiAIlZBamcHJMLn///////7////////NX/
    //9/////mT/////////gAAAiAF5mjMMQvz0Ln///////7////////NX///9/////mT/////////gAAAiACK/kuwwMGRjqAAAAHyV
    gDa////////f///////5q/////////5k/////////4AAACIAYc8rtz3egDa////////f///////5q/////////5k/////////4AA
    ACIAjfaaM5wckza////////f///////5q/////////5k/////////4AAACIAWskTWRC/PTa////////f///////5q/////////5k
    /////////4AAACIAJhANdjAwZGOkAAAAfJWANj////////////////NX/////////Mn/////////AAAhABuRgqM93oA2P///////
    ////////81f////////8yf////////8AACEAN9CUP5wckzY////////////////zV/////////zJ/////////wAAIQCbw4h7EL89
    Nj////////////////NX/////////Mn/////////AAAhAPM1/E4wMGRjpAAAAHyVgDW////////////////zV/////////zJ////
    /////wAAIQB/LVXJPd6ANb////////////////NX/////////Mn/////////AAAhAFNsQ1WcHJM1v///////////////81f/////
    ///8yf////////8AACEA/39fERC/PTW////////////////zV/////////zJ/////////wAAIQCXiSskMDBkY6QAAAB8lYA1P///
    ////////////81f////////8yf////////8AACEAsCQapT3egDU////////////////zV/////////zJ/////////wAAIQCcZQw5
    nByTNT////////////////NX/////////Mn/////////AAAhADB2EH0Qvz01P///////////////81f////////8yf////////8A
    ACEAWIBkSDAwZGOkAAAAfJWANL////////////////NX/////////Mn/////////AAAhAOX+1qY93oA0v///////////////81f/
    ///////8yf////////8AACEAyb/AOpwckzS////////////////zV/////////zJ/////////wAAIQBlrNx+EL89NL//////////
    //////NX/////////Mn/////////AAAhAA1aqEswMGRjpAAAAHyVgDQ////////////////zV/////////zJ/////////wAAIQAq
    95nKPd6AND////////////////NX/////////Mn/////////AAAhAAa2j1acHJM0P///////////////81f////////8yf//////
    //8AACEAqqWTEhC/PTQ////////////////zV/////////zJ/////////wAAIQDCU+cnMDBkY6QAAAB8lYAzv///////////////
    81f////////8yf////////8AACEALId4cj3egDO////////////////zV/////////zJ/////////wAAIQAAxm7unByTM7//////
    //////////NX/////////Mn/////////AAAhAKzVcqoQvz0zv///////////////81f////////8yf////////8AACEAxCMGnzAw
    ZGOkAAAAfJWAMz////////////////NX/////////Mn/////////AAAhAOOONx493oAzP///////////////81f////////8yf//
    //////8AACEAz88hgpwckzM////////////////zV/////////zJ/////////wAAIQBj3D3GEL89Mz////////////////NX////
    /////Mn/////////AAAhAAsqSfMwMGRjpAAAAHyVgDK////////////////zV/////////zJ/////////wAAIQC2VPsdPd6AMr//
    //////////////NX/////////Mn/////////AAAhAJoV7YGcHJMyv///////////////81f////////8yf////////8AACEANgbx
    xRC/PTK////////////////zV/////////zJ/////////wAAIQBe8IXwMDBkY6QAAAB8lYAyP///////////////81f////////8
    yf////////8AACEAeV20cT3egDI////////////////zV/////////zJ/////////wAAIQBVHKLtnByTMj////////////////NX
    /////////Mn/////////AAAhAPkPvqkQvz0yP///////////////81f////////8yf////////8AACEAkfnKnGlkeDEAAwAAMDBk
    YxAAAAAEAAAAuAAAADAwZGMAAAAAxAAAAKgAAAAwMGRjAAAAAHQBAACoAAAAMDBkYwAAAAAkAgAApAAAADAwZGMAAAAA0AIAAKQA
    AAAwMGRjAAAAAHwDAACkAAAAMDBkYwAAAAAoBAAApAAAADAwZGMAAAAA1AQAAKQAAAAwMGRjAAAAAIAFAACkAAAAMDBkYwAAAAAs
    BgAApAAAADAwZGMAAAAA2AYAAKQAAAAwMGRjAAAAAIQHAACkAAAAMDBkYxAAAAAwCAAAuAAAADAwZGMAAAAA8AgAAKgAAAAwMGRj
    AAAAAKAJAACoAAAAMDBkYwAAAABQCgAApAAAADAwZGMAAAAA/AoAAKQAAAAwMGRjAAAAAKgLAACkAAAAMDBkYwAAAABUDAAApAAA
    ADAwZGMAAAAAAA0AAKQAAAAwMGRjAAAAAKwNAACkAAAAMDBkYwAAAABYDgAApAAAADAwZGMAAAAABA8AAKQAAAAwMGRjAAAAALAP
    AACkAAAAMDBkYxAAAABcEAAAuAAAADAwZGMAAAAAHBEAAKgAAAAwMGRjAAAAAMwRAACoAAAAMDBkYwAAAAB8EgAApAAAADAwZGMA
    AAAAKBMAAKQAAAAwMGRjAAAAANQTAACkAAAAMDBkYwAAAACAFAAApAAAADAwZGMAAAAALBUAAKQAAAAwMGRjAAAAANgVAACkAAAA
    MDBkYwAAAACEFgAApAAAADAwZGMAAAAAMBcAAKQAAAAwMGRjAAAAANwXAACkAAAAMDBkYxAAAACIGAAAuAAAADAwZGMAAAAASBkA
    AKgAAAAwMGRjAAAAAPgZAACoAAAAMDBkYwAAAACoGgAApAAAADAwZGMAAAAAVBsAAKQAAAAwMGRjAAAAAAAcAACkAAAAMDBkYwAA
    AACsHAAApAAAADAwZGMAAAAAWB0AAKQAAAAwMGRjAAAAAAQeAACkAAAAMDBkYwAAAACwHgAApAAAADAwZGMAAAAAXB8AAKQAAAAw
    MGRjAAAAAAggAACkAAAA
    """,
    "06-vp9.webm": """
    GkXfo59ChoEBQveBAULygQRC84EIQoKEd2VibUKHgQJChYECGFOAZwEAAAAAAAYKEU2bdLpNu4tTq4QVSalmU6yBoU27i1OrhBZU
    rmtTrIHWTbuMU6uEElTDZ1OsggEyTbuMU6uEHFO7a1OsggX07AEAAAAAAABZAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAVSalmsCrXsYMPQkBNgIxM
    YXZmNjMuMS4xMDFXQYxMYXZmNjMuMS4xMDFEiYhAt3AAAAAAABZUrmvXrgEAAAAAAABO14EBc8WI8oOb3JxXIyicgQAitZyDdW5k
    iIEAhoVWX1ZQOYOBASPjg4QHc1lA4JCwgWC6gUCagQJVsIRVuYEBVe6BAOwBAAAAAAAAAgAAElTDZ/5zc59jwIBnyJlFo4dFTkNP
    REVSRIeMTGF2ZjYzLjEuMTAxc3PZY8CLY8WI8oOb3JxXIyhnyKRFo4dFTkNPREVSRIeXTGF2YzYzLjEuMTAxIGxpYnZweC12cDln
    yKFFo4hEVVJBVElPTkSHkzAwOjAwOjA2LjAwMDAwMDAwMAAfQ7Z1Q5zngQCjrIEAAICCSYNCAAXwA/YAOCQcGEIAADBgAAB4uf2y
    v///6cD///8uA5+l05kAo5SBAH0AhgBAkpwASUAAAyAAAFj2AKOUgQD6AIYAQJKcAErAAAMgAABY9gCjlIEBdwCGAECSnABJwAAD
    IAAAWPYAo5SBAfQAhgBAkpwASKAAAyAAAFj2AKOUgQJxAIYAQJKcAEeAAAMgAABY9gCjlIEC7gCGAECSnABG4AADIAAAWPYAo5SB
    A2sAhgBAkpwARkAAAyAAAFj2AKOUgQPoAIYAQJKcAEXAAAMgAABY9gCjlIEEZQCGAECSnABFQAADIAAAWPYAo5SBBOIAhgDAkpwA
    QQAAAyAAAFj2AKOUgQVfAIYAQJKcAETgAAMgAABY9gCjlIEF3ACGAECSnABEYAADIAAAWPYAo5SBBlkAhgBAkpwARAAAAyAAAFj2
    AKOUgQbWAIYAQJKcAEOgAAMgAABY9gCjlIEHUwCGAECSnABDQAADIAAAWPYAo5SBB9AAhgBAkpwAQwAAAyAAAFj2AKOUgQhNAIYA
    QJKcAELAAAMgAABY9gCjlIEIygCGAECSnABCgAADIAAAWPYAo5SBCUcAhgBAkpwAQkAAAyAAAFj2AKOTgQnEAIYAwJKcAEAAAAIA
    AFj2AKOUgQpBAIYAQJKcAEIAAAMgAABY9gCjlIEKvgCGAECSnABB4AADIAAAWPYAo5SBCzsAhgBAkpwAQcAAAyAAAFj2AKOUgQu4
    AIYAQJKcAEGAAAMgAABY9gCjlIEMNQCGAECSnABBYAADIAAAWPYAo5SBDLIAhgBAkpwAQSAAAyAAAFj2AKOUgQ0vAIYAQJKcAEEA
    AAMgAABY9gCjlIENrACGAECSnABA4AADIAAAWPYAo5SBDikAhgBAkpwAQOAAAyAAAFj2AKOTgQ6mAIYAwJKcAEAAAAIAAFj2AKOU
    gQ8jAIYAQJKcAEDAAAMgAABY9gCjlIEPoACGAECSnABAoAADIAAAWPYAo5SBEB0AhgBAkpwAQKAAAyAAAFj2AKOUgRCaAIYAQJKc
    AECAAAMgAABY9gCjlIERFwCGAECSnABAYAADIAAAWPYAo5SBEZQAhgBAkpwAQGAAAyAAAFj2AKOUgRIRAIYAQJKcAEBAAAMgAABY
    9gCjk4ESjgCGAECSnABAAAACAABY9gCjk4ETCwCGAECSnABAAAACAABY9gCjk4ETiACGAMCSnABAAAACAABY9gAfQ7Z1QJfnghQF
    o5OBAAAAhgBAkpwAQAAAAgAAWPYAo5OBAH0AhgBAkpwAQAAAAgAAWPYAo5OBAPoAhgBAkpwAQAAAAgAAWPYAo5OBAXcAhgBAkpwA
    QAAAAgAAWPYAo5OBAfQAhgBAkpwAQAAAAgAAWPYAo5OBAnEAhgBAkpwAQAAAAgAAWPYAo5OBAu4AhgBAkpwAQAAAAgAAWPYAHFO7
    a5G7j7OBALeK94EB8YIBtfCBAw==
    """,
    "07-av1.mkv": """
    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
    MA67j7OBALeK94EB8YIB7vCBCQ==
    """,
    "08-opus.ogg": """
    T2dnUwACAAAAAAAAAAC7o0WLAAAAAPNGav4BE09wdXNIZWFkAQE4AYC7AAAAAABPZ2dTAAAAAAAAAAAAALujRYsBAAAAx5axMQE8
    T3B1c1RhZ3MMAAAATGF2ZjYzLjEuMTAxAQAAABwAAABlbmNvZGVyPUxhdmM2My4xLjEwMSBsaWJvcHVzT2dnUwAAgLsAAAAAAAC7
    o0WLAgAAABEKS8oyDxESEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhJ4C+TBNuzFjYxJRpmk
    JrB4B8lyJ+FE6lXx8MDV3elSYHgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgH
    yXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnI
    yVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfA
    ohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj
    +u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n
    82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA
    4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgH
    yXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnI
    yVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfA
    ohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj
    +u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n
    82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4E9nZ1MAAAB3AQAAAAAAu6NF
    iwMAAACdsTMOMhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISeAfJecjJV8CiEiP672fz
    ZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDg
    eAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJ
    ecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJ
    V8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8Ci
    EiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP6
    72fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fz
    ZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDg
    eAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJ
    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
    +u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n
    82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA
    4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgH
    yXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnI
    yVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfA
    ohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4HgHyXnIyVfAohIj+u9n82TA4E9nZ1MAAICpAwAA
    AAAAu6NFiwYAAABcGVb+MhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISeAfJecjJV8Ci
    EiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP6
    72fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fz
    ZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDg
    eAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJ
    ecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJV8CiEiP672fzZMDgeAfJecjJ
    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
    """
]
