import AppKit
import ImageIO
import UniformTypeIdentifiers

/// Test-only observation at the real loader entry. The normal fixture walk still
/// uses ImageIO and the production loader queues/caches without substitutions.
enum ThumbnailTestMetrics {
    static var requests: [URL: Int] = [:]
    static var draws = 0
    static var controlled: ((URL, @escaping (NSImage?) -> Void) -> Void)?
    #if CANCELLABLE_THUMBNAILS
    static var tickets: [ThumbnailRequest] = []
    #endif
    static func record(_ url: URL) { requests[url, default: 0] += 1 }
    static var total: Int { requests.values.reduce(0, +) }
    static func reset() {
        requests.removeAll(); controlled = nil; draws = 0
        #if CANCELLABLE_THUMBNAILS
        tickets.removeAll()
        #endif
    }
}

@main
struct ThumbnailTests {
    private static var checks = 0
    private static var failures: [String] = []
    private static var output = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? NSTemporaryDirectory()).standardizedFileURL.resolvingSymlinksInPath()
    private static let width: CGFloat = 904
    private static let capacity = 12

    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        Task { @MainActor in
            do { try await runChecks() }
            catch { failures.append("unexpected error: \(error)") }
            if failures.isEmpty { print("PASS: \(checks) thumbnail cache / navigation / callback / rendering checks") }
            else {
                for failure in failures { print("FAIL: \(failure)") }
                print("FAILED: \(failures.count) of \(checks) thumbnail checks")
            }
            fflush(stdout)
            app.terminate(nil)
        }
        app.run()
    }

    @MainActor
    private static func runChecks() async throws {
        let fixtures = output.appendingPathComponent("fixtures-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: fixtures, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: fixtures) }
        let colors: [NSColor] = [
            NSColor(srgbRed: 0.88, green: 0.17, blue: 0.12, alpha: 1),
            NSColor(srgbRed: 0.1, green: 0.74, blue: 0.24, alpha: 1),
            NSColor(srgbRed: 0.12, green: 0.33, blue: 0.92, alpha: 1),
            NSColor(srgbRed: 0.87, green: 0.69, blue: 0.1, alpha: 1),
            NSColor(srgbRed: 0.78, green: 0.14, blue: 0.8, alpha: 1)
        ]
        let images = try colors.map(makeImage)
        let data = try images.map { image -> Data in
            guard let bitmap = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
                  let png = NSBitmapImageRep(cgImage: bitmap).representation(using: .png, properties: [:]) else { throw TestError.render }
            return png
        }
        for index in 0..<443 {
            try data[index % data.count].write(to: fixtures.appendingPathComponent(String(format: "%04d.png", index)))
        }
        let collected = try ImageLibrary.collect(from: [fixtures])
        check(collected.items.count == 443, "folder scan collects all 443 generated images")
        check(collected.items.first?.name == "0000.png" && collected.items.last?.name == "0442.png", "fixture order matches file navigation order")
        let window = NSWindow(contentRect: NSRect(x: 100, y: 100, width: width + 40, height: 120),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.title = "LumaView thumbnail regression"
        window.isReleasedWhenClosed = false
        window.backgroundColor = NSColor(srgbRed: 0.12, green: 0.13, blue: 0.14, alpha: 1)
        let strip = Filmstrip(loader: ImageLoader())
        strip.frame = NSRect(x: 20, y: 20, width: width, height: 74)
        window.contentView?.addSubview(strip)
        window.makeKeyAndOrderFront(nil)
        defer { window.close() }
        ThumbnailTestMetrics.reset()
        strip.items = collected.items
        strip.selected = 0
        let initial = await waitForImages(strip, colors: colors, timeout: 2)
        check(initial, "initial 12 thumbnails decode and draw their actual image colors")

        // More than three times the old view cache limit, beyond the loader's
        // independent 256-entry cache, then revisit earlier and far-away ranges.
        var completeRanges = 0
        for selected in stride(from: 12, through: 432, by: 12) {
            strip.selected = selected
            if await waitForImages(strip, colors: colors, timeout: 0.15) { completeRanges += 1 }
        }
        print("INFO: complete visited ranges after initial range: \(completeRanges)/36; thumbnail requests: \(ThumbnailTestMetrics.total)")
        check(completeRanges == 36, "all ranges remain populated after browsing beyond both cache limits")
        check(await waitForImages(strip, colors: colors, timeout: 1), "last visible range fully populates after browsing 443 files")
        try saveSnapshot(strip, name: "thumbnail-after-443-files.png")
        let stationaryRequests = ThumbnailTestMetrics.total
        var stableFrames = 0
        for _ in 0..<30 {
            if pixelsMatch(strip, colors: colors) { stableFrames += 1 }
            await pause(0.02)
        }
        let stationaryReloads = ThumbnailTestMetrics.total - stationaryRequests
        print("INFO: stationary frames with every image: \(stableFrames)/30; repeated thumbnail requests: \(stationaryReloads)")
        check(stableFrames == 30, "all 12 thumbnail cells remain visible in every stationary frame")
        check(stationaryReloads == 0, "a stationary strip does not enter a thumbnail reload/redraw loop")
        let beforeEviction = ThumbnailTestMetrics.total
        var pressureFrames = 0
        for _ in 0..<15 {
            discardRecreatableCaches(strip)
            if pixelsMatch(strip, colors: colors) { pressureFrames += 1 }
            await pause(0.01)
        }
        check(pressureFrames == 15, "visible thumbnails never disappear when optional caches are reclaimed")
        check(ThumbnailTestMetrics.total == beforeEviction, "cache reclamation does not repeatedly decode the visible thumbnails")
        for index in [13, 230, 442, 0, 128, 300] {
            strip.selected = index
            check(await waitForImages(strip, colors: colors, timeout: 1), "jump to file \(index) restores every visible thumbnail")
        }
        for index in 0..<180 {
            strip.selected = (index * 127) % collected.items.count
            _ = render(strip)
            if index % 20 == 0 { await pause(0.01) }
        }
        strip.selected = 13
        check(await waitForImages(strip, colors: colors, timeout: 2), "rapid navigation settles to the correct visible images")
        let rapidSettledRequests = ThumbnailTestMetrics.total
        await pause(0.2)
        for _ in 0..<5 { check(pixelsMatch(strip, colors: colors), "settled range survives later offscreen completions") }
        check(ThumbnailTestMetrics.total == rapidSettledRequests, "later completions do not force visible thumbnails to reload")
        try saveSnapshot(strip, name: "thumbnail-stable-return.png")
        strip.removeFromSuperview()
        try await callbackChecks(window: window, items: collected.items, images: images)
    }

    @MainActor
    private static func callbackChecks(window: NSWindow, items: [ImageItem], images: [NSImage]) async throws {
        typealias Pending = (url: URL, completion: (NSImage?) -> Void)
        var pending: [Pending] = []
        ThumbnailTestMetrics.reset()
        ThumbnailTestMetrics.controlled = { url, completion in pending.append((url, completion)) }
        defer { ThumbnailTestMetrics.controlled = nil }
        let strip = Filmstrip(loader: ImageLoader())
        strip.frame = NSRect(x: 20, y: 20, width: width, height: 74)
        window.contentView?.addSubview(strip)
        defer { strip.removeFromSuperview() }
        strip.items = Array(items.prefix(12))
        _ = render(strip)
        let oldFolder = pending; pending.removeAll()
        #if CANCELLABLE_THUMBNAILS
        let oldFolderTickets = ThumbnailTestMetrics.tickets
        #endif
        check(oldFolder.count == 12, "each visible file starts exactly one thumbnail request")
        for _ in 0..<10 { _ = render(strip) }
        check(pending.isEmpty, "redrawing while thumbnails are pending never duplicates requests")
        // Reopen the same URLs while the previous folder requests are still in
        // flight. An old completion must not masquerade as the new generation.
        strip.items = Array(items.prefix(12))
        _ = render(strip)
        let newFolder = pending; pending.removeAll()
        check(newFolder.count == 12, "reopening a folder creates a new set of requests")
        #if CANCELLABLE_THUMBNAILS
        check(oldFolderTickets.allSatisfy(\.isCancelled), "reopening a folder cancels every previous request")
        #endif
        for item in oldFolder { item.completion(images[2]) }
        let beforeCurrent = render(strip)
        check(!centerMatches(beforeCurrent, column: 0, color: NSColor(srgbRed: 0.12, green: 0.33, blue: 0.92, alpha: 1)), "callbacks from the previous folder cannot paint stale thumbnails")
        check(pending.isEmpty, "old folder callbacks cannot clear the new generation's pending state")
        for item in newFolder { item.completion(images[1]) }
        check(centerMatches(render(strip), column: 0, color: NSColor(srgbRed: 0.1, green: 0.74, blue: 0.24, alpha: 1)), "current folder callbacks display the new thumbnails")

        strip.items = items
        strip.selected = 0
        _ = render(strip)
        let offscreen = pending; pending.removeAll()
        #if CANCELLABLE_THUMBNAILS
        let offscreenTickets = Array(ThumbnailTestMetrics.tickets.suffix(offscreen.count))
        #endif
        strip.selected = 400
        _ = render(strip)
        let onscreen = pending; pending.removeAll()
        #if CANCELLABLE_THUMBNAILS
        check(offscreenTickets.allSatisfy(\.isCancelled), "jumping away cancels slow offscreen thumbnail requests")
        check(ThumbnailTestMetrics.tickets.suffix(onscreen.count).allSatisfy { !$0.isCancelled }, "current visible requests remain active after an offscreen cancellation")
        #endif
        window.displayIfNeeded()
        let offscreenDraws = ThumbnailTestMetrics.draws
        for item in offscreen { item.completion(images[0]) }
        window.displayIfNeeded()
        check(ThumbnailTestMetrics.draws == offscreenDraws, "offscreen completions do not redraw the currently visible strip")
        for item in onscreen { item.completion(images[1]) }
        check(centerMatches(render(strip), column: 11, color: NSColor(srgbRed: 0.1, green: 0.74, blue: 0.24, alpha: 1)), "rightmost visible thumbnail survives late offscreen results")
        check(pending.isEmpty, "completing offscreen work does not resubmit visible thumbnail requests")

        strip.items = Array(items.prefix(12))
        _ = render(strip)
        let closing = pending; pending.removeAll()
        #if CANCELLABLE_THUMBNAILS
        let closingTickets = Array(ThumbnailTestMetrics.tickets.suffix(closing.count))
        #endif
        strip.items = []
        #if CANCELLABLE_THUMBNAILS
        check(closingTickets.allSatisfy(\.isCancelled), "clearing a folder cancels all its outstanding thumbnail requests")
        #endif
        window.displayIfNeeded()
        let clearedDraws = ThumbnailTestMetrics.draws
        for item in closing { item.completion(images[0]) }
        window.displayIfNeeded()
        check(ThumbnailTestMetrics.draws == clearedDraws, "cleared folders ignore callbacks without scheduling another redraw")
        check(pending.isEmpty, "cleared folders leave no new thumbnail work")
        await pause(0.03)
    }

    private enum TestError: Error { case render }
    private static func check(_ condition: Bool, _ label: String) {
        checks += 1
        if condition { print("ok \(checks): \(label)") }
        else { failures.append(label); print("not ok \(checks): \(label)") }
        fflush(stdout)
    }
    @MainActor
    private static func pause(_ seconds: Double) async { try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000)) }
    @MainActor
    private static func waitForImages(_ strip: Filmstrip, colors: [NSColor], timeout: Double) async -> Bool {
        let end = Date().addingTimeInterval(timeout)
        repeat {
            if pixelsMatch(strip, colors: colors) { return true }
            await pause(0.01)
        } while Date() < end
        return pixelsMatch(strip, colors: colors)
    }
    @MainActor
    private static func pixelsMatch(_ strip: Filmstrip, colors: [NSColor]) -> Bool {
        let bitmap = render(strip)
        let first = max(0, min(strip.selected - capacity / 2, strip.items.count - capacity))
        return (0..<min(capacity, strip.items.count)).allSatisfy { centerMatches(bitmap, column: $0, color: colors[(first + $0) % colors.count]) }
    }
    private static func render(_ view: NSView) -> NSBitmapImageRep? {
        guard let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return nil }
        view.cacheDisplay(in: view.bounds, to: bitmap)
        return bitmap
    }
    private static func centerMatches(_ bitmap: NSBitmapImageRep?, column: Int, color: NSColor) -> Bool {
        guard let bitmap else { return false }
        let scale = CGFloat(bitmap.pixelsWide) / width
        let x = Int((20 + CGFloat(column) * 72 + 35) * scale)
        let y = Int((74 - 37) * scale)
        guard let actual = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.sRGB), let expected = color.usingColorSpace(.sRGB) else { return false }
        // AppKit's display profile can adjust RGB components during bitmap
        // caching. These fixtures have distinct hues, so compare their identity
        // after color management instead of assuming a particular display ICC.
        var actualHue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        var expectedHue: CGFloat = 0
        actual.getHue(&actualHue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        expected.getHue(&expectedHue, saturation: nil, brightness: nil, alpha: nil)
        let hueDistance = abs(actualHue - expectedHue)
        return min(hueDistance, 1 - hueDistance) < 0.08 && saturation > 0.35 && brightness > 0.3 && alpha > 0.95
    }
    private static func discardRecreatableCaches(_ strip: Filmstrip) {
        // NSCache may discard any object at any time. Reclaim only those caches;
        // strong references owned by the visible view must remain unaffected.
        for value in Mirror(reflecting: strip).children.map(\.value) {
            (value as? NSCache<NSURL, NSImage>)?.removeAllObjects()
        }
        for value in Mirror(reflecting: strip.loader).children.map(\.value) {
            (value as? NSCache<NSString, NSImage>)?.removeAllObjects()
        }
    }
    private static func makeImage(_ color: NSColor) throws -> NSImage {
        let image = NSImage(size: NSSize(width: 32, height: 24))
        image.lockFocus()
        color.setFill(); NSRect(x: 0, y: 0, width: 32, height: 24).fill()
        image.unlockFocus()
        return image
    }
    private static func saveSnapshot(_ strip: Filmstrip, name: String) throws {
        guard let data = render(strip)?.representation(using: .png, properties: [:]) else { throw TestError.render }
        try data.write(to: output.appendingPathComponent(name))
    }
}
