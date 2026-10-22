import AppKit
import AVFoundation
import CoreVideo
import ImageIO
import QuartzCore
import UniformTypeIdentifiers

/// Generated fixtures, a private pasteboard and injected external actions keep
/// these integration checks separate from the user's clipboard and applications.
func runContextMenuSelfTests(_ viewer: ViewerController, output: URL) {
    var report: [String] = [], failures = 0
    func check(_ value: @autoclosure () -> Bool, _ message: String) {
        let passed = value(); report.append("\(passed ? "PASS" : "FAIL") \(message)")
        if !passed { failures += 1 }
    }
    func failure(_ message: String) -> NSError { NSError(domain: "LumaView.ContextMenuSelfTest", code: 1, userInfo: [NSLocalizedDescriptionKey: message]) }
    @discardableResult
    func spin(_ predicate: () -> Bool, timeout: Double = 12) -> Bool {
        let end = Date().addingTimeInterval(timeout)
        repeat {
            CATransaction.flush()
            if predicate() { return true }
            RunLoop.main.run(until: Date().addingTimeInterval(0.015))
        } while Date() < end
        return predicate()
    }
    let board = NSPasteboard(name: .init("LumaView.ContextMenuTest.\(UUID().uuidString)"))
    viewer.contextActions.pasteboard = board
    var messages: [String] = [], revealed: [URL] = [], opened: [(URL, URL)] = []
    viewer.contextActions.onMessage = { messages.append($0) }
    viewer.contextActions.reveal = { revealed.append($0) }
    viewer.contextActions.openWith = { file, app, completion in opened.append((file, app)); completion(nil) }
    func item(_ menu: NSMenu?, _ id: String) -> NSMenuItem? { menu?.items.first { $0.identifier?.rawValue == id } }
    @discardableResult
    func invoke(_ item: NSMenuItem?) -> Bool {
        guard let item, let action = item.action else { return false }
        return NSApp.sendAction(action, to: item.target, from: item)
    }
    func menu(at point: NSPoint? = nil, control: Bool = false) -> NSMenu? {
        guard let window = viewer.window else { return nil }
        viewer.revealChrome(); viewer.root.layoutSubtreeIfNeeded(); window.display(); CATransaction.flush()
        let local = point ?? NSPoint(x: viewer.canvas.bounds.midX, y: viewer.canvas.bounds.midY)
        let location = viewer.canvas.convert(local, to: nil)
        guard let event = NSEvent.mouseEvent(with: control ? .leftMouseDown : .rightMouseDown, location: location,
            modifierFlags: control ? [.control] : [], timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: window.windowNumber, context: nil, eventNumber: 9900, clickCount: 1, pressure: 1) else { return nil }
        return viewer.canvas.menu(for: event)
    }
    func layer(_ name: String, in root: CALayer?) -> CALayer? {
        guard let root else { return nil }; if root.name == name { return root }
        for child in root.sublayers ?? [] { if let result = layer(name, in: child) { return result } }
        return nil
    }
    func canvasPoint(_ documentPoint: CGPoint) -> CGPoint? {
        guard let page = viewer.documentPage, let content = layer("photo-content", in: viewer.canvas.layer),
              let root = viewer.canvas.layer else { return nil }
        let displayed = content.presentation() ?? content, displayedRoot = root.presentation() ?? root
        let local = CGPoint(x: displayed.bounds.minX + documentPoint.x / page.size.width * displayed.bounds.width,
                            y: displayed.bounds.minY + documentPoint.y / page.size.height * displayed.bounds.height)
        return displayed.convert(local, to: displayedRoot)
    }
    func markBoard() -> Int { board.clearContents(); board.setString("unchanged", forType: .string); return board.changeCount }
    func copiedImage() -> CGImage? {
        guard let data = board.data(forType: .png), let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
    func waitForCopy(after count: Int) -> CGImage? {
        guard spin({ board.changeCount != count && board.data(forType: .png) != nil }, timeout: 30) else { return nil }
        return copiedImage()
    }
    func sample(_ image: CGImage, x: Int? = nil, y: Int? = nil) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        guard let context = CGContext(data: &bytes, width: image.width, height: image.height, bitsPerComponent: 8,
            bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return [] }
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        let offset = ((y ?? image.height / 2) * image.width + (x ?? image.width / 2)) * 4
        return Array(bytes[offset..<offset + 4])
    }
    func imageFixture(_ color: NSColor, transparent: Bool = false, width: Int = 320, height: Int = 180) throws -> CGImage {
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { throw failure("image fixture context") }
        context.setFillColor(color.cgColor); context.fill(CGRect(x: 0, y: 0, width: transparent ? width / 2 : width, height: height))
        guard let image = context.makeImage() else { throw failure("image fixture pixels") }; return image
    }
    func save(_ image: CGImage, to url: URL) throws {
        guard let data = MediaCopy.encodedImage(image, type: .png) else { throw failure("PNG fixture") }; try data.write(to: url)
    }
    func writePDF(_ url: URL, embedded: CGImage) throws {
        let data = NSMutableData(); var box = CGRect(x: 0, y: 0, width: 600, height: 760)
        guard let consumer = CGDataConsumer(data: data as CFMutableData), let context = CGContext(consumer: consumer, mediaBox: &box, nil) else { throw failure("PDF fixture") }
        for index in 0..<2 {
            context.beginPDFPage(nil); context.setFillColor(NSColor.white.cgColor); context.fill(box)
            context.draw(embedded, in: CGRect(x: 60, y: 430, width: 240, height: 160))
            NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
            ("Text region / Page \(index + 1)" as NSString).draw(at: CGPoint(x: 80, y: 200), withAttributes: [.font: NSFont.systemFont(ofSize: 28), .foregroundColor: NSColor.black])
            NSGraphicsContext.restoreGraphicsState(); context.endPDFPage()
        }
        context.closePDF(); try (data as Data).write(to: url)
    }
    func writeAudio(_ url: URL) throws {
        var data = Data()
        func text(_ v: String) { data.append(contentsOf: v.utf8) }
        func u16(_ v: UInt16) { var v = v.littleEndian; withUnsafeBytes(of: &v) { data.append(contentsOf: $0) } }
        func u32(_ v: UInt32) { var v = v.littleEndian; withUnsafeBytes(of: &v) { data.append(contentsOf: $0) } }
        text("RIFF"); u32(36 + 64_000); text("WAVEfmt "); u32(16); u16(1); u16(1); u32(8_000)
        u32(16_000); u16(2); u16(16); text("data"); u32(64_000); data.append(Data(count: 64_000)); try data.write(to: url)
    }
    func writeVideo(_ url: URL) throws {
        let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: 160, AVVideoHeightKey: 96])
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB, kCVPixelBufferWidthKey as String: 160,
            kCVPixelBufferHeightKey as String: 96, kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true])
        guard writer.canAdd(input) else { throw failure("video input") }; writer.add(input)
        guard writer.startWriting() else { throw writer.error ?? failure("video writer") }; writer.startSession(atSourceTime: .zero)
        for index in 0..<60 {
            guard spin({ input.isReadyForMoreMediaData || writer.status == .failed }), writer.status == .writing,
                  let pool = adaptor.pixelBufferPool else { throw writer.error ?? failure("video frame readiness") }
            var optionalBuffer: CVPixelBuffer?
            guard CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &optionalBuffer) == kCVReturnSuccess,
                  let buffer = optionalBuffer else { throw failure("video pixel buffer") }
            CVPixelBufferLockBaseAddress(buffer, [])
            guard let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: 160, height: 96, bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else { throw failure("video context") }
            context.setFillColor(index < 30 ? NSColor.red.cgColor : NSColor.blue.cgColor); context.fill(CGRect(x: 0, y: 0, width: 160, height: 96))
            CVPixelBufferUnlockBaseAddress(buffer, [])
            guard adaptor.append(buffer, withPresentationTime: CMTime(value: Int64(index), timescale: 30)) else { throw writer.error ?? failure("video append") }
        }
        input.markAsFinished(); writer.endSession(atSourceTime: CMTime(value: 2, timescale: 1))
        var complete = false; writer.finishWriting { DispatchQueue.main.async { complete = true } }
        guard spin({ complete }), writer.status == .completed else { throw writer.error ?? failure("video finish") }
    }
    func select(_ url: URL) throws {
        guard let index = viewer.items.firstIndex(where: { $0.url == url }) else { throw failure("fixture missing from file sequence") }
        viewer.select(index)
    }
    func imageReady(_ url: URL) -> Bool { viewer.currentURL == url && viewer.loaded != nil && viewer.canvas.image != nil }
    func pageReady(_ url: URL, _ index: Int) -> Bool { viewer.currentURL == url && viewer.documentPage?.index == index && viewer.selectedPageIndex == index && viewer.canvas.documentPage === viewer.documentPage }
    func videoDisplayReady(_ root: CALayer?) -> Bool {
        guard let root else { return false }
        if let layer = root as? AVPlayerLayer, layer.player === viewer.video?.player { return layer.isReadyForDisplay }
        return root.sublayers?.contains(where: videoDisplayReady) == true
    }

    do {
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let fixtures = output.appendingPathComponent("context-fixtures", isDirectory: true)
        try FileManager.default.createDirectory(at: fixtures, withIntermediateDirectories: true)
        let still = fixtures.appendingPathComponent("01-transparent.png"), second = fixtures.appendingPathComponent("02-second.png")
        let pdf = fixtures.appendingPathComponent("03-book.pdf"), videoURL = fixtures.appendingPathComponent("04-video.mov"), audioURL = fixtures.appendingPathComponent("05-audio.wav")
        try save(imageFixture(.red, transparent: true), to: still); try save(imageFixture(.blue), to: second)
        try writePDF(pdf, embedded: imageFixture(.systemTeal, width: 120, height: 80)); try writeVideo(videoURL); try writeAudio(audioURL)
        func fakeApp(_ name: String, id: String) throws -> URL {
            let app = output.appendingPathComponent("mock-apps/\(name).app", isDirectory: true)
            let contents = app.appendingPathComponent("Contents", isDirectory: true)
            try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
            let data = try PropertyListSerialization.data(fromPropertyList: ["CFBundleIdentifier": id, "CFBundleName": name, "CFBundlePackageType": "APPL"], format: .xml, options: 0)
            try data.write(to: contents.appendingPathComponent("Info.plist")); return app
        }
        let external = try fakeApp("Example Viewer", id: "io.local.lumaview.test-external")
        let own = Bundle.main.bundleURL
        viewer.contextActions.applications = { _ in [external, external, own] }
        viewer.canvas.animationsEnabled = true; viewer.showFilmstrip = true
        viewer.open([still])
        guard spin({ imageReady(still) && viewer.window?.isVisible == true }) else { throw failure("initial image load") }
        viewer.canvas.rotate(1); viewer.canvas.zoomBy(4)
        spin({ !viewer.canvas.isAnimating }, timeout: 2)
        let beforeZoom = viewer.canvas.zoom, beforeTurns = viewer.canvas.quarterTurns
        let imageMenu = menu()
        check(item(imageMenu, "copy-image") != nil && item(imageMenu, "open-with") != nil && item(imageMenu, "reveal-in-finder") != nil, "Native canvas right-click menu exposes image copy, Open With and Finder actions")
        check(item(menu(control: true), "copy-image") != nil, "Control-click follows the same canvas context-menu path")
        check(viewer.canvas.zoom == beforeZoom && viewer.canvas.quarterTurns == beforeTurns && imageReady(still) && !viewer.isClosing, "Context-menu opening preserves zoom, rotation, current file and viewer lifetime")
        let startCount = markBoard()
        check(invoke(item(imageMenu, "copy-image")), "Image copy dispatches through native menu target/action")
        guard let copied = waitForCopy(after: startCount) else { throw failure("image copy timeout") }
        let oneCopyChanges = board.changeCount - startCount
        check(copied.width == 180 && copied.height == 320, "Copied image retains complete native pixels and visible quarter-turn despite zoom")
        check(sample(copied, x: 0, y: 0)[3] == 255 && sample(copied, x: 0, y: 319)[3] == 0, "Copied image preserves transparent pixels without checkerboard, backdrop or controls")
        check(board.data(forType: .png) != nil && board.data(forType: .tiff) != nil, "Private pasteboard publishes both PNG and TIFF image representations")
        let openMenu = item(imageMenu, "open-with")?.submenu
        check(openMenu?.items.filter { !$0.isSeparatorItem && $0.identifier?.rawValue != "choose-application" }.count == 1, "Open With deduplicates applications and omits LumaView itself")
        check(item(openMenu, "choose-application") != nil, "Open With also offers an application chooser")
        try select(second); guard spin({ imageReady(second) }) else { throw failure("second image load") }
        check(invoke(item(imageMenu, "reveal-in-finder")) && revealed == [still], "Finder action retains file from the menu snapshot without launching Finder in tests")
        check(invoke(openMenu?.items.first) && opened.count == 1 && opened[0].0 == still && opened[0].1 == external, "Open With retains menu file and selected application through a later selection change")
        let staleCount = markBoard(); _ = invoke(item(imageMenu, "copy-image")); spin({ false }, timeout: 0.2)
        check(board.changeCount == staleCount, "Stale image menu cannot overwrite clipboard after switching files")
        let currentMenu = menu(); _ = invoke(item(currentMenu, "copy-image")); try select(still)
        guard spin({ imageReady(still) }) else { throw failure("return to initial image") }
        let validMenu = menu(); _ = invoke(item(validMenu, "copy-image"))
        guard waitForCopy(after: staleCount) != nil else { throw failure("replacement copy timeout") }
        check(board.changeCount - staleCount == oneCopyChanges, "An in-flight old copy is discarded before the new selection publishes exactly one image")

        try select(pdf); guard spin({ pageReady(pdf, 0) }) else { throw failure("PDF load") }
        spin({ !viewer.canvas.isAnimating }, timeout: 2)
        let embeddedPoint = CGPoint(x: 180, y: 510), textPoint = CGPoint(x: 160, y: 210)
        guard spin({
            guard let point = canvasPoint(textPoint) else { return false }
            return item(viewer.contextActions.menu(at: point), "copy-embedded-image") == nil
        }), let onImage = canvasPoint(embeddedPoint), let onText = canvasPoint(textPoint) else { throw failure("PDF image index preparation") }
        let embeddedMenu = menu(at: onImage), textMenu = menu(at: onText)
        check(item(embeddedMenu, "copy-embedded-image") != nil && item(embeddedMenu, "copy-page") != nil, "Right-click on an embedded PDF image offers image and page as distinct copy actions")
        check(item(textMenu, "copy-embedded-image") == nil && item(textMenu, "copy-page") != nil, "Text-only PDF region does not masquerade as an embedded image")
        let embeddedCount = markBoard(); _ = invoke(item(embeddedMenu, "copy-embedded-image"))
        guard let embeddedCopy = waitForCopy(after: embeddedCount) else { throw failure("embedded PDF copy") }
        check(embeddedCopy.width == 120 && embeddedCopy.height == 80, "PDF embedded image copies original image pixels rather than a screenshot of the page")
        viewer.canvas.rotate(1); viewer.canvas.zoomBy(1.2); spin({ !viewer.canvas.isAnimating }, timeout: 2)
        guard let transformedPoint = canvasPoint(embeddedPoint), let hit = viewer.canvas.documentPoint(at: transformedPoint) else { throw failure("rotated PDF coordinates") }
        check(hypot(hit.x - embeddedPoint.x, hit.y - embeddedPoint.y) < 0.01, "Canvas PDF hit testing accounts for displayed rotation and zoom")
        let rotatedMenu = menu(at: transformedPoint), rotatedCount = markBoard()
        _ = invoke(item(rotatedMenu, "copy-embedded-image"))
        guard let rotatedEmbedded = waitForCopy(after: rotatedCount) else { throw failure("rotated PDF image copy") }
        check(rotatedEmbedded.width == 80 && rotatedEmbedded.height == 120, "Embedded PDF image copy follows the visible page quarter-turn")
        let pageCount = markBoard(); _ = invoke(item(rotatedMenu, "copy-page"))
        guard let wholePage = waitForCopy(after: pageCount) else { throw failure("whole-page copy") }
        check(wholePage.width > 1000 && wholePage.height > 1000 && abs(Double(wholePage.width) / Double(wholePage.height) - 760.0 / 600) < 0.01, "Copy current page produces a complete high-resolution rotated page independently from embedded-image copy")
        let oldPageMenu = menu(at: transformedPoint); viewer.selectPage(1)
        guard spin({ pageReady(pdf, 1) }) else { throw failure("PDF page switch") }
        let pageStaleCount = markBoard(); _ = invoke(item(oldPageMenu, "copy-embedded-image")); spin({ false }, timeout: 0.2)
        check(board.changeCount == pageStaleCount, "Page change invalidates an earlier PDF image menu")

        try select(audioURL)
        guard spin({ viewer.currentURL == audioURL && viewer.video?.isAudioOnly == true && viewer.video?.duration ?? 0 > 0 }) else { throw failure("audio load") }
        viewer.video?.pause()
        let audioMenu = menu()
        check(audioMenu?.items.contains { $0.identifier?.rawValue.hasPrefix("copy-") == true } == false, "Audio context menu never offers fake video-frame or cover-image copying")
        check(item(audioMenu, "open-with") != nil && item(audioMenu, "reveal-in-finder") != nil, "Audio retains Open With and Finder actions")

        try select(videoURL)
        guard spin({ viewer.currentURL == videoURL && viewer.video?.isAudioOnly == false
            && viewer.video?.player.currentItem?.status == .readyToPlay && viewer.video?.isPlaying == true
            && videoDisplayReady(viewer.canvas.layer) }), let video = viewer.video else { throw failure("video load") }
        video.pause(); video.seek(to: 0.25)
        guard spin({ abs(video.currentTime - 0.25) < 0.01 }) else { throw failure("video first seek") }
        viewer.canvas.rotate(1); spin({ !viewer.canvas.isAnimating }, timeout: 2)
        let videoMenu = menu()
        check(item(videoMenu, "copy-video-frame") != nil && item(videoMenu, "copy-image") == nil, "Video has a dedicated copy-current-frame menu action")
        video.seek(to: 1.25); guard spin({ abs(video.currentTime - 1.25) < 0.01 }) else { throw failure("video later seek") }
        let videoCount = markBoard(); _ = invoke(item(videoMenu, "copy-video-frame"))
        guard let videoCopy = waitForCopy(after: videoCount) else { throw failure("video menu copy") }
        let pixel = sample(videoCopy)
        check(pixel.count == 4 && pixel[0] > 180 && pixel[2] < 70, "Video menu copies the red frame visible when menu opened, despite later blue playback time")
        check(videoCopy.width == 96 && videoCopy.height == 160, "Video clipboard image includes view rotation at original video resolution")
        check(!video.isPlaying && video.player.rate == 0 && abs(video.currentTime - 1.25) < 0.01,
              "Context-menu frame copy does not alter pause or playback position (playing=\(video.isPlaying), rate=\(video.player.rate), time=\(video.currentTime))")
        let closingMenu = menu(); let closeCount = markBoard(); _ = invoke(item(closingMenu, "copy-video-frame")); viewer.closeViewer()
        spin({ viewer.window?.isVisible == false }, timeout: 2); spin({ false }, timeout: 0.3)
        check(board.changeCount == closeCount, "Closing during video copy prevents a late clipboard replacement")
        check(messages.count > 0, "Copy completion feedback is delivered through context action message callback")
    } catch { check(false, "Unexpected error: \(error)") }
    board.releaseGlobally()
    report.append("\n\(report.count - failures) passed, \(failures) failed")
    let text = report.joined(separator: "\n") + "\n"
    try? text.write(to: output.appendingPathComponent("context-menu-test-results.txt"), atomically: true, encoding: .utf8)
    print(text); fflush(stdout); exit(failures == 0 ? 0 : 1)
}
