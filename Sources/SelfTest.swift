import AppKit
import ImageIO
import QuartzCore
import UniformTypeIdentifiers

/// Opt-in local integration harness. It only creates fixtures inside the supplied directory.
func runViewerSelfTests(_ viewer: ViewerController, output: URL) {
    var report: [String] = [], failures = 0
    var diagnostics: [String] = []
    func check(_ condition: @autoclosure () -> Bool, _ message: String) {
        let passed = condition(); report.append("\(passed ? "PASS" : "FAIL") \(message)")
        if !passed { failures += 1 }
    }
    func spin(_ condition: () -> Bool, timeout: TimeInterval = 8) -> Bool {
        let end = Date().addingTimeInterval(timeout)
        repeat {
            // The harness runs many actions in one callback. Commit the same
            // implicit transaction that a normal AppKit event boundary would.
            CATransaction.flush()
            if condition() { return true }
            RunLoop.main.run(until: Date().addingTimeInterval(0.025))
        } while Date() < end
        return condition()
    }
    func key(_ text: String, code: UInt16 = 0, mods: NSEvent.ModifierFlags = []) {
        if let event = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: mods, timestamp: 1, windowNumber: viewer.window!.windowNumber, context: nil, characters: text, charactersIgnoringModifiers: text, isARepeat: false, keyCode: code) { _ = viewer.handleKey(event) }
    }
    var mouseEventNumber = 100
    /// Route real down/up events through the window, including controls whose
    /// mouseDown enters AppKit's nested button or text-selection tracking loop.
    func click(_ view: NSView, at point: NSPoint? = nil, revealBeforeClick: Bool = true,
               validateTarget: Bool = true, settle: TimeInterval = 0.25) -> Bool {
        guard let window = viewer.window, window.isVisible else { return false }
        if revealBeforeClick { viewer.revealChrome() }
        viewer.root.layoutSubtreeIfNeeded(); window.display(); CATransaction.flush()
        let location = view.convert(point ?? NSPoint(x: view.bounds.midX, y: view.bounds.midY), to: nil)
        let hit = viewer.root.hitTest(viewer.root.convert(location, from: nil))
        guard !validateTarget || hit === view || hit?.isDescendant(of: view) == true else {
            diagnostics.append("DIAGNOSTIC click target: expected=\(type(of: view)), hit=\(String(describing: hit.map { type(of: $0) }))")
            return false
        }
        mouseEventNumber += 2
        let timestamp = ProcessInfo.processInfo.systemUptime
        guard let down = NSEvent.mouseEvent(with: .leftMouseDown, location: location, modifierFlags: [], timestamp: timestamp,
                                           windowNumber: window.windowNumber, context: nil, eventNumber: mouseEventNumber, clickCount: 1, pressure: 1),
              let up = NSEvent.mouseEvent(with: .leftMouseUp, location: location, modifierFlags: [], timestamp: timestamp + 0.01,
                                         windowNumber: window.windowNumber, context: nil, eventNumber: mouseEventNumber + 1, clickCount: 1, pressure: 0) else { return false }
        NSApp.postEvent(up, atStart: true)
        window.sendEvent(down)
        // A custom view may not enter a tracking loop; deliver its queued up too.
        while let event = NSApp.nextEvent(matching: .leftMouseUp, until: Date(), inMode: .default, dequeue: true) {
            if event.windowNumber == window.windowNumber { window.sendEvent(event) }
            else { NSApp.sendEvent(event) }
        }
        if settle > 0 { _ = spin({ false }, timeout: settle) }
        return true
    }
    func moveMouse(_ view: NSView, to point: NSPoint) {
        guard let window = viewer.window,
              let event = NSEvent.mouseEvent(with: .mouseMoved, location: view.convert(point, to: nil), modifierFlags: [],
                                             timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber,
                                             context: nil, eventNumber: 0, clickCount: 0, pressure: 0) else { return }
        window.sendEvent(event)
    }
    func thumbnailSlot(_ slot: Int) -> (point: NSPoint, index: Int) {
        let capacity = max(1, Int((viewer.strip.bounds.width - 24) / 72))
        let firstVisible = max(0, min(viewer.selectedIndex - capacity / 2, viewer.items.count - capacity))
        let count = min(capacity, viewer.items.count)
        let position = max(0, min(slot, count - 1))
        let start = (viewer.strip.bounds.width - CGFloat(count) * 72) / 2
        return (NSPoint(x: start + CGFloat(position) * 72 + 35, y: 35), firstVisible + position)
    }
    func viewerRemainsOpen() -> Bool { viewer.window?.isVisible == true && !viewer.isClosing }
    func snapshot(_ name: String) {
        CATransaction.flush()
        _ = spin({ !viewer.canvas.isAnimating }, timeout: 1)
        viewer.revealChrome(); viewer.root.layoutSubtreeIfNeeded(); viewer.window?.display()
        CATransaction.flush()
        guard let bitmap = viewer.root.bitmapImageRepForCachingDisplay(in: viewer.root.bounds) else { check(false, "Allocate snapshot \(name)"); return }
        viewer.root.cacheDisplay(in: viewer.root.bounds, to: bitmap)
        guard let data = bitmap.representation(using: .png, properties: [:]) else { check(false, "Encode snapshot \(name)"); return }
        do { try data.write(to: output.appendingPathComponent(name)); check(data.count > 1_000, "Render \(name)") }
        catch { check(false, "Write snapshot \(name): \(error)") }
    }
    func fixture(_ name: String, width: Int = 1800, height: Int = 1125, variant: Int = 0) throws -> URL {
        let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let w = CGFloat(width), h = CGFloat(height)
        let colors = [NSColor(srgbRed: 0.08, green: 0.20, blue: 0.27, alpha: 1).cgColor,
                      NSColor(srgbRed: 0.76, green: 0.79, blue: 0.72, alpha: 1).cgColor]
        ctx.drawLinearGradient(CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors as CFArray, locations: [0, 1])!, start: CGPoint(x: 0, y: h), end: CGPoint(x: w * 0.3, y: 0), options: [])
        ctx.setFillColor(NSColor(srgbRed: 0.96, green: 0.77, blue: 0.42, alpha: 1).cgColor)
        ctx.fillEllipse(in: CGRect(x: w * 0.68, y: h * 0.63, width: h * 0.12, height: h * 0.12))
        for layer in 0..<4 {
            let base = h * (0.18 + Double(layer) * 0.12)
            ctx.beginPath(); ctx.move(to: CGPoint(x: 0, y: 0)); ctx.addLine(to: CGPoint(x: 0, y: base))
            for step in 0...16 {
                let x = CGFloat(step) * w / 16
                let y = base + sin(CGFloat(step) * 0.55 + CGFloat(layer + variant)) * h * 0.11 + cos(CGFloat(step) * 1.1) * h * 0.035
                ctx.addLine(to: CGPoint(x: x, y: y))
            }
            ctx.addLine(to: CGPoint(x: w, y: 0)); ctx.closePath()
            let tone = CGFloat(3 - layer) * 0.09
            ctx.setFillColor(NSColor(srgbRed: 0.1 + tone, green: 0.22 + tone, blue: 0.24 + tone, alpha: 1).cgColor); ctx.fillPath()
        }
        let url = output.appendingPathComponent("fixtures", isDirectory: true).appendingPathComponent(name)
        let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, ctx.makeImage()!, [kCGImageDestinationLossyCompressionQuality: 0.92] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw NSError(domain: "fixtures", code: 1) }; return url
    }
    do {
        try FileManager.default.createDirectory(at: output.appendingPathComponent("fixtures"), withIntermediateDirectories: true)
        try? FileManager.default.removeItem(at: output.appendingPathComponent("fixtures/损坏.jpg"))
        viewer.window?.setContentSize(NSSize(width: 1100, height: 760))
        viewer.canvas.backgroundMode = .dark; viewer.showFilmstrip = true; viewer.looping = true; viewer.sort = .name
        viewer.show(); viewer.layoutChrome()
        let defaultViewerItem = NSApp.mainMenu?.items.first?.submenu?.items.first {
            $0.action == #selector(ViewerController.showDefaultViewerPreferences)
        }
        check(defaultViewerItem?.target === viewer && defaultViewerItem.map(viewer.validateMenuItem) == true,
              "Format-selection preferences are available from the app menu before opening media")
        snapshot("01-welcome.png")
        let first = try fixture("旅途 01.jpg"), second = try fixture("旅途 02.jpg", width: 1200, height: 1800, variant: 2)
        _ = try fixture("旅途 10.jpg", width: 2400, height: 1200, variant: 4)
        let original = try Data(contentsOf: second)
        viewer.open([second])
        check(spin { viewer.loaded != nil && viewer.currentURL == second }, "Open selected image asynchronously")
        check(viewer.items.count == 3 && viewer.selectedIndex == 1, "Expand folder with natural order and selected file")
        check(viewer.loaded?.pixelSize == CGSize(width: 1200, height: 1800), "Decode original portrait resolution")
        check(viewer.canvas.isFit, "Initially fit image")
        viewer.window?.setContentSize(NSSize(width: 1100, height: 760)); viewer.layoutChrome()
        viewer.actualSize(); check(abs(viewer.canvas.zoom - 1) < 0.0001, "100% actual physical pixels")
        viewer.zoomIn(); check(viewer.canvas.zoom > 1, "Zoom beyond 100%")
        viewer.fit(); check(viewer.canvas.isFit, "Restore fit")
        key("r", mods: .control); check(viewer.canvas.quarterTurns == 1, "Picasa Ctrl+R rotation")
        key("r", mods: [.control, .shift]); check(viewer.canvas.quarterTurns == 0, "Reverse rotation")
        viewer.rotateRight()
        let visibleBeforeNavigation = viewer.canvas.image
        viewer.nextImage()
        check(visibleBeforeNavigation != nil && viewer.canvas.image === visibleBeforeNavigation, "Retain previous visible image while next image decodes")
        check(viewer.canvas.quarterTurns == 1, "Keep previous image rotation until replacement is ready")
        check(spin { viewer.loaded != nil && viewer.selectedIndex == 2 }, "Navigate next image")
        check(viewer.canvas.quarterTurns == 0, "Apply replacement image and its saved rotation together")
        viewer.previous()
        check(spin { viewer.loaded != nil && viewer.selectedIndex == 1 }, "Navigate previous image")
        check(viewer.canvas.quarterTurns == 1, "Remember display rotation per image")
        viewer.rotateLeft()
        let afterViewing = try Data(contentsOf: second)
        check(afterViewing == original, "Viewing and rotation leave original bytes unchanged")
        let oldBG = viewer.canvas.backgroundMode
        key(" ", code: 49); check(viewer.canvas.backgroundMode != oldBG, "Space cycles background")
        viewer.canvas.backgroundMode = .dark
        key("t"); check(!viewer.showFilmstrip, "T hides filmstrip"); key("t")
        viewer.lastImage(); check(spin { viewer.loaded != nil && viewer.selectedIndex == 2 }, "End selects final image")
        viewer.nextImage(); check(spin { viewer.loaded != nil && viewer.selectedIndex == 0 }, "Loop from last to first")
        viewer.looping = false; viewer.previous(); check(viewer.selectedIndex == 0, "No-loop stops at first")
        for i in 0..<18 { viewer.select(i % 3) }; viewer.select(1)
        check(spin { viewer.loaded != nil && viewer.selectedIndex == 1 }, "Rapid navigation settles on latest request")
        check(viewer.loaded?.pixelSize == CGSize(width: 1200, height: 1800), "Stale image never replaces latest selection")
        viewer.select(2)
        let transitionSourceReady = spin { viewer.loaded != nil && viewer.selectedIndex == 2 }
        viewer.select(0); viewer.select(1)
        let interruptedTransitionSettled = spin {
            viewer.loaded != nil && viewer.selectedIndex == 1 && !viewer.canvas.isAnimating
        }
        let transitionPassed = transitionSourceReady && interruptedTransitionSettled && viewer.canvas.image === viewer.loaded?.image
            && viewer.canvas.image?.width == 1200 && viewer.canvas.image?.height == 1800
        if !transitionPassed {
            let loadedSize = viewer.loaded.map { "\($0.image.width)x\($0.image.height)" } ?? "nil"
            let canvasSize = viewer.canvas.image.map { "\($0.width)x\($0.height)" } ?? "nil"
            diagnostics.append("DIAGNOSTIC overlapping transition: sourceReady=\(transitionSourceReady), settled=\(interruptedTransitionSettled), selectedIndex=\(viewer.selectedIndex), currentURL=\(viewer.currentURL?.lastPathComponent ?? "nil"), loaded=\(loadedSize), canvas=\(canvasSize), sameImage=\(viewer.canvas.image === viewer.loaded?.image), isAnimating=\(viewer.canvas.isAnimating), appActive=\(NSApp.isActive), appRunning=\(NSApp.isRunning)")
        }
        check(transitionPassed,
              "Overlapping image transitions settle on the latest canvas image")
        viewer.slideInterval = 0.12; viewer.firstImage()
        check(spin { viewer.loaded != nil && viewer.selectedIndex == 0 }, "Ready for slideshow")
        viewer.toggleSlideshow()
        check(spin({ !viewer.isPlaying && viewer.selectedIndex == 2 }, timeout: 5), "Non-loop slideshow advances and stops on final image")
        viewer.looping = true; viewer.slideInterval = 3
        viewer.toggleSlideshow(); key("", code: 53); check(!viewer.isPlaying, "Escape pauses slideshow first")
        viewer.closeOnBackground = true
        viewer.window?.makeFirstResponder(viewer.canvas)
        let visibleThumbnailCount = min(max(1, Int((viewer.strip.bounds.width - 24) / 72)), viewer.items.count)
        let thumbnailStart = (viewer.strip.bounds.width - CGFloat(visibleThumbnailCount) * 72) / 2
        let clickedThumbnail = click(viewer.strip, at: NSPoint(x: thumbnailStart + 72 + 35, y: 35))
        check(clickedThumbnail && spin { viewer.loaded != nil && viewer.currentURL == second && viewerRemainsOpen() },
              "Real thumbnail mouse down/up selects the image without closing")
        viewer.window?.makeFirstResponder(viewer.canvas)
        let clickedFileTitle = click(viewer.fileLabel, at: NSPoint(x: 20, y: 8))
        check(clickedFileTitle && viewerRemainsOpen(), "Real filename text click does not close the viewer")
        let clickedInfo = viewer.buttons["info"].map { click($0) } ?? false
        check(clickedInfo && spin { !viewer.infoPanel.isHidden && viewer.infoPanel.alphaValue > 0.99 && viewerRemainsOpen() },
              "Real information button click opens the panel without closing")
        viewer.window?.makeFirstResponder(viewer.canvas)
        let clickedTitle = click(viewer.infoText, at: NSPoint(x: 20, y: viewer.infoText.bounds.height - 15))
        check(clickedTitle && viewerRemainsOpen(), "Real information title click does not close the viewer")
        viewer.window?.makeFirstResponder(viewer.canvas)
        let clickedMetadata = click(viewer.infoText, at: NSPoint(x: 20, y: viewer.infoText.bounds.height - 70))
        check(clickedMetadata && viewerRemainsOpen(), "Real metadata text click does not close the viewer")
        viewer.window?.makeFirstResponder(viewer.canvas)
        let clickedInfoPadding = click(viewer.infoPanel, at: NSPoint(x: 5, y: 5))
        check(clickedInfoPadding && viewerRemainsOpen(), "Real information-panel padding click stays inside the panel")
        viewer.window?.makeFirstResponder(viewer.canvas)
        let clickedInfoClose = viewer.buttons["closeInfo"].map { click($0) } ?? false
        check(clickedInfoClose && spin { viewer.infoPanel.isHidden && viewerRemainsOpen() },
              "Real information close button hides only the panel")
        viewer.window?.makeFirstResponder(viewer.canvas)
        let clickedDockPadding = click(viewer.dock, at: NSPoint(x: 5, y: 5))
        check(clickedDockPadding && viewerRemainsOpen(), "Real dock-padding mouse down/up does not close the viewer")
        check(viewer.openButton.superview == nil, "Welcome open button leaves the view hierarchy while viewing images")
        viewer.select(0); check(spin { viewer.loaded != nil && viewer.currentURL == first }, "Load landscape for preview")
        viewer.toast.isHidden = true
        _ = spin({ false }, timeout: 0.25)
        snapshot("02-viewer.png")
        viewer.canvas.zoomBy(0.01 / viewer.canvas.zoom)
        _ = spin { !viewer.canvas.isAnimating }
        viewer.canvas.displayIfNeeded(); CATransaction.flush()
        check(abs(viewer.canvas.zoom - 0.01) < 0.00001, "Smallest 1% view retains its requested zoom")
        check(viewer.canvas.backgroundMode == .dark && viewer.canvas.layer?.backgroundColor?.alpha == 1,
              "Dark viewing background is fully opaque")
        snapshot("05-small-1-percent.png")
        viewer.fit(); _ = spin { !viewer.canvas.isAnimating }
        viewer.toggleInfo(); snapshot("03-information.png"); viewer.toggleInfo()
        viewer.canvas.backgroundMode = .translucent
        viewer.layoutChrome(); viewer.canvas.displayIfNeeded(); CATransaction.flush()
        check(!viewer.backdrop.isHidden && viewer.backdrop.material == .hudWindow
              && viewer.backdrop.blendingMode == .behindWindow && viewer.backdrop.frame == viewer.root.bounds
              && (viewer.canvas.layer?.backgroundColor?.alpha ?? 1) < 1,
              "Translucent mode installs a full-window behind-window glass backdrop")
        snapshot("04-transparent.png")
        viewer.canvas.backgroundMode = .dark
        viewer.canvas.displayIfNeeded(); CATransaction.flush()
        check(viewer.backdrop.isHidden && viewer.canvas.layer?.backgroundColor?.alpha == 1,
              "Dark mode hides the glass backdrop and restores an opaque canvas")
        let invalid = output.appendingPathComponent("fixtures/损坏.jpg")
        try Data("not an image".utf8).write(to: invalid)
        viewer.open([invalid])
        check(spin { viewer.currentURL == invalid && viewer.canvas.placeholderText?.contains("暂时") == true }, "Corrupt image shows recoverable error")
        viewer.firstImage(); check(spin { viewer.loaded != nil }, "Continue viewing after corrupt image")
        viewer.stopSlideshow()
        viewer.toggleFullscreen()
        check(spin({ viewer.window?.styleMask.contains(.fullScreen) == true && !viewer.fullScreenTransitioning }, timeout: 6), "Complete native macOS fullscreen entry")
        key("", code: 53)
        check(spin({ viewer.window?.styleMask.contains(.fullScreen) == false && !viewer.fullScreenTransitioning }, timeout: 6), "Escape completes native fullscreen exit")
        viewer.closeViewer()
        viewer.show()
        _ = spin({ false }, timeout: 0.4)
        check(viewer.window?.isVisible == true && (viewer.window?.alphaValue ?? 0) > 0.99 && !viewer.isClosing,
              "Showing during close cancels the stale fade completion")
        let restoredInput = viewer.window?.firstResponder === viewer.canvas && viewer.window?.ignoresMouseEvents == false
            && viewer.window?.isKeyWindow == true
        if !restoredInput {
            let responderType = (viewer.window?.firstResponder).map { String(describing: type(of: $0)) } ?? "nil"
            diagnostics.append("DIAGNOSTIC interrupted-close input: firstResponder=\(responderType), responderIsCanvas=\(viewer.window?.firstResponder === viewer.canvas), ignoresMouseEvents=\(String(describing: viewer.window?.ignoresMouseEvents)), isKeyWindow=\(String(describing: viewer.window?.isKeyWindow)), canBecomeKey=\(String(describing: viewer.window?.canBecomeKey)), visible=\(String(describing: viewer.window?.isVisible)), alpha=\(String(describing: viewer.window?.alphaValue)), isClosing=\(viewer.isClosing), appActive=\(NSApp.isActive), appRunning=\(NSApp.isRunning)")
        }
        check(restoredInput,
              "Interrupted close restores mouse input and keyboard focus")
        viewer.select(viewer.items.firstIndex(where: { $0.url == second }) ?? 0)
        viewer.closeViewer(); viewer.show()
        check(spin { viewer.loaded != nil && viewer.currentURL == second && viewer.canvas.image === viewer.loaded?.image
                     && !viewer.canvas.isAnimating && !viewer.isClosing && viewer.window?.isVisible == true
                     && (viewer.window?.alphaValue ?? 0) > 0.99 },
              "Showing during a pending-load close restarts the selected decode")
        let staticImageBeforeClose = viewer.loaded?.image
        let wasStaticImage = viewer.loaded?.frameCount == 1
        viewer.closeViewer()
        check(NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
              || (viewer.isClosing && viewer.window?.isVisible == true),
              "Close keeps the window visible while fading when Reduce Motion is off")
        check(spin({ viewer.window?.isVisible == false && !viewer.isClosing }, timeout: 2),
              "Close finishes its fade and then hides the window")
        viewer.show()
        check(wasStaticImage && staticImageBeforeClose != nil && spin {
            viewer.window?.isVisible == true && !viewer.isClosing && (viewer.window?.alphaValue ?? 0) > 0.99
                && viewer.currentURL == second && viewer.canvas.image != nil
                && viewer.canvas.image === staticImageBeforeClose && viewer.canvas.image === viewer.loaded?.image
                && !viewer.canvas.isAnimating
        }, "Showing after completed close restores the retained static image without relying on an animation timer")
        viewer.closeViewer()
        let restoredViewerClosed = spin({ viewer.window?.isVisible == false && !viewer.isClosing }, timeout: 2)
        viewer.open([second])
        check(restoredViewerClosed && spin({ viewer.window?.isVisible == true && !viewer.isClosing && viewer.loaded != nil
                     && viewer.currentURL == second && (viewer.window?.alphaValue ?? 0) > 0.99 }),
              "Opening after completed close restores a functional viewer")
        let expectedAfterReopening = viewer.items[(viewer.selectedIndex + 1) % viewer.items.count].url
        key("", code: 124)
        check(spin { viewer.loaded != nil && viewer.currentURL == expectedAfterReopening }, "Keyboard navigation works after reopening")

        let stressDirectory = output.appendingPathComponent("fixtures/thumbnail-stress", isDirectory: true)
        try FileManager.default.createDirectory(at: stressDirectory, withIntermediateDirectories: true)
        var stressURLs: [URL] = []
        for index in 0..<18 {
            let url = stressDirectory.appendingPathComponent(String(format: "photo-%02d.jpg", index))
            try? FileManager.default.removeItem(at: url)
            try FileManager.default.copyItem(at: first, to: url)
            stressURLs.append(url)
        }
        viewer.open([stressURLs[8]])
        check(spin { viewer.items.count == 18 && viewer.loaded != nil && viewer.currentURL == stressURLs[8] },
              "Open an eighteen-image folder for filmstrip scrolling regressions")
        var allRecenteredClicksPassed = true
        for slot in [10, 0, 9, 1, 10, 2, 8, 0, 10, 3, 7, 1] {
            let target = thumbnailSlot(slot)
            let expected = viewer.items[target.index].url
            moveMouse(viewer.strip, to: target.point)
            let delivered = click(viewer.strip, at: target.point, revealBeforeClick: false, settle: 0.015)
            let selected = spin { viewer.loaded != nil && viewer.currentURL == expected && viewerRemainsOpen() }
            if !delivered || !selected {
                allRecenteredClicksPassed = false
                diagnostics.append("DIAGNOSTIC recentered filmstrip: slot=\(slot), expectedIndex=\(target.index), selectedIndex=\(viewer.selectedIndex), visible=\(String(describing: viewer.window?.isVisible)), closing=\(viewer.isClosing)")
                break
            }
        }
        check(allRecenteredClicksPassed, "Repeated real clicks follow recentered thumbnails across eighteen images")

        _ = viewer.buttons["info"].map { click($0) }
        let selectedMetadata = click(viewer.infoText, at: NSPoint(x: 20, y: viewer.infoText.bounds.height - 70))
        let textWasFirstResponder = viewer.window?.firstResponder is NSTextView
        let afterTextTarget = thumbnailSlot(0)
        let afterTextURL = viewer.items[afterTextTarget.index].url
        let clickedAfterText = click(viewer.strip, at: afterTextTarget.point, revealBeforeClick: false)
        check(selectedMetadata && textWasFirstResponder && clickedAfterText
              && spin { viewer.loaded != nil && viewer.currentURL == afterTextURL && viewerRemainsOpen() },
              "Real thumbnail clicks remain safe after metadata text selection owns focus")
        _ = viewer.buttons["closeInfo"].map { click($0) }

        for state in ["hidden", "transparent", "mouse-move"] {
            let target = thumbnailSlot(viewer.selectedIndex == thumbnailSlot(0).index ? 1 : 0)
            let expected = viewer.items[target.index].url
            // Match the endpoint of the actual chrome fade without depending on
            // the human user's global cursor position or the auto-hide timer.
            viewer.dock.isHidden = state != "transparent"
            viewer.dock.alphaValue = 0
            CATransaction.flush()
            if state == "mouse-move" { moveMouse(viewer.strip, to: target.point) }
            let delivered = click(viewer.strip, at: target.point, revealBeforeClick: false, validateTarget: false)
            let survived = spin { viewer.loaded != nil && viewer.currentURL == expected && viewerRemainsOpen() }
            check(delivered && survived, "Real thumbnail click reveals \(state) chrome before routing mouse events")
            if !survived {
                diagnostics.append("DIAGNOSTIC \(state) chrome: expectedIndex=\(target.index), selectedIndex=\(viewer.selectedIndex), dockHidden=\(viewer.dock.isHidden), dockAlpha=\(viewer.dock.alphaValue), closing=\(viewer.isClosing)")
            }
            viewer.dock.isHidden = false; viewer.dock.alphaValue = 1
            if !viewerRemainsOpen() { viewer.show(); _ = spin { viewerRemainsOpen() && viewer.loaded != nil } }
        }
    } catch { check(false, "Unexpected error: \(error)") }
    report.append("\n\(report.count - failures) passed, \(failures) failed")
    let text = (report + diagnostics).joined(separator: "\n") + "\n"
    try? text.write(to: output.appendingPathComponent("ui-test-results.txt"), atomically: true, encoding: .utf8)
    print(text)
    fflush(stdout)
    exit(failures == 0 ? 0 : 1)
}
