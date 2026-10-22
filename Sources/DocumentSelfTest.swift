import AppKit
import ImageIO
import QuartzCore
import UniformTypeIdentifiers

/// Opt-in integration coverage. Generated files and language overrides never
/// mutate the user's documents, defaults, or application associations.
func runDocumentSelfTests(_ viewer: ViewerController, output: URL) {
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
            RunLoop.main.run(until: Date().addingTimeInterval(0.02))
        } while Date() < end
        return condition()
    }
    func failure(_ message: String) -> NSError {
        NSError(domain: "LumaView.DocumentSelfTest", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }
    func makeImage(_ color: NSColor, width: Int = 900, height: Int = 600) throws -> CGImage {
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { throw failure("Cannot allocate fixture") }
        context.setFillColor(color.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.setFillColor(NSColor.white.cgColor)
        context.fillEllipse(in: CGRect(x: width / 4, y: height / 4, width: width / 2, height: height / 2))
        guard let image = context.makeImage() else { throw failure("Cannot create fixture image") }
        return image
    }
    func writeImages(_ images: [CGImage], to url: URL, type: UTType) throws {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, type.identifier as CFString, images.count, nil) else { throw failure("Cannot create fixture destination") }
        for image in images { CGImageDestinationAddImage(destination, image, nil) }
        guard CGImageDestinationFinalize(destination) else { throw failure("Cannot encode fixture") }
    }
    func writePDF(_ url: URL) throws {
        let data = NSMutableData()
        var box = CGRect(x: 0, y: 0, width: 600, height: 760)
        guard let consumer = CGDataConsumer(data: data as CFMutableData), let context = CGContext(consumer: consumer, mediaBox: &box, nil) else { throw failure("Cannot create PDF fixture") }
        let colors: [NSColor] = [.systemTeal, .systemOrange, .systemIndigo]
        for index in 0..<3 {
            context.beginPDFPage(nil)
            context.setFillColor(NSColor.white.cgColor); context.fill(box)
            context.setFillColor(colors[index].cgColor); context.fill(CGRect(x: 42, y: 490, width: 516, height: 210))
            context.setFillColor(colors[index].withAlphaComponent(0.15).cgColor)
            context.fill(CGRect(x: 42, y: 240, width: 516, height: 210))
            context.setFillColor(colors[index].cgColor)
            for row in 0..<6 { context.fill(CGRect(x: 42, y: 70 + row * 21, width: 280 + row * 30, height: 7)) }
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
            ("DOCUMENT / \(index + 1)" as NSString).draw(at: NSPoint(x: 62, y: 615), withAttributes: [.font: NSFont.systemFont(ofSize: 28, weight: .bold), .foregroundColor: NSColor.white])
            ("Native vector page" as NSString).draw(at: NSPoint(x: 62, y: 562), withAttributes: [.font: NSFont.systemFont(ofSize: 18), .foregroundColor: NSColor.white])
            NSGraphicsContext.restoreGraphicsState()
            context.endPDFPage()
        }
        context.closePDF()
        try (data as Data).write(to: url)
    }
    func ready(_ url: URL, page: Int? = nil) -> Bool {
        guard viewer.currentURL == url, viewer.documentMedia?.url == url, let current = viewer.documentPage,
              viewer.canvas.documentPage === current, viewer.canvas.hasMedia else { return false }
        return page == nil || (current.index == page && viewer.selectedPageIndex == page)
    }
    func remainsOpen() -> Bool { viewer.window?.isVisible == true && !viewer.isClosing }
    func key(_ code: UInt16, modifiers: NSEvent.ModifierFlags = []) {
        guard let window = viewer.window, let event = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: modifiers,
            timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber, context: nil,
            characters: "", charactersIgnoringModifiers: "", isARepeat: false, keyCode: code) else { return }
        viewer.canvas.keyDown(with: event)
    }
    var eventNumber = 1200
    @discardableResult
    func click(_ view: NSView, point: NSPoint? = nil) -> Bool {
        guard let window = viewer.window, remainsOpen() else { return false }
        viewer.revealChrome(); viewer.root.layoutSubtreeIfNeeded(); window.display(); CATransaction.flush()
        let location = view.convert(point ?? NSPoint(x: view.bounds.midX, y: view.bounds.midY), to: nil)
        let hit = viewer.root.hitTest(viewer.root.convert(location, from: nil))
        guard hit === view || hit?.isDescendant(of: view) == true else {
            diagnostics.append("Click target mismatch: \(type(of: view)); hit=\(String(describing: hit))")
            return false
        }
        eventNumber += 2
        let time = ProcessInfo.processInfo.systemUptime
        guard let down = NSEvent.mouseEvent(with: .leftMouseDown, location: location, modifierFlags: [], timestamp: time,
            windowNumber: window.windowNumber, context: nil, eventNumber: eventNumber, clickCount: 1, pressure: 1),
              let up = NSEvent.mouseEvent(with: .leftMouseUp, location: location, modifierFlags: [], timestamp: time + 0.02,
            windowNumber: window.windowNumber, context: nil, eventNumber: eventNumber + 1, clickCount: 1, pressure: 0) else { return false }
        NSApp.postEvent(up, atStart: true)
        window.sendEvent(down)
        while let event = NSApp.nextEvent(matching: .leftMouseUp, until: Date(), inMode: .default, dequeue: true) {
            if event.windowNumber == window.windowNumber { window.sendEvent(event) } else { NSApp.sendEvent(event) }
        }
        spin({ false }, timeout: 0.1)
        return true
    }
    func pagePoint(_ index: Int) -> NSPoint {
        let count = viewer.documentMedia?.pageCount ?? 0
        let capacity = max(1, Int((viewer.pageStrip.bounds.width - 8) / 40))
        let first = max(0, min(viewer.selectedPageIndex - capacity / 2, count - capacity))
        return NSPoint(x: (viewer.pageStrip.bounds.width - CGFloat(min(capacity, count)) * 40) / 2 + CGFloat(index - first) * 40 + 20, y: 28)
    }
    func filePoint(_ index: Int) -> NSPoint {
        let capacity = max(1, Int((viewer.strip.bounds.width - 24) / 72))
        let first = max(0, min(viewer.selectedIndex - capacity / 2, viewer.items.count - capacity))
        return NSPoint(x: (viewer.strip.bounds.width - CGFloat(min(capacity, viewer.items.count)) * 72) / 2 + CGFloat(index - first) * 72 + 35, y: 35)
    }
    func tileLayer(_ layer: CALayer?) -> DocumentTileLayer? {
        guard let layer else { return nil }
        if let tiles = layer as? DocumentTileLayer { return tiles }
        for child in layer.sublayers ?? [] { if let found = tileLayer(child) { return found } }
        return nil
    }
    func namedLayer(_ name: String, in layer: CALayer?) -> CALayer? {
        guard let layer else { return nil }
        if layer.name == name { return layer }
        for child in layer.sublayers ?? [] { if let found = namedLayer(name, in: child) { return found } }
        return nil
    }
    func selectedBorder(in strip: NSView, selected: Int, count: Int, pages: Bool) -> NSColor? {
        strip.displayIfNeeded()
        guard let bitmap = strip.bitmapImageRepForCachingDisplay(in: strip.bounds) else { return nil }
        strip.cacheDisplay(in: strip.bounds, to: bitmap)
        let pitch: CGFloat = pages ? 40 : 72
        let capacity = max(1, Int((strip.bounds.width - (pages ? 8 : 24)) / pitch))
        let first = max(0, min(selected - capacity / 2, count - capacity))
        let start = (strip.bounds.width - CGFloat(min(capacity, count)) * pitch) / 2
        let x = start + CGFloat(selected - first) * pitch + 2
        let y: CGFloat = pages ? 28 : 37
        let sx = CGFloat(bitmap.pixelsWide) / strip.bounds.width
        let sy = CGFloat(bitmap.pixelsHigh) / strip.bounds.height
        return bitmap.colorAt(x: Int(x * sx), y: Int((strip.bounds.height - y) * sy))?.usingColorSpace(.deviceRGB)
    }
    func isOrange(_ color: NSColor?) -> Bool {
        guard let color else { return false }
        return color.redComponent > color.blueComponent + 0.2 && color.greenComponent > color.blueComponent + 0.1
    }
    func isGray(_ color: NSColor?) -> Bool {
        guard let color else { return false }
        return color.redComponent > 0.3 && abs(color.redComponent - color.greenComponent) < 0.05
            && abs(color.redComponent - color.blueComponent) < 0.05
    }
    func popup(in view: NSView?) -> NSPopUpButton? {
        if let choice = view as? NSPopUpButton, choice.identifier?.rawValue == "languageChoice" { return choice }
        for child in view?.subviews ?? [] { if let found = popup(in: child) { return found } }
        return nil
    }
    func saveScreenshot(_ name: String) {
        viewer.revealChrome(); viewer.root.layoutSubtreeIfNeeded(); viewer.window?.display()
        if let bitmap = viewer.root.bitmapImageRepForCachingDisplay(in: viewer.root.bounds) {
            viewer.root.cacheDisplay(in: viewer.root.bounds, to: bitmap)
            if let png = bitmap.representation(using: .png, properties: [:]) { try? png.write(to: output.appendingPathComponent(name)) }
        }
    }
    let originalLanguagePreference = UserDefaults.standard.string(forKey: L10n.preferenceKey)
    L10n.useLanguageForTesting("zh-Hans")
    NotificationCenter.default.post(name: L10n.languageDidChange, object: nil)
    do {
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let fixtures = output.appendingPathComponent("document-fixtures", isDirectory: true)
        try FileManager.default.createDirectory(at: fixtures, withIntermediateDirectories: true)
        let still = fixtures.appendingPathComponent("01-photo.png"), pdf = fixtures.appendingPathComponent("02-book.pdf")
        let svg = fixtures.appendingPathComponent("03-vector.svg"), tiff = fixtures.appendingPathComponent("04-pages.tiff")
        let last = fixtures.appendingPathComponent("05-photo.png")
        try writeImages([makeImage(.systemTeal)], to: still, type: .png)
        try writeImages([makeImage(.systemOrange)], to: last, type: .png)
        try writePDF(pdf)
        try writeImages([makeImage(.systemGreen, width: 400, height: 600), makeImage(.systemPurple, width: 600, height: 400)], to: tiff, type: .tiff)
        try Data("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"600\" height=\"400\" viewBox=\"0 0 600 400\"><circle cx=\"300\" cy=\"200\" r=\"150\" fill=\"#3478a4\"/><path d=\"M80 200 L300 70 L520 200 L300 330 Z\" fill=\"none\" stroke=\"#ffd065\" stroke-width=\"2\"/></svg>".utf8).write(to: svg)
        viewer.canvas.animationsEnabled = true; viewer.showFilmstrip = true
        viewer.open([pdf])
        guard spin({ ready(pdf, page: 0) && remainsOpen() }) else { throw failure("PDF initial load did not finish") }
        check(viewer.documentMedia?.pageCount == 3 && viewer.items.count == 5, "Three-page PDF expands neighboring media files without flattening pages into files")
        check(viewer.showsDocumentNavigation && !viewer.pageStrip.isHidden && !viewer.pageSeekSlider.isHidden,
              "PDF displays internal-page thumbnails and page seek slider")
        check(viewer.pageCountLabel.stringValue == "1 / 3", "Initial current/total page counter is correct")
        check(viewer.pageStrip.frame.minY >= viewer.strip.frame.maxY && viewer.pageStrip.frame.height < viewer.strip.frame.height,
              "Page strip sits above file strip and uses smaller thumbnails")
        check(viewer.videoSeekSlider.isHidden && viewer.buttons["mediaPlay"]?.isHidden == true,
              "PDF row replaces media transport without showing audio/video controls")
        check(viewer.navigationFocus == .files && !viewer.pageStrip.keyboardFocused && viewer.strip.keyboardFocused,
              "Document initially highlights selected file and leaves page selection inactive")
        check(viewer.openButton.isHidden && viewer.canvas.placeholderText == nil && namedLayer("photo-placeholder", in: viewer.canvas.layer) == nil,
              "Document hides welcome text, open button, and empty-state layer")
        check(tileLayer(viewer.canvas.layer)?.documentPage === viewer.documentPage && viewer.canvas.image == nil,
              "PDF canvas retains vector instructions in tiled layer")

        check(viewer.dock.subviews.compactMap { $0 as? NSButton }.allSatisfy { !$0.title.contains("↑") && !$0.title.contains("↓") },
              "Document dock has no page/file focus text buttons")
        key(126)
        check(isGray(selectedBorder(in: viewer.strip, selected: viewer.selectedIndex, count: viewer.items.count, pages: false)),
              "Rendered current-file border is gray when page navigation has focus")
        check(isOrange(selectedBorder(in: viewer.pageStrip, selected: viewer.selectedPageIndex, count: 3, pages: true)),
              "Rendered current-page border is orange when page navigation has focus")
        check(viewer.navigationFocus == .pages && viewer.pageStrip.keyboardFocused && !viewer.strip.keyboardFocused,
              "Up arrow focuses pages and transfers active thumbnail border from files to pages")
        key(124)
        check(spin { ready(pdf, page: 1) }, "Right arrow in page focus switches internal page while retaining file")
        let wholePage = namedLayer("document-page-preview", in: viewer.canvas.layer)
        check(wholePage?.contents != nil && wholePage?.isHidden == false,
              "New page arrives with a complete visible image before asynchronous vector tiles")
        check(tileLayer(viewer.canvas.layer)?.isHidden == true,
              "Fit-to-window page uses its complete screen-resolution image without tile-by-tile reveal")
        if !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            check(namedLayer("photo-current", in: viewer.canvas.layer)?.animation(forKey: "imageFade") != nil,
                  "Page arrival uses one whole-page opacity transition")
        }
        check(viewer.pageCountLabel.stringValue == "2 / 3" && viewer.pageSeekSlider.doubleValue == 2, "Page counter and slider track keyboard page switch")
        key(123)
        check(spin { ready(pdf, page: 0) }, "Left arrow in page focus switches previous internal page")
        key(123)
        spin({ false }, timeout: 0.12)
        check(ready(pdf, page: 0), "First-page boundary never crosses to previous file")
        viewer.selectPage(2)
        guard spin({ ready(pdf, page: 2) }) else { throw failure("Cannot select last PDF page") }
        key(124)
        spin({ false }, timeout: 0.12)
        check(ready(pdf, page: 2), "Last-page boundary never crosses to next file")

        let thumbnailClicked = click(viewer.pageStrip, point: pagePoint(0))
        check(thumbnailClicked && spin { ready(pdf, page: 0) && remainsOpen() }, "Real mouse click selects page thumbnail without closing viewer")
        check(viewer.navigationFocus == .pages, "Page thumbnail click sets page-navigation focus")
        let sliderClicked = click(viewer.pageSeekSlider, point: NSPoint(x: viewer.pageSeekSlider.bounds.width - 9, y: viewer.pageSeekSlider.bounds.midY))
        check(sliderClicked && spin { ready(pdf, page: 2) }, "Real page-slider click seeks to final internal page")
        check(viewer.window?.firstResponder === viewer.canvas, "Page-slider completion restores keyboard navigation to canvas")
        check(abs(viewer.pageSeekSlider.doubleValue - Double(viewer.selectedPageIndex + 1)) < 0.001,
              "Page-slider release snaps thumb to the selected integer page")
        let selectedFileClicked = click(viewer.strip, point: filePoint(viewer.selectedIndex))
        check(selectedFileClicked && spin { ready(pdf, page: 2) && viewer.navigationFocus == .files },
              "Clicking selected file thumbnail activates file navigation without needing text labels")
        check(viewer.strip.keyboardFocused && !viewer.pageStrip.keyboardFocused,
              "File thumbnail click highlights file border while page border becomes inactive")
        let selectedPageClicked = click(viewer.pageStrip, point: pagePoint(2))
        check(selectedPageClicked && spin { ready(pdf, page: 2) && viewer.navigationFocus == .pages },
              "Clicking selected page thumbnail activates internal-page navigation without text labels")
        check(viewer.pageStrip.keyboardFocused && !viewer.strip.keyboardFocused,
              "Page thumbnail click highlights page border while file border becomes inactive")
        key(125)
        check(viewer.navigationFocus == .files && !viewer.pageStrip.keyboardFocused && viewer.strip.keyboardFocused,
              "Down arrow returns active thumbnail border to files")
        check(isOrange(selectedBorder(in: viewer.strip, selected: viewer.selectedIndex, count: viewer.items.count, pages: false)),
              "Rendered current-file border returns to orange after Down arrow")
        check(isGray(selectedBorder(in: viewer.pageStrip, selected: viewer.selectedPageIndex, count: 3, pages: true)),
              "Rendered current-page border becomes gray after Down arrow")
        key(124)
        check(spin { ready(svg) && remainsOpen() }, "Right arrow in file focus advances to adjacent SVG file")
        check(!viewer.showsDocumentNavigation && viewer.pageStrip.isHidden && viewer.videoSeekSlider.isHidden,
              "Single-page SVG hides unnecessary internal-page controls")
        viewer.canvas.zoomBy(1000)
        spin({ !viewer.canvas.isAnimating }, timeout: 1)
        check(viewer.canvas.zoom == 32 && tileLayer(viewer.canvas.layer)?.documentPage?.document.url == svg,
              "SVG retains live vector tiles at 3200% zoom")
        let vectorTiles = tileLayer(viewer.canvas.layer)
        let vectorContent = vectorTiles?.superlayer
        let vectorWhite = vectorContent?.backgroundColor.flatMap { NSColor(cgColor: $0)?.usingColorSpace(.deviceRGB) }
        let whitePaper = (vectorWhite?.redComponent ?? 0) > 0.99 && (vectorWhite?.greenComponent ?? 0) > 0.99
            && (vectorWhite?.blueComponent ?? 0) > 0.99 && (vectorWhite?.alphaComponent ?? 0) > 0.99
        // The complete preview prevents blank regions while native vector tiles
        // supply detail at this high zoom. It never replaces the vector source.
        check(whitePaper && vectorTiles?.documentPage?.isVector == true && vectorTiles?.isHidden == false
              && vectorContent?.sublayers?.count == 2 && vectorContent?.sublayers?.last === vectorTiles
              && vectorContent?.sublayers?.first?.name == "document-page-preview",
              "High zoom keeps native vector drawing above complete page fallback on solid white paper")
        viewer.rotateRight()
        check(viewer.canvas.quarterTurns == 1 && viewer.canvas.documentPage?.document.url == svg, "Rotation keeps SVG vector drawing active")
        viewer.fit()
        key(123)
        check(spin { ready(pdf, page: 2) }, "Returning to PDF remembers its selected internal page")
        guard let pdfIndex = viewer.items.firstIndex(where: { $0.url == pdf }),
              let svgIndex = viewer.items.firstIndex(where: { $0.url == svg }),
              let tiffIndex = viewer.items.firstIndex(where: { $0.url == tiff }),
              let stillIndex = viewer.items.firstIndex(where: { $0.url == still }) else { throw failure("Missing generated sibling media") }

        let clickFile = click(viewer.strip, point: filePoint(tiffIndex))
        check(clickFile && spin { ready(tiff, page: 0) && remainsOpen() }, "Real lower-file-strip click opens multipage TIFF without closing viewer")
        check(viewer.documentMedia?.pageCount == 2 && viewer.navigationFocus == .files && viewer.showsDocumentNavigation,
              "TIFF exposes two internal pages with file focus initially")
        key(126); key(124)
        check(spin { ready(tiff, page: 1) }, "TIFF page navigation selects second stored image")
        check(viewer.documentPage?.size == CGSize(width: 600, height: 400) && viewer.canvas.image != nil,
              "TIFF second page preserves its own raster dimensions")

        viewer.select(pdfIndex)
        guard spin({ ready(pdf) }) else { throw failure("Cannot reload PDF before race checks") }
        for index in [0, 2, 1, 0, 2] { viewer.selectPage(index) }
        check(spin { ready(pdf, page: 2) }, "Rapid page selection only displays newest page callback")
        viewer.selectPage(0); viewer.selectPage(1); viewer.select(svgIndex)
        check(spin { ready(svg) }, "Page callbacks cannot replace a subsequently selected SVG")
        spin({ false }, timeout: 0.3)
        check(ready(svg), "Late old-document callbacks remain discarded after completion")
        viewer.select(pdfIndex)
        guard spin({ ready(pdf) }) else { throw failure("Cannot reload PDF before image race check") }
        viewer.selectPage(0); viewer.selectPage(2); viewer.select(stillIndex)
        check(spin { viewer.currentURL == still && viewer.loaded != nil && viewer.documentMedia == nil && viewer.canvas.documentPage == nil },
              "Pending PDF page cannot overwrite a newly selected ordinary image")
        check(viewer.pageStrip.isHidden && viewer.videoSeekSlider.isHidden, "Ordinary image removes page and media navigation rows")
        viewer.select(pdfIndex)
        guard spin({ ready(pdf) }) else { throw failure("Cannot restore PDF for reopen check") }
        viewer.selectPage(1)
        guard spin({ ready(pdf, page: 1) }) else { throw failure("Cannot select page before closing") }
        viewer.closeViewer()
        check(spin({ viewer.window?.isVisible == false }, timeout: 2), "PDF close completes animation")
        check(!viewer.canvas.hasMedia && viewer.canvas.documentPage == nil, "Closed canvas releases active document rendering layer")
        viewer.show()
        check(spin { ready(pdf, page: 1) && remainsOpen() }, "Reopening restores selected PDF page as vector source")
        check(tileLayer(viewer.canvas.layer)?.documentPage === viewer.documentPage, "Window reopen restores vector layer rather than preview bitmap")
        viewer.selectPage(2)
        viewer.closeViewer()
        check(spin({ viewer.window?.isVisible == false }, timeout: 2), "Close during pending page load cancels asynchronous presentation")
        viewer.show()
        check(spin { ready(pdf) && viewer.selectedPageIndex == viewer.documentPage?.index && remainsOpen() },
              "Reopen during pending page transition keeps visible page and selected index synchronized")
        check(viewer.pageCountLabel.stringValue == "\(viewer.selectedPageIndex + 1) / 3" && viewer.pageSeekSlider.doubleValue == Double(viewer.selectedPageIndex + 1),
              "Reopened page counter, slider and rendered page agree")
        viewer.selectPage(1)
        guard spin({ ready(pdf, page: 1) }) else { throw failure("Cannot restore page for language checks") }
        viewer.focusPages(); viewer.revealChrome()
        spin({ !viewer.canvas.isAnimating }, timeout: 1)
        saveScreenshot("document-navigation-zh.png")

        L10n.useLanguageForTesting("en")
        NotificationCenter.default.post(name: L10n.languageDidChange, object: nil)
        check(spin { viewer.pageStrip.toolTip == L10n.tr("内页焦点：← → 切换页面")
            && L10n.tr("内页焦点：← → 切换页面") != "内页焦点：← → 切换页面" },
              "Changing language immediately refreshes page-thumbnail navigation tooltip")
        check(NSApp.mainMenu?.items.contains(where: { $0.title == L10n.tr("文件") }) == true && L10n.tr("文件") != "文件",
              "English language refresh updates application menu")
        check(viewer.pageStrip.toolTip == L10n.tr("内页焦点：← → 切换页面") && viewer.pageStrip.toolTip?.contains("←") == true,
              "Page-navigation tooltip retains directional keyboard guidance in selected language")
        check(viewer.buttons["zoomIn"]?.toolTip == L10n.tr("放大 + / Page Up"), "Existing zoom control tooltip refreshes with language")
        check(ready(pdf, page: 1) && viewer.navigationFocus == .pages, "Language refresh preserves current file, page, and keyboard focus")
        saveScreenshot("document-navigation-en.png")

        let languageSelector = NSSelectorFromString("showLanguagePreferences")
        if viewer.responds(to: languageSelector) {
            viewer.perform(languageSelector)
            let found = spin { NSApp.windows.contains { $0.isVisible && $0.title == L10n.tr("语言设置") } }
            let panel = NSApp.windows.first { $0.isVisible && $0.title == L10n.tr("语言设置") }
            check(found && panel != nil, "Language preferences opens a dedicated popup window")
            check(popup(in: panel?.contentView)?.numberOfItems == L10n.languages.count + 1,
                  "Language popup includes all supported languages plus Follow System")
            L10n.useLanguageForTesting("ja")
            NotificationCenter.default.post(name: L10n.languageDidChange, object: nil)
            check(spin { NSApp.mainMenu?.items.contains(where: { $0.title == L10n.tr("文件") }) == true && L10n.tr("文件") != "File" && L10n.tr("文件") != "文件" },
                  "Japanese language refresh updates application menu immediately")
            check(panel?.title == L10n.tr("语言设置") && (popup(in: panel?.contentView)?.selectedItem?.representedObject as? String) == "ja",
                  "Open language preferences refreshes its title and selected language")
            panel?.performClose(nil)
            check(spin { panel?.isVisible == false }, "Language preferences closes without closing media viewer")
        } else { check(false, "Language preferences menu action is available") }
        check(ready(pdf, page: 1) && remainsOpen(), "Closing preferences preserves active document viewer")
        check(UserDefaults.standard.string(forKey: L10n.preferenceKey) == originalLanguagePreference,
              "Language tests leave user's saved preference unchanged")

        // Keep new PostScript fixtures outside the original five-file folder so
        // the existing navigation checks continue to exercise the same ordering.
        let postScriptFixtures = output.appendingPathComponent("postscript-ui-fixtures", isDirectory: true)
        try FileManager.default.createDirectory(at: postScriptFixtures, withIntermediateDirectories: true)
        let eps = postScriptFixtures.appendingPathComponent("01-vector.eps")
        let ps = postScriptFixtures.appendingPathComponent("02-pages.ps")
        let afterPS = postScriptFixtures.appendingPathComponent("03-photo.png")
        try Data("""
        %!PS-Adobe-3.0 EPSF-3.0
        %%BoundingBox: 0 0 600 400
        1 1 1 setrgbcolor 0 0 600 400 rectfill
        0.1 0.5 0.7 setrgbcolor 300 200 150 0 360 arc fill
        1 0.65 0.1 setrgbcolor 80 200 moveto 300 330 lineto 520 200 lineto 300 70 lineto closepath 3 setlinewidth stroke
        /Helvetica findfont 24 scalefont setfont 40 30 moveto (Live EPS vectors) show
        showpage
        %%EOF
        """.utf8).write(to: eps)
        try Data("""
        %!PS-Adobe-3.0
        << /PageSize [240 160] >> setpagedevice
        0.1 0.5 0.7 setrgbcolor 0 0 240 160 rectfill showpage
        0.9 0.4 0.1 setrgbcolor 0 0 240 160 rectfill showpage
        """.utf8).write(to: ps)
        try writeImages([makeImage(.systemPink, width: 480, height: 320)], to: afterPS, type: .png)
        viewer.open([eps])
        guard spin({ ready(eps, page: 0) && remainsOpen() }, timeout: 20) else { throw failure("EPS native viewer load did not finish") }
        // During a crossfade the outgoing PDF layer is still in the hierarchy.
        // Inspect the settled current layer rather than that retained old page.
        check(spin { viewer.documentMedia?.isVector == true && viewer.documentMedia?.format == "EPS"
              && viewer.documentPage?.rasterImage == nil && tileLayer(viewer.canvas.layer)?.documentPage === viewer.documentPage },
              "EPS opens as live vector instructions instead of an embedded preview bitmap")
        viewer.canvas.zoomBy(1000)
        spin({ !viewer.canvas.isAnimating }, timeout: 1)
        check(viewer.canvas.zoom == 32 && tileLayer(viewer.canvas.layer)?.isHidden == false
              && tileLayer(viewer.canvas.layer)?.documentPage?.document.url == eps,
              "EPS keeps native vector drawing at 3200 percent zoom")
        viewer.fit()
        viewer.open([ps])
        guard spin({ ready(ps, page: 0) }, timeout: 20) else { throw failure("PostScript native viewer load did not finish") }
        check(viewer.documentMedia?.pageCount == 2 && viewer.documentMedia?.isVector == true
              && viewer.showsDocumentNavigation && viewer.pageCountLabel.stringValue == "1 / 2",
              "Multipage PostScript uses the existing page thumbnails and current-total indicator")
        key(126); key(124)
        check(spin { ready(ps, page: 1) && viewer.navigationFocus == .pages
            && viewer.pageStrip.keyboardFocused && !viewer.strip.keyboardFocused },
              "Up then Right navigates the next PostScript page with page focus")
        key(123)
        check(spin { ready(ps, page: 0) && viewer.pageCountLabel.stringValue == "1 / 2" },
              "Left returns to the previous PostScript page and updates its counter")
        key(125); key(124)
        check(spin { viewer.currentURL == afterPS && viewer.loaded != nil && viewer.documentMedia == nil
            && viewer.navigationFocus == .files && viewer.strip.keyboardFocused },
              "Down then Right returns to file navigation and opens the adjacent PNG")

        // Create the hanging source only after navigation checks. Switching out
        // of this separate folder cancels both its main and thumbnail consumers.
        let cancelFixtures = postScriptFixtures.appendingPathComponent("cancellation", isDirectory: true)
        try FileManager.default.createDirectory(at: cancelFixtures, withIntermediateDirectories: true)
        let hangingPS = cancelFixtures.appendingPathComponent("pending.ps")
        try Data("%!PS\n{} loop\n".utf8).write(to: hangingPS)
        viewer.open([hangingPS])
        check(spin { viewer.currentURL == hangingPS && viewer.documentMedia == nil && remainsOpen() },
              "Unfinished PostScript conversion leaves the native viewer responsive")
        spin({ false }, timeout: 0.25)
        viewer.open([afterPS])
        check(spin { viewer.currentURL == afterPS && viewer.loaded != nil && viewer.documentMedia == nil
            && viewer.canvas.documentPage == nil && remainsOpen() },
              "Selecting PNG while PostScript is converting cancels the old document request")
        spin({ false }, timeout: 0.5)
        check(viewer.currentURL == afterPS && viewer.loaded != nil && viewer.documentMedia == nil
              && viewer.canvas.documentPage == nil && remainsOpen(),
              "Cancelled PostScript completion cannot overwrite the newly selected PNG")
        L10n.useLanguageForTesting(nil)
        NotificationCenter.default.post(name: L10n.languageDidChange, object: nil)
        viewer.closeViewer(); spin({ viewer.window?.isVisible == false }, timeout: 2)
    } catch { check(false, "Unexpected error: \(error)") }
    L10n.useLanguageForTesting(nil)
    NotificationCenter.default.post(name: L10n.languageDidChange, object: nil)
    report.append("\n\(report.count - failures) passed, \(failures) failed")
    let text = (report + diagnostics).joined(separator: "\n") + "\n"
    try? text.write(to: output.appendingPathComponent("document-test-results.txt"), atomically: true, encoding: .utf8)
    print(text); fflush(stdout)
    exit(failures == 0 ? 0 : 1)
}
