import AppKit
import AudioToolbox
import AVFoundation
import CoreVideo
import ImageIO
import QuartzCore
import UniformTypeIdentifiers

/// Opt-in integration checks using generated media, without changing file associations.
func runVideoSelfTests(_ viewer: ViewerController, output: URL) {
    var report: [String] = [], diagnostics: [String] = [], failures = 0
    func check(_ condition: @autoclosure () -> Bool, _ message: String) {
        let passed = condition()
        report.append("\(passed ? "PASS" : "FAIL") \(message)")
        if !passed { failures += 1 }
    }
    @discardableResult
    func spin(_ condition: () -> Bool, timeout: TimeInterval = 8) -> Bool {
        let end = Date().addingTimeInterval(timeout)
        repeat {
            CATransaction.flush()
            if condition() { return true }
            RunLoop.main.run(until: Date().addingTimeInterval(0.025))
        } while Date() < end
        return condition()
    }
    func failure(_ message: String) -> NSError {
        NSError(domain: "LumaView.VideoSelfTest", code: 1,
                userInfo: [NSLocalizedDescriptionKey: message])
    }
    func writeVideo(_ url: URL, portrait: Bool = false) throws {
        try? FileManager.default.removeItem(at: url)
        let writer = try AVAssetWriter(outputURL: url, fileType: portrait ? .mov : .mp4)
        let width = 640, height = 360, frames = 144, fps: Int32 = 24
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 900_000]
        ])
        input.expectsMediaDataInRealTime = false
        if portrait { input.transform = CGAffineTransform(a: 0, b: 1, c: -1, d: 0, tx: CGFloat(height), ty: 0) }
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height,
                kCVPixelBufferCGImageCompatibilityKey as String: true,
                kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
            ])
        guard writer.canAdd(input) else { throw failure("Writer cannot add H.264 input") }
        writer.add(input)
        // A real AAC track exercises audio playback/lifecycle without making noise.
        let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 48_000,
            AVNumberOfChannelsKey: 1, AVEncoderBitRateKey: 64_000
        ])
        audioInput.expectsMediaDataInRealTime = false
        guard writer.canAdd(audioInput) else { throw failure("Writer cannot add AAC input") }
        writer.add(audioInput)
        var audioDescription = AudioStreamBasicDescription(mSampleRate: 48_000,
            mFormatID: kAudioFormatLinearPCM, mFormatFlags: kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
            mBytesPerPacket: 2, mFramesPerPacket: 1, mBytesPerFrame: 2, mChannelsPerFrame: 1, mBitsPerChannel: 16, mReserved: 0)
        var audioFormat: CMAudioFormatDescription?
        guard CMAudioFormatDescriptionCreate(allocator: kCFAllocatorDefault, asbd: &audioDescription,
            layoutSize: 0, layout: nil, magicCookieSize: 0, magicCookie: nil, extensions: nil,
            formatDescriptionOut: &audioFormat) == noErr, let audioFormat else { throw failure("Cannot describe PCM audio") }
        guard writer.startWriting() else { throw writer.error ?? failure("Writer cannot start") }
        writer.startSession(atSourceTime: .zero)
        var index = 0, audioIndex = 0
        while index < frames || audioIndex < frames {
            // Feed each encoder independently: AAC priming and video reordering
            // can otherwise deadlock a strict video-then-audio append sequence.
            guard spin({ (index < frames && input.isReadyForMoreMediaData)
                || (audioIndex < frames && audioInput.isReadyForMoreMediaData) || writer.status == .failed }, timeout: 5),
                  writer.status == .writing else { throw writer.error ?? failure("Writer timed out") }
            if index < frames && input.isReadyForMoreMediaData {
            var optionalBuffer: CVPixelBuffer?
            guard CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, adaptor.pixelBufferPool!, &optionalBuffer) == kCVReturnSuccess,
                  let buffer = optionalBuffer else { throw failure("Cannot create a video pixel buffer") }
            CVPixelBufferLockBaseAddress(buffer, [])
            guard let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: width, height: height,
                    bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
                CVPixelBufferUnlockBaseAddress(buffer, [])
                throw failure("Cannot draw a video frame")
            }
            let w = CGFloat(width), h = CGFloat(height), progress = CGFloat(index) / CGFloat(frames - 1)
            context.setFillColor(NSColor(srgbRed: 0.08, green: 0.18, blue: 0.28, alpha: 1).cgColor)
            context.fill(CGRect(x: 0, y: 0, width: w, height: h))
            context.setFillColor(NSColor(srgbRed: 0.96, green: 0.71, blue: 0.30, alpha: 1).cgColor)
            context.fillEllipse(in: CGRect(x: 35 + progress * 440, y: 120, width: 125, height: 125))
            context.setFillColor(NSColor(srgbRed: 0.32, green: 0.72, blue: 0.67, alpha: 1).cgColor)
            context.fill(CGRect(x: 0, y: 0, width: w * progress, height: 24))
            // Asymmetric corners make the preferred track transform visible.
            context.setFillColor(NSColor.white.cgColor)
            context.fill(CGRect(x: 20, y: h - 65, width: 80, height: 45))
            context.setFillColor(NSColor.systemRed.cgColor)
            context.fill(CGRect(x: w - 65, y: 35, width: 40, height: 75))
            CVPixelBufferUnlockBaseAddress(buffer, [])
            guard adaptor.append(buffer, withPresentationTime: CMTime(value: Int64(index), timescale: fps)) else {
                throw writer.error ?? failure("Cannot append video frame")
            }
            index += 1
            if index == frames { input.markAsFinished() }
            }
            if audioIndex < frames && audioInput.isReadyForMoreMediaData {
            let audioSampleCount = 2_000 // 48 kHz / 24 fps.
            var audioBlock: CMBlockBuffer?
            guard CMBlockBufferCreateWithMemoryBlock(allocator: kCFAllocatorDefault, memoryBlock: nil,
                blockLength: audioSampleCount * 2, blockAllocator: kCFAllocatorDefault, customBlockSource: nil,
                offsetToData: 0, dataLength: audioSampleCount * 2, flags: 0,
                blockBufferOut: &audioBlock) == kCMBlockBufferNoErr, let audioBlock else { throw failure("Cannot allocate audio data") }
            guard CMBlockBufferFillDataBytes(with: 0, blockBuffer: audioBlock, offsetIntoDestination: 0,
                                            dataLength: audioSampleCount * 2) == kCMBlockBufferNoErr else { throw failure("Cannot fill audio data") }
            var audioSamples: CMSampleBuffer?
            guard CMAudioSampleBufferCreateReadyWithPacketDescriptions(allocator: kCFAllocatorDefault,
                dataBuffer: audioBlock, formatDescription: audioFormat, sampleCount: audioSampleCount,
                presentationTimeStamp: CMTime(value: Int64(audioIndex * audioSampleCount), timescale: 48_000),
                packetDescriptions: nil, sampleBufferOut: &audioSamples) == noErr,
                let audioSamples, audioInput.append(audioSamples) else {
                throw writer.error ?? failure("Cannot append audio samples")
            }
            audioIndex += 1
            if audioIndex == frames { audioInput.markAsFinished() }
            }
        }
        writer.endSession(atSourceTime: CMTime(value: Int64(frames), timescale: fps))
        var finished = false
        writer.finishWriting { DispatchQueue.main.async { finished = true } }
        guard spin({ finished }, timeout: 20), writer.status == .completed else {
            throw writer.error ?? failure("Writer did not finish")
        }
    }
    func writeImage(_ url: URL) throws {
        let context = CGContext(data: nil, width: 1200, height: 800, bitsPerComponent: 8, bytesPerRow: 1200 * 4,
                                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.setFillColor(NSColor(srgbRed: 0.23, green: 0.56, blue: 0.48, alpha: 1).cgColor)
        context.fill(CGRect(x: 0, y: 0, width: 1200, height: 800))
        context.setFillColor(NSColor(srgbRed: 0.98, green: 0.77, blue: 0.40, alpha: 1).cgColor)
        context.fillEllipse(in: CGRect(x: 700, y: 400, width: 250, height: 250))
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw failure("Cannot create image fixture")
        }
        CGImageDestinationAddImage(destination, context.makeImage()!, nil)
        guard CGImageDestinationFinalize(destination) else { throw failure("Cannot write image fixture") }
    }
    func playerLayer(in layer: CALayer?) -> AVPlayerLayer? {
        guard let layer else { return nil }
        if let video = layer as? AVPlayerLayer, video.player === viewer.video?.player { return video }
        for child in layer.sublayers ?? [] {
            if let result = playerLayer(in: child) { return result }
        }
        return nil
    }
    func ready(_ url: URL) -> Bool {
        viewer.currentURL == url && viewer.video != nil && viewer.canvas.hasMedia
            && playerLayer(in: viewer.canvas.layer)?.isReadyForDisplay == true
            && playerLayer(in: viewer.canvas.layer)?.superlayer?.superlayer?.opacity == 1
    }
    func remainsOpen() -> Bool { viewer.window?.isVisible == true && !viewer.isClosing }
    func key(_ text: String, code: UInt16 = 0, modifiers: NSEvent.ModifierFlags = []) {
        guard let window = viewer.window,
              let event = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: modifiers,
                  timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber, context: nil,
                  characters: text, charactersIgnoringModifiers: text, isARepeat: false, keyCode: code) else { return }
        _ = viewer.handleKey(event)
    }
    var eventNumber = 500
    func click(_ view: NSView, point: NSPoint? = nil, reveal: Bool = true, validateTarget: Bool = true) -> Bool {
        guard let window = viewer.window, remainsOpen() else { return false }
        if reveal { viewer.revealChrome() }
        viewer.root.layoutSubtreeIfNeeded(); window.display(); CATransaction.flush()
        let location = view.convert(point ?? NSPoint(x: view.bounds.midX, y: view.bounds.midY), to: nil)
        let hit = viewer.root.hitTest(viewer.root.convert(location, from: nil))
        guard !validateTarget || hit === view || hit?.isDescendant(of: view) == true else {
            diagnostics.append("Click target mismatch: \(type(of: view)), hit=\(String(describing: hit))")
            return false
        }
        eventNumber += 2
        let time = ProcessInfo.processInfo.systemUptime
        guard let down = NSEvent.mouseEvent(with: .leftMouseDown, location: location, modifierFlags: [],
                  timestamp: time, windowNumber: window.windowNumber, context: nil, eventNumber: eventNumber,
                  clickCount: 1, pressure: 1),
              let up = NSEvent.mouseEvent(with: .leftMouseUp, location: location, modifierFlags: [],
                  timestamp: time + 0.01, windowNumber: window.windowNumber, context: nil, eventNumber: eventNumber + 1,
                  clickCount: 1, pressure: 0) else { return false }
        NSApp.postEvent(up, atStart: true)
        window.sendEvent(down)
        while let event = NSApp.nextEvent(matching: .leftMouseUp, until: Date(), inMode: .default, dequeue: true) {
            if event.windowNumber == window.windowNumber { window.sendEvent(event) }
            else { NSApp.sendEvent(event) }
        }
        spin({ false }, timeout: 0.12)
        return true
    }
    func thumbnailPoint(_ index: Int) -> NSPoint {
        let capacity = max(1, Int((viewer.strip.bounds.width - 24) / 72))
        let first = max(0, min(viewer.selectedIndex - capacity / 2, viewer.items.count - capacity))
        let count = min(capacity, viewer.items.count)
        return NSPoint(x: (viewer.strip.bounds.width - CGFloat(count) * 72) / 2 + CGFloat(index - first) * 72 + 35, y: 35)
    }
    func dragVideo() -> Bool {
        guard let window = viewer.window, let videoLayer = playerLayer(in: viewer.canvas.layer),
              let container = videoLayer.superlayer?.superlayer else { return false }
        let before = container.position
        let center = NSPoint(x: viewer.canvas.bounds.midX, y: viewer.canvas.bounds.midY + 40)
        for (type, delta) in [(NSEvent.EventType.leftMouseDown, CGFloat(0)), (.leftMouseDragged, 90), (.leftMouseUp, 90)] {
            let position = viewer.canvas.convert(NSPoint(x: center.x + delta, y: center.y + delta / 3), to: nil)
            guard let event = NSEvent.mouseEvent(with: type, location: position, modifierFlags: [],
                timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber, context: nil,
                eventNumber: 700, clickCount: 1, pressure: type == .leftMouseUp ? 0 : 1) else { return false }
            window.sendEvent(event)
        }
        spin({ !viewer.canvas.isAnimating }, timeout: 1)
        return remainsOpen() && hypot(container.position.x - before.x, container.position.y - before.y) > 20
    }

    do {
        let fixtures = output.appendingPathComponent("fixtures", isDirectory: true)
        try FileManager.default.createDirectory(at: fixtures, withIntermediateDirectories: true)
        let still = fixtures.appendingPathComponent("01-photo.jpg")
        let landscape = fixtures.appendingPathComponent("02-video.mp4")
        let portrait = fixtures.appendingPathComponent("03-portrait.mov")
        let secondStill = fixtures.appendingPathComponent("04-photo.jpg")
        let invalid = fixtures.appendingPathComponent("05-broken.mp4")
        try? FileManager.default.removeItem(at: invalid)
        try writeImage(still); try writeImage(secondStill)
        try writeVideo(landscape); try writeVideo(portrait, portrait: true)
        check((try? Data(contentsOf: landscape).count) ?? 0 > 1_000, "Generate local H.264 MP4 fixture")
        var audioTrackFound = false, audioInspectionFinished = false
        Task { @MainActor in
            let tracks = try? await AVURLAsset(url: landscape).loadTracks(withMediaType: .audio)
            audioTrackFound = tracks?.isEmpty == false
            audioInspectionFinished = true
        }
        check(spin { audioInspectionFinished } && audioTrackFound, "Fixture contains a native AAC audio track")

        let session = VideoSession(url: landscape)
        var prepared = false, preparationError: Error?
        session.prepare { result in
            switch result {
            case .success: prepared = true
            case .failure(let error): preparationError = error
            }
        }
        check(spin { prepared || preparationError != nil } && prepared, "Prepare a native H.264 player asynchronously")
        if let preparationError { diagnostics.append("Prepare error: \(preparationError)") }
        check(session.pixelSize == CGSize(width: 640, height: 360), "Read video dimensions")
        check(abs(session.duration - 6) < 0.1, "Read video duration in seconds")
        check(!session.metadata.isEmpty, "Build video information metadata")
        var updates = 0
        session.onUpdate = { updates += 1 }
        session.play()
        check(spin { session.currentTime > 0.2 && session.isPlaying }, "Playback time advances")
        session.pause(); let pausedTime = session.currentTime
        spin({ false }, timeout: 0.25)
        check(session.player.rate == 0 && abs(session.currentTime - pausedTime) < 0.1, "Pause stops playback time")
        session.seek(to: 2.5)
        check(spin { abs(session.currentTime - 2.5) < 0.2 }, "Seek accurately while paused")
        for value in [1.0, 4.0, 0.5, 3.0] { session.seek(to: value) }
        check(spin { abs(session.currentTime - 3) < 0.2 }, "Repeated seeks settle on the latest requested time")
        session.seek(by: -1)
        check(spin { abs(session.currentTime - 2) < 0.2 }, "Relative seeking retains paused state")
        check(session.player.rate == 0, "Seeking does not silently resume paused playback")
        session.togglePlayback(); check(spin { session.isPlaying }, "Toggle resumes playback")
        var endedCount = 0
        session.onEnded = { endedCount += 1 }
        session.seek(to: session.duration - 0.15)
        check(spin { endedCount == 1 && !session.isPlaying }, "End of video emits one completion and pauses")
        session.play()
        check(spin { session.isPlaying && session.currentTime > 0.1 && session.currentTime < 1 }, "Playing an ended video restarts from its beginning")
        session.pause(); session.seek(to: session.duration)
        spin { session.currentTime > session.duration - 0.1 }
        session.seek(to: 3); session.play()
        check(spin { session.isPlaying && session.currentTime > 2.8 && session.currentTime < 4 },
              "Seeking from the end and immediately playing preserves the pending middle seek")
        session.pause(); session.seek(to: session.duration)
        check(spin { session.currentTime > session.duration - 0.1 && session.player.rate == 0 },
              "Seeking to the last frame while paused does not unexpectedly replay")
        session.dispose(); let updatesAfterDisposal = updates
        spin({ false }, timeout: 0.35)
        check(session.player.rate == 0, "Disposal immediately stops video and its audio clock")
        check(updates == updatesAfterDisposal, "Disposal removes periodic UI callbacks")

        let oriented = VideoSession(url: portrait)
        var portraitPrepared = false
        oriented.prepare { result in if case .success = result { portraitPrepared = true } }
        check(spin { portraitPrepared } && oriented.pixelSize == CGSize(width: 360, height: 640),
              "Apply preferred track transform to portrait dimensions")
        oriented.dispose()

        viewer.window?.setContentSize(NSSize(width: 1100, height: 760))
        viewer.showFilmstrip = true; viewer.looping = true; viewer.sort = .name
        viewer.closeOnBackground = true; viewer.canvas.backgroundMode = .translucent
        viewer.open([still])
        check(spin { viewer.loaded != nil && viewer.currentURL == still && viewer.items.count == 4 },
              "Opening an image discovers a mixed image/video folder in natural order")
        check(viewer.items.map(\.url) == [still, landscape, portrait, secondStill], "Mixed media preserves filename order")
        viewer.select(1)
        check(!viewer.videoSeekSlider.isEnabled && !viewer.videoVolumeSlider.isEnabled
              && viewer.buttons["mediaPlay"]?.isEnabled == false && viewer.buttons["mediaStop"]?.isEnabled == false,
              "Media playback controls stay disabled while video is being prepared")
        viewer.togglePlayback()
        check(viewer.video?.isPlaying != true && !viewer.isPlaying, "P during video preparation does not start a slideshow or premature playback")
        viewer.select(0)
        spin { viewer.loaded != nil && viewer.currentURL == still }
        viewer.layoutChrome()
        let selectedVideo = click(viewer.strip, point: thumbnailPoint(1))
        check(selectedVideo && spin { ready(landscape) && remainsOpen() },
              "Real thumbnail down/up opens video and displays its first frame without closing")
        viewer.video?.pause()
        check(viewer.canvas.image == nil && viewer.canvas.hasMedia, "Video uses a live player layer rather than a decoded still image")
        check(viewer.openButton.superview == nil, "Video removes the welcome button")
        check(!viewer.backdrop.isHidden && viewer.backdrop.blendingMode == .behindWindow
              && (viewer.canvas.layer?.backgroundColor?.alpha ?? 1) < 1, "Video retains the translucent glass background")
        check(!viewer.videoSeekSlider.isHidden && !viewer.videoTimeLabel.stringValue.isEmpty,
              "Video exposes a seek slider and playback time")
        check(viewer.buttons["play"]?.action == #selector(ViewerController.toggleSlideshow)
              && viewer.buttons["mediaPlay"]?.action == #selector(ViewerController.togglePlayback)
              && viewer.buttons["mediaStop"]?.action == #selector(ViewerController.stopPlayback),
              "Slideshow, media play/pause, and media stop have distinct actions")
        check(viewer.videoSeekSlider.frame.minY > viewer.strip.frame.maxY
              && (viewer.buttons["mediaPlay"]?.frame.minY ?? 0) > viewer.strip.frame.maxY,
              "Media transport sits above the thumbnail strip without overlap")
        let playClicked = viewer.buttons["mediaPlay"].map { click($0) } ?? false
        check(playClicked && spin { viewer.video?.isPlaying == true && (viewer.video?.currentTime ?? 0) > 0.15 }
              && !viewer.isPlaying && remainsOpen(), "Real media play click starts only the current video")
        let pauseClicked = viewer.buttons["mediaPlay"].map { click($0) } ?? false
        check(pauseClicked && viewer.video?.player.rate == 0 && !viewer.isPlaying && remainsOpen(),
              "Real media pause click pauses without starting a slideshow")
        let sliderClicked = click(viewer.videoSeekSlider,
                                  point: NSPoint(x: viewer.videoSeekSlider.bounds.midX, y: viewer.videoSeekSlider.bounds.midY))
        check(sliderClicked && spin { abs((viewer.video?.currentTime ?? 0) - 3) < 0.5 },
              "Real seek-slider mouse down/up changes the current playback time")
        let stopClicked = viewer.buttons["mediaStop"].map { click($0) } ?? false
        check(stopClicked && spin { (viewer.video?.currentTime ?? 99) < 0.1 && viewer.video?.player.rate == 0 }
              && viewer.currentURL == landscape && !viewer.isPlaying, "Real media stop click pauses and returns to zero")
        let slideshowClicked = viewer.buttons["play"].map { click($0) } ?? false
        check(slideshowClicked && viewer.isPlaying && viewer.video?.isPlaying == true,
              "The independent slideshow button starts continuous playback")
        check((viewer.buttons["mediaPlay"].map { click($0) } ?? false)
              && viewer.video?.player.rate == 0 && viewer.isPlaying,
              "Media pause preserves the independent slideshow setting")
        check((viewer.buttons["mediaStop"].map { click($0) } ?? false)
              && spin { (viewer.video?.currentTime ?? 99) < 0.1 && viewer.video?.player.rate == 0 } && viewer.isPlaying,
              "Media stop rewinds while preserving the independent slideshow setting")
        let slideshowStopped = viewer.buttons["play"].map { click($0) } ?? false
        check(slideshowStopped && !viewer.isPlaying && viewer.currentURL == landscape,
              "The slideshow button stops continuous playback without changing the file")
        viewer.video?.pause()

        viewer.actualSize()
        check(abs(viewer.canvas.zoom - 1) < 0.0001, "Video 100% uses physical source pixels")
        viewer.canvas.zoomBy(8)
        spin({ !viewer.canvas.isAnimating }, timeout: 1)
        check(viewer.canvas.zoom >= 7.99, "Video zooms beyond 100% with the existing canvas controls")
        viewer.video?.play()
        let beforeDragTime = viewer.video?.currentTime ?? 0
        check(dragVideo(), "Real drag pans the enlarged video without closing it")
        check(spin { (viewer.video?.currentTime ?? 0) > beforeDragTime + 0.15 }, "Video continues playing during a canvas drag")
        viewer.video?.pause()
        viewer.rotateRight()
        check(viewer.canvas.quarterTurns == 1, "Existing rotation transforms the video display")
        viewer.rotateLeft(); viewer.fit()
        check(viewer.canvas.isFit && viewer.canvas.quarterTurns == 0, "Fit and reverse rotation restore video geometry")
        viewer.video?.seek(to: 1)
        spin { abs((viewer.video?.currentTime ?? 0) - 1) < 0.2 }
        viewer.video?.play()
        let beforeZoom = viewer.video?.currentTime ?? 0
        viewer.zoomIn(); viewer.zoomOut()
        check(spin { (viewer.video?.currentTime ?? 0) > beforeZoom + 0.2 }, "Playback continues while zoom animations run")
        viewer.video?.pause()
        let videoBeforeSpace = viewer.video
        let backgroundBeforeSpace = viewer.canvas.backgroundMode
        key(" ", code: 49)
        check(viewer.canvas.backgroundMode != backgroundBeforeSpace && viewer.video === videoBeforeSpace,
              "Space keeps the existing background-cycle interaction")
        viewer.canvas.backgroundMode = .translucent
        key("p"); check(spin { viewer.video?.isPlaying == true }, "P plays the selected video")
        key("p"); check(viewer.video?.player.rate == 0, "P pauses the selected video")
        viewer.videoSeekSlider.doubleValue = 2
        viewer.seekVideo(viewer.videoSeekSlider)
        check(spin { abs((viewer.video?.currentTime ?? 0) - 2) < 0.25 }, "Seek slider updates the native player")
        let beforeMute = viewer.video?.player.isMuted
        viewer.toggleVideoMute()
        check(viewer.video?.player.isMuted != beforeMute, "Mute control updates the player")
        viewer.toggleVideoMute()

        let infoOpened = viewer.buttons["info"].map { click($0) } ?? false
        check(infoOpened && spin { !viewer.infoPanel.isHidden && remainsOpen() }, "Information panel opens on video")
        let metadataClicked = click(viewer.infoText, point: NSPoint(x: 20, y: viewer.infoText.bounds.height - 70))
        check(metadataClicked && remainsOpen(), "Real video-metadata text click does not close the viewer")
        let oldPlayer = viewer.video?.player
        let portraitClicked = click(viewer.strip, point: thumbnailPoint(2))
        check(portraitClicked && spin { ready(portrait) && remainsOpen() }, "Real thumbnail click switches to a portrait video after metadata selection")
        check(viewer.video?.pixelSize == CGSize(width: 360, height: 640), "Portrait viewer uses the oriented dimensions")
        check(oldPlayer?.rate == 0, "Switching video stops the previous player's audio immediately")
        _ = viewer.buttons["closeInfo"].map { click($0) }
        viewer.video?.pause()

        var previousPlayers: [AVPlayer] = []
        for index in [1, 0, 2, 3, 1, 2, 0, 1, 3, 2] {
            if let player = viewer.video?.player { previousPlayers.append(player) }
            viewer.select(index)
        }
        check(spin { ready(portrait) }, "Rapid mixed-media switching settles on the final requested video")
        check(previousPlayers.allSatisfy { $0 === viewer.video?.player || $0.rate == 0 },
              "Rapid switching leaves no old player or audio clock running")
        viewer.video?.pause()
        let lastVideoPlayer = viewer.video?.player
        viewer.select(0)
        check(spin { viewer.loaded != nil && viewer.currentURL == still && viewer.video == nil },
              "Video-to-image switch restores the image canvas")
        check(lastVideoPlayer?.rate == 0, "Switching back to an image stops video playback")
        viewer.dock.isHidden = true; viewer.dock.alphaValue = 0; CATransaction.flush()
        let hiddenClick = click(viewer.strip, point: thumbnailPoint(1), reveal: false, validateTarget: false)
        check(hiddenClick && spin { ready(landscape) && remainsOpen() },
              "Clicking a video thumbnail in hidden chrome reveals it before routing events")

        let beforeClose = viewer.video?.player
        viewer.closeViewer()
        check(beforeClose?.rate == 0, "Closing stops video immediately before the window fade finishes")
        check(spin({ !remainsOpen() && viewer.window?.isVisible == false }, timeout: 2), "Video close finishes its transition")
        viewer.open([portrait])
        check(spin { ready(portrait) && remainsOpen() }, "Reopening after video close creates a functional player")
        viewer.video?.pause()
        key("", code: 123)
        check(spin { ready(landscape) }, "Left arrow preserves previous-file navigation for video")
        viewer.video?.pause()
        viewer.video?.seek(to: 0.25)
        spin { abs((viewer.video?.currentTime ?? 0) - 0.25) < 0.2 }
        key("", code: 124, modifiers: .option)
        check(spin { (viewer.video?.currentTime ?? 0) > 4.5 && viewer.currentURL == landscape },
              "Option-right seeks inside video without changing the selected file")

        try Data("not a valid movie".utf8).write(to: invalid)
        viewer.open([invalid])
        check(spin { viewer.currentURL == invalid && viewer.canvas.placeholderText != nil && viewer.video == nil },
              "A corrupt movie produces a recoverable error instead of crashing")
        viewer.open([still])
        check(spin { viewer.loaded != nil && viewer.currentURL == still && remainsOpen() }, "Image viewing recovers after a corrupt movie")
        viewer.closeViewer()
        spin({ viewer.window?.isVisible == false }, timeout: 2)
    } catch { check(false, "Unexpected error: \(error)") }

    report.append("\n\(report.count - failures) passed, \(failures) failed")
    let text = (report + diagnostics).joined(separator: "\n") + "\n"
    try? text.write(to: output.appendingPathComponent("video-test-results.txt"), atomically: true, encoding: .utf8)
    print(text); fflush(stdout)
    exit(failures == 0 ? 0 : 1)
}
