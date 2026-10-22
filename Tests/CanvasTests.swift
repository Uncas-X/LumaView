import AppKit
import QuartzCore

private struct CanvasTestFailure: Error, CustomStringConvertible {
    let description: String
}

@main
struct CanvasTests {
    private static var checks = 0
    private static var eventTime: UInt64 = DispatchTime.now().uptimeNanoseconds

    static func main() throws {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        var failure: Error?
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { _ in
            do { try runChecks() } catch { failure = error }
            app.stop(nil)
            if let event = NSEvent.otherEvent(with: .applicationDefined, location: .zero, modifierFlags: [], timestamp: 0,
                                              windowNumber: 0, context: nil, subtype: 0, data1: 0, data2: 0) {
                app.postEvent(event, atStart: true)
            }
        }
        app.run()
        if let failure { throw failure }
    }

    private static func runChecks() throws {
        _ = NSApplication.shared
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1000, height: 800),
                              styleMask: [.borderless], backing: .buffered, defer: false)
        let canvas = PhotoCanvas(frame: NSRect(x: 0, y: 0, width: 1000, height: 800))
        canvas.animationsEnabled = false
        window.contentView = canvas
        let scale = window.backingScaleFactor
        let image = try redImage()

        canvas.setImage(image, pixelSize: CGSize(width: 4000, height: 2000))
        try check(canvas.isFit && abs(canvas.zoom - Double(920 * scale / 4000)) < 0.000001, "fit reserves the side margins")
        let landscape = try redBounds(canvas)
        try check(approximately(landscape.width, 920) && approximately(landscape.height, 460), "fit rendering preserves landscape aspect ratio")
        canvas.rotate(1)
        let portrait = try redBounds(canvas)
        try check(canvas.quarterTurns == 1 && approximately(portrait.height, 550) && approximately(portrait.width, 275), "rotation swaps axes and fits between the top and bottom controls")
        canvas.toggleActualSize(at: NSPoint(x: 100, y: 300))
        try check(!canvas.isFit && canvas.zoom == 1, "clicking a fitted image enters actual pixel size")
        canvas.zoomBy(2)
        try check(canvas.zoom == 2, "incremental zoom starts at the current scale")
        canvas.zoomBy(.infinity)
        canvas.zoomBy(-1)
        try check(canvas.zoom == 2, "invalid zoom input cannot corrupt the transform")
        canvas.zoomBy(1000)
        try check(canvas.zoom == 32, "zoom has a finite upper limit")
        canvas.toggleActualSize()
        try check(canvas.isFit, "clicking a manually zoomed image returns to fit")
        canvas.rotate(-1)
        try check(canvas.quarterTurns == 0, "counterclockwise rotation restores the orientation")

        let center = NSPoint(x: 500, y: 445)
        canvas.mouseDown(with: try mouseEvent(.leftMouseDown, at: center, window: window, count: 1))
        canvas.mouseUp(with: try mouseEvent(.leftMouseUp, at: center, window: window, count: 1))
        try check(canvas.zoom == 1 && !canvas.isFit, "a complete single click enters actual size")
        canvas.mouseDown(with: try mouseEvent(.leftMouseDown, at: center, window: window, count: 2))
        canvas.mouseUp(with: try mouseEvent(.leftMouseUp, at: center, window: window, count: 2))
        try check(canvas.zoom == 1 && !canvas.isFit, "the second half of a double click does not undo the first click")
        canvas.mouseDown(with: try mouseEvent(.leftMouseDown, at: center, window: window, count: 1))
        let farRight = NSPoint(x: 10500, y: center.y)
        canvas.mouseDragged(with: try mouseEvent(.leftMouseDragged, at: farRight, window: window, count: 1))
        canvas.mouseUp(with: try mouseEvent(.leftMouseUp, at: farRight, window: window, count: 1))
        try check(!canvas.isFit && canvas.zoom == 1, "dragging pans without triggering the click zoom action")
        let panned = try redBounds(canvas)
        try check(approximately(panned.minX, 40), "pan clamping keeps the image covering the viewport after an extreme drag")

        canvas.setImage(image, pixelSize: CGSize(width: 40, height: 20))
        try check(canvas.isFit && canvas.zoom == 1, "fit does not enlarge small images")
        let actual = try redBounds(canvas)
        try check(approximately(actual.width, 40 / scale) && approximately(actual.height, 20 / scale), "100% maps source pixels to backing pixels, not points")

        var navigation = [Int]()
        canvas.onNavigate = { navigation.append($0) }
        canvas.wheelNavigates = false
        let normalZoom = canvas.zoom
        canvas.scrollWheel(with: try wheelEvent(control: false))
        try check(canvas.zoom > normalZoom && navigation.isEmpty, "default wheel action zooms")
        let modifiedZoom = canvas.zoom
        canvas.scrollWheel(with: try wheelEvent(control: true))
        try check(canvas.zoom == modifiedZoom && navigation == [-1], "Ctrl temporarily changes default zoom to navigation")
        canvas.wheelNavigates = true
        canvas.scrollWheel(with: try wheelEvent(control: false))
        try check(navigation == [-1, -1], "wheel navigation preference switches pictures")
        let invertedZoom = canvas.zoom
        canvas.scrollWheel(with: try wheelEvent(control: true))
        try check(canvas.zoom > invertedZoom && navigation == [-1, -1], "Ctrl temporarily changes navigation preference back to zoom")

        canvas.rotate(1)
        let preservedZoom = canvas.zoom
        canvas.setImage(image, pixelSize: CGSize(width: 40, height: 20), reset: false)
        try check(canvas.quarterTurns == 1 && canvas.zoom == preservedZoom && !canvas.isFit, "animation frame replacement preserves rotation and zoom")
        canvas.setImage(nil, pixelSize: .zero)
        try check(canvas.zoom == 1 && canvas.isFit && canvas.quarterTurns == 0, "opening a new file resets the previous transform")
        canvas.placeholderText = "正在打开…"
        _ = try render(canvas)
        canvas.placeholderText = nil
        _ = try render(canvas)
        try check(canvas.image == nil, "loading and welcome placeholders can both render without a photo")
        try mouseOwnershipChecks(canvas, window: window, image: image)
        try placeholderChecks(canvas, image: image)
        try replacementGeometryChecks(canvas, window: window, image: image)
        try animationChecks(canvas, window: window, image: image)
        print("PASS: \(checks) canvas geometry / rendering / interaction checks")
    }

    private static func replacementGeometryChecks(_ canvas: PhotoCanvas, window: NSWindow, image: CGImage) throws {
        canvas.animationsEnabled = false
        canvas.setImage(image, pixelSize: CGSize(width: 400, height: 250), animated: false)
        canvas.setImage(image, pixelSize: CGSize(width: 600, height: 600), reset: false, animated: false)
        canvas.displayIfNeeded()
        let fitted = try currentLayer(canvas)
        try check(abs(fitted.bounds.width - fitted.bounds.height) < 0.001 && canvas.isFit,
                  "late square artwork replaces a landscape placeholder without stretching")
        canvas.zoomBy(2)
        let zoom = canvas.zoom
        canvas.setImage(image, pixelSize: CGSize(width: 800, height: 400), reset: false, animated: false)
        canvas.displayIfNeeded()
        let changed = try currentLayer(canvas)
        try check(abs(changed.bounds.width / changed.bounds.height - 2) < 0.001 && canvas.zoom == zoom && !canvas.isFit,
                  "different-size artwork preserves user zoom while rebuilding layer geometry")
        let original = try currentLayer(canvas)
        canvas.setImage(image, pixelSize: CGSize(width: 800, height: 400), reset: false, animated: false)
        try check(try currentLayer(canvas) === original, "same-size waveform or animation update retains the existing display layer")
    }

    private static func mouseOwnershipChecks(_ canvas: PhotoCanvas, window: NSWindow, image: CGImage) throws {
        canvas.setImage(image, pixelSize: CGSize(width: 40, height: 20), animated: false)
        var closed = 0
        canvas.onBackgroundClick = { closed += 1 }
        defer { canvas.onBackgroundClick = nil }
        let center = NSPoint(x: 500, y: 445), background = NSPoint(x: 30, y: 30)
        canvas.mouseUp(with: try mouseEvent(.leftMouseUp, at: background, window: window, count: 1))
        try check(closed == 0, "a forwarded mouse-up without a canvas mouse-down cannot close the viewer")
        canvas.mouseUp(with: try mouseEvent(.leftMouseUp, at: center, window: window, count: 1))
        try check(canvas.isFit && canvas.zoom == 1, "a forwarded mouse-up over the photo cannot trigger click zoom")
        let overlay = NSView(frame: NSRect(x: 400, y: 345, width: 200, height: 200))
        canvas.addSubview(overlay)
        canvas.mouseDown(with: try mouseEvent(.leftMouseDown, at: center, window: window, count: 1))
        canvas.mouseUp(with: try mouseEvent(.leftMouseUp, at: center, window: window, count: 1))
        overlay.removeFromSuperview()
        try check(canvas.isFit && closed == 0, "mouse events forwarded from a covering control cannot start a canvas sequence")
        canvas.mouseDown(with: try mouseEvent(.leftMouseDown, at: background, window: window, count: 1))
        canvas.mouseUp(with: try mouseEvent(.leftMouseUp, at: background, window: window, count: 1))
        canvas.mouseUp(with: try mouseEvent(.leftMouseUp, at: background, window: window, count: 1))
        try check(closed == 1, "one genuine background click closes once and consumes its mouse sequence")
        closed = 0
        canvas.mouseDown(with: try mouseEvent(.leftMouseDown, at: background, window: window, count: 1))
        canvas.cancelMouseSequence()
        canvas.mouseUp(with: try mouseEvent(.leftMouseUp, at: background, window: window, count: 1))
        try check(closed == 0, "a new control mouse-down cancels any abandoned canvas click ownership")
        canvas.mouseDown(with: try mouseEvent(.leftMouseDown, at: background, window: window, count: 1))
        canvas.mouseUp(with: try mouseEvent(.leftMouseUp, at: NSPoint(x: 100, y: 100), window: window, count: 1))
        try check(closed == 0, "a background press released at another location cannot close the viewer")
        canvas.mouseDown(with: try mouseEvent(.leftMouseDown, at: center, window: window, count: 1))
        canvas.mouseUp(with: try mouseEvent(.leftMouseUp, at: background, window: window, count: 1))
        try check(canvas.isFit && closed == 0, "releasing a photo press on another target cannot zoom or close")
        let covering = NSView(frame: NSRect(x: 10, y: 10, width: 100, height: 100))
        canvas.mouseDown(with: try mouseEvent(.leftMouseDown, at: background, window: window, count: 1))
        canvas.addSubview(covering)
        canvas.mouseUp(with: try mouseEvent(.leftMouseUp, at: background, window: window, count: 1))
        try check(closed == 0, "a control revealed between mouse-down and mouse-up takes precedence over background close")
        covering.alphaValue = 0.001
        canvas.onShouldBeginMouseSequence = { !covering.frame.contains($0) }
        canvas.mouseDown(with: try mouseEvent(.leftMouseDown, at: background, window: window, count: 1))
        canvas.mouseUp(with: try mouseEvent(.leftMouseUp, at: background, window: window, count: 1))
        try check(closed == 0, "reserved chrome region rejects clicks while its view alpha is too low for AppKit hit testing")
        covering.removeFromSuperview()
        canvas.onShouldBeginMouseSequence = nil
        canvas.mouseDown(with: try mouseEvent(.leftMouseDown, at: background, window: window, count: 1))
        canvas.onShouldBeginMouseSequence = { _ in false }
        canvas.mouseUp(with: try mouseEvent(.leftMouseUp, at: background, window: window, count: 1))
        try check(closed == 0, "mouse-up rechecks the controller's protected region gate")
        canvas.onShouldBeginMouseSequence = nil
    }

    private static func placeholderChecks(_ canvas: PhotoCanvas, image: CGImage) throws {
        let originalBackground = canvas.backgroundMode
        var backgroundChanges = 0
        canvas.onBackgroundModeChanged = { backgroundChanges += 1 }
        canvas.backgroundMode = .dark
        try check(backgroundChanges == 1, "direct background changes notify the controller to update its glass backdrop")
        canvas.onBackgroundModeChanged = nil
        canvas.setImage(nil, pixelSize: .zero, animated: false)
        canvas.placeholderText = nil
        canvas.updateLayer()
        guard let placeholder = canvas.layer?.sublayers?.first(where: { $0.name == "photo-placeholder" }) else {
            throw CanvasTestFailure(description: "empty state installs its placeholder layer")
        }
        try check(placeholder.contents != nil && !placeholder.isHidden, "welcome texture is visible before opening a photo")
        // Model the stale backing texture that can survive a cached empty-state display.
        canvas.layer?.contents = placeholder.contents
        canvas.setImage(image, pixelSize: CGSize(width: 40, height: 20), animated: false)
        try check(placeholder.isHidden && placeholder.contents == nil && placeholder.superlayer == nil,
                  "opening a photo immediately clears and detaches the welcome texture before the next display pass")
        try check(canvas.layer?.contents == nil, "opening a photo clears any stale root backing texture")
        canvas.zoomBy(0.01)
        canvas.updateLayer()
        try check(try strayBackgroundPixels(canvas) == 0, "1% zoom leaves a clean GPU background with no welcome letters or placeholder remnants")
        canvas.beginImageLoading()
        canvas.updateLayer()
        try check(placeholder.contents == nil && placeholder.superlayer == nil,
                  "loading another photo preserves the displayed photo without restoring the welcome layer")
        canvas.placeholderText = "图片暂时无法显示\n按 ← → 继续浏览"
        canvas.setImage(nil, pixelSize: .zero, animated: false)
        canvas.updateLayer()
        let host = canvas.layer?.sublayers?.first(where: { $0.name == "photo-host" })
        try check(placeholder.contents != nil && !placeholder.isHidden && host?.sublayers?.isEmpty != false,
                  "a failed decode displays its error texture and removes every previous photo layer")
        canvas.setImage(image, pixelSize: CGSize(width: 40, height: 20), animated: false)
        canvas.zoomBy(0.01)
        canvas.updateLayer()
        try check(placeholder.contents == nil && placeholder.superlayer == nil && canvas.placeholderText == nil,
                  "opening a valid photo after an error clears both error text and its GPU texture")
        try check(try strayBackgroundPixels(canvas) == 0, "welcome-to-photo-to-error-to-photo leaves no text behind at 1% zoom")
        canvas.setImage(nil, pixelSize: .zero, animated: false)
        canvas.updateLayer()
        try check(placeholder.superlayer === canvas.layer && placeholder.contents != nil && !placeholder.isHidden,
                  "returning to an empty view regenerates its welcome texture after clearing the photo")
        canvas.backgroundMode = originalBackground
    }

    private static func strayBackgroundPixels(_ canvas: PhotoCanvas) throws -> Int {
        let pixels = try render(canvas, useLayers: true)
        let width = Int(canvas.bounds.width), height = Int(canvas.bounds.height)
        var brightPixels = 0
        for y in 0..<height {
            for x in 0..<width {
                // Leave a small area for the tiny image and its antialiased edges.
                if abs(x - width / 2) < 20 && abs(y - (height / 2 - 45)) < 20 { continue }
                let offset = (y * width + x) * 4
                if pixels[offset] > 90 || pixels[offset + 1] > 90 || pixels[offset + 2] > 90 { brightPixels += 1 }
            }
        }
        return brightPixels
    }

    private static func animationChecks(_ canvas: PhotoCanvas, window: NSWindow, image: CGImage) throws {
        // A visible test window receives WindowServer animation-completion callbacks.
        window.alphaValue = 1
        window.orderFrontRegardless()
        defer { window.orderOut(nil) }
        canvas.setImage(image, pixelSize: CGSize(width: 400, height: 200), animated: false)
        canvas.animationsEnabled = true
        canvas.displayIfNeeded()
        CATransaction.flush()
        pump(0.06)
        guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
            canvas.zoomBy(2)
            try check(!canvas.isAnimating, "Reduce Motion disables image motion")
            return
        }
        canvas.zoomBy(1.5)
        try check(canvas.zoom == 1.5 && canvas.isAnimating, "zoom target updates before its presentation settles")
        CATransaction.flush()
        pump(0.045)
        let container = try currentLayer(canvas)
        let shownBeforeRetarget = presentationScale(container)
        try check(shownBeforeRetarget > 1 && shownBeforeRetarget < 1.5, "real presentation tree shows intermediate eased zoom (scale \(shownBeforeRetarget), presentation \(container.presentation() != nil))")
        canvas.zoomBy(1.25)
        guard let zoomAnimation = container.animation(forKey: "zoom") as? CABasicAnimation,
              let retargetStart = zoomAnimation.fromValue as? NSNumber else { throw CanvasTestFailure(description: "retarget zoom animation") }
        try check(canvas.zoom == 1.875 && abs(retargetStart.doubleValue - shownBeforeRetarget) < 0.035, "rapid wheel retarget continues from presentation while accumulating target zoom")
        canvas.setImage(image, pixelSize: CGSize(width: 400, height: 200), reset: false, animated: false)
        try check(try currentLayer(canvas) === container && container.animation(forKey: "zoom") != nil && container.animation(forKey: "imageFade") == nil,
                  "animation frames preserve an in-flight zoom without creating a file transition")
        CATransaction.flush()
        pump(0.3)
        settle(canvas)
        try check(!canvas.isAnimating && abs(presentationScale(container) - 1.875) < 0.001, "zoom settles at its target and releases animation objects (scale \(presentationScale(container)), keys \(container.animationKeys() ?? []), active \(canvas.isAnimating))")
        let actualGPU = try redBounds(canvas, useLayers: true)
        try check(approximately(actualGPU.width, 750 / window.backingScaleFactor) && approximately(actualGPU.height, 375 / window.backingScaleFactor),
                  "settled CALayer pixels have the expected zoom and aspect ratio (bounds \(actualGPU), backing \(window.backingScaleFactor))")

        let asymmetric = try asymmetricImage()
        canvas.setImage(asymmetric, pixelSize: CGSize(width: 400, height: 200), animated: false)
        canvas.displayIfNeeded()
        CATransaction.flush()
        pump(0.03)
        let cpu = try render(canvas), gpu = try render(canvas, useLayers: true)
        let s = window.backingScaleFactor
        for (index, point) in [CGPoint(x: 500 - 100 / s, y: 445 - 50 / s), CGPoint(x: 500 + 100 / s, y: 445 + 50 / s)].enumerated() {
            let offset = (Int(canvas.bounds.height - point.y) * 1000 + Int(point.x)) * 4
            try check(cpu[offset + index] > 240 && cpu[offset + 2] < 10, "orientation sample hits the fixture's distinct red or green quadrant")
            try check((0..<3).allSatisfy { abs(Int(cpu[offset + $0]) - Int(gpu[offset + $0])) < 3 }, "CALayer texture orientation matches asymmetric CGImage draw (rootFlipped \(canvas.layer?.isGeometryFlipped ?? false), CPU \(Array(cpu[offset..<(offset+3)])), GPU \(Array(gpu[offset..<(offset+3)])))")
        }
        canvas.rotate(1)
        try check(canvas.quarterTurns == 1 && (try currentLayer(canvas)).animation(forKey: "rotation") != nil, "rotation updates its target and animates the displayed angle")
        CATransaction.flush()
        pump(0.28)
        settle(canvas)
        try check(!canvas.isAnimating, "rotation animation is removed after settling")

        canvas.setImage(image, pixelSize: CGSize(width: 4000, height: 2000), animated: false)
        canvas.zoomBy(4)
        let queuedZoom = canvas.zoom
        CATransaction.flush()
        pump(0.045)
        let dragLayer = try currentLayer(canvas)
        let beforeDrag = presentationScale(dragLayer)
        let center = NSPoint(x: 500, y: 445)
        canvas.mouseDown(with: try mouseEvent(.leftMouseDown, at: center, window: window, count: 1))
        canvas.mouseDragged(with: try mouseEvent(.leftMouseDragged, at: NSPoint(x: 530, y: 445), window: window, count: 1))
        canvas.mouseUp(with: try mouseEvent(.leftMouseUp, at: NSPoint(x: 530, y: 445), window: window, count: 1))
        try check(canvas.zoom < queuedZoom && abs(canvas.zoom - beforeDrag) < 0.035, "drag interrupts at the visible scale instead of jumping to the queued target")
        try check(dragLayer.animation(forKey: "zoom") == nil && dragLayer.animation(forKey: "pan") == nil, "drag position and scale track the finger without easing")

        canvas.beginImageLoading()
        try check(canvas.image === image, "starting a decode keeps the previous photo visible")
        canvas.setImage(asymmetric, pixelSize: CGSize(width: 40, height: 20), quarterTurns: 1)
        try check(canvas.quarterTurns == 1 && canvas.zoom == 1 && canvas.isAnimating, "incoming photo applies saved rotation atomically before its fade")
        try check(outgoingCount(canvas) == 1, "a file transition retains exactly one outgoing photo")
        CATransaction.flush()
        pump(0.035)
        canvas.setImage(image, pixelSize: CGSize(width: 40, height: 20))
        try check(outgoingCount(canvas) == 1, "rapid file switching collapses the visible composition to one outgoing layer")
        let arriving = try currentLayer(canvas)
        canvas.setImage(asymmetric, pixelSize: CGSize(width: 40, height: 20), reset: false, animated: false)
        try check(arriving.animation(forKey: "imageFade") != nil && (try currentLayer(canvas)) === arriving,
                  "animated frame update does not restart or cancel the incoming file fade")
        CATransaction.flush()
        pump(0.3)
        settle(canvas)
        try check(outgoingCount(canvas) == 0 && !canvas.isAnimating, "completed transitions dispose old textures and animation state")
        canvas.zoomBy(2)
        canvas.animationsEnabled = false
        try check(!canvas.isAnimating, "explicit animation override immediately finishes active transitions")
    }

    private static func currentLayer(_ canvas: PhotoCanvas) throws -> CALayer {
        guard let current = canvas.layer?.sublayers?.first(where: { $0.name == "photo-host" })?.sublayers?.first(where: { $0.name == "photo-current" }) else {
            throw CanvasTestFailure(description: "current GPU photo layer exists")
        }
        return current
    }

    private static func outgoingCount(_ canvas: PhotoCanvas) -> Int {
        canvas.layer?.sublayers?.first(where: { $0.name == "photo-host" })?.sublayers?.filter { $0.name == "photo-outgoing" }.count ?? 0
    }

    private static func presentationScale(_ layer: CALayer) -> Double {
        let t = (layer.presentation() ?? layer).transform
        return Double(sqrt(t.m11 * t.m11 + t.m12 * t.m12))
    }

    private static func pump(_ duration: TimeInterval) {
        let end = Date().addingTimeInterval(duration)
        while Date() < end {
            CATransaction.flush()
            RunLoop.main.run(until: Date().addingTimeInterval(0.005))
        }
    }

    private static func settle(_ canvas: PhotoCanvas) {
        let end = Date().addingTimeInterval(2)
        while canvas.isAnimating && Date() < end { pump(0.02) }
    }

    private static func asymmetricImage() throws -> CGImage {
        guard let context = CGContext(data: nil, width: 40, height: 20, bitsPerComponent: 8, bytesPerRow: 160,
                                      space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw CanvasTestFailure(description: "asymmetric fixture context")
        }
        context.setFillColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 40, height: 20))
        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 20, height: 10))
        context.setFillColor(CGColor(red: 0, green: 1, blue: 0, alpha: 1))
        context.fill(CGRect(x: 20, y: 10, width: 20, height: 10))
        guard let image = context.makeImage() else { throw CanvasTestFailure(description: "asymmetric fixture image") }
        return image
    }

    private static func check(_ condition: @autoclosure () throws -> Bool, _ message: String) throws {
        guard try condition() else { throw CanvasTestFailure(description: message) }
        checks += 1
    }

    private static func approximately(_ a: CGFloat, _ b: CGFloat) -> Bool { abs(a - b) < 2.1 }

    private static func redImage() throws -> CGImage {
        guard let context = CGContext(data: nil, width: 40, height: 20, bitsPerComponent: 8, bytesPerRow: 160,
                                      space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw CanvasTestFailure(description: "create fixture context")
        }
        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 40, height: 20))
        guard let image = context.makeImage() else { throw CanvasTestFailure(description: "create fixture image") }
        return image
    }

    /// Draw at one output pixel per view point so Retina scaling remains measurable.
    private static func render(_ canvas: PhotoCanvas, useLayers: Bool = false) throws -> [UInt8] {
        let width = Int(canvas.bounds.width), height = Int(canvas.bounds.height)
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        try pixels.withUnsafeMutableBytes { storage in
            guard let context = CGContext(data: storage.baseAddress, width: width, height: height,
                                          bitsPerComponent: 8, bytesPerRow: width * 4,
                                          space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
                throw CanvasTestFailure(description: "create snapshot context")
            }
            NSGraphicsContext.saveGraphicsState()
            defer { NSGraphicsContext.restoreGraphicsState() }
            NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
            if useLayers { canvas.layer?.render(in: context) }
            else { canvas.draw(canvas.bounds) }
        }
        return pixels
    }

    private static func redBounds(_ canvas: PhotoCanvas, useLayers: Bool = false) throws -> CGRect {
        let width = Int(canvas.bounds.width), height = Int(canvas.bounds.height)
        let pixels = try render(canvas, useLayers: useLayers)
        var minimumX = width, minimumY = height, maximumX = -1, maximumY = -1
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                if pixels[offset] > 180 && pixels[offset + 1] < 90 && pixels[offset + 2] < 90 {
                    minimumX = min(minimumX, x); minimumY = min(minimumY, y)
                    maximumX = max(maximumX, x); maximumY = max(maximumY, y)
                }
            }
        }
        guard maximumX >= minimumX else { throw CanvasTestFailure(description: "rendered photo is visible") }
        return CGRect(x: minimumX, y: minimumY, width: maximumX - minimumX + 1, height: maximumY - minimumY + 1)
    }

    private static func wheelEvent(control: Bool) throws -> NSEvent {
        guard let cgEvent = CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 1, wheel1: 1, wheel2: 0, wheel3: 0) else {
            throw CanvasTestFailure(description: "create wheel event")
        }
        eventTime += 1_000_000_000
        cgEvent.timestamp = eventTime
        cgEvent.flags = control ? [.maskControl] : []
        guard let event = NSEvent(cgEvent: cgEvent) else { throw CanvasTestFailure(description: "convert wheel event") }
        return event
    }

    private static func mouseEvent(_ type: NSEvent.EventType, at point: NSPoint, window: NSWindow, count: Int) throws -> NSEvent {
        guard let event = NSEvent.mouseEvent(with: type, location: point, modifierFlags: [], timestamp: 1,
                                            windowNumber: window.windowNumber, context: nil,
                                            eventNumber: 0, clickCount: count, pressure: 1) else {
            throw CanvasTestFailure(description: "create mouse event")
        }
        return event
    }
}
