// The runner instruments a temporary copy of DocumentTileLayer to expose
// draw-call metrics. The released application contains no test counters.
import AppKit
import QuartzCore

@main
struct LargeDocumentTests {
    static func spin(_ time: TimeInterval) {
        let until = Date().addingTimeInterval(time)
        while Date() < until { CATransaction.flush(); RunLoop.current.run(until: Date().addingTimeInterval(0.01)) }
    }
    static func tiles(_ layer: CALayer?) -> DocumentTileLayer? {
        guard let layer else { return nil }
        if let tile = layer as? DocumentTileLayer { return tile }
        for child in layer.sublayers ?? [] { if let result = tiles(child) { return result } }
        return nil
    }
    static func main() {
        guard CommandLine.arguments.count > 1 else {
            FileHandle.standardError.write(Data("Usage: LargeDocumentTests OUTPUT_DIRECTORY\n".utf8)); exit(2)
        }
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { _ in
            var lines: [String] = []
            do {
                let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
                try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
                let svg = root.appendingPathComponent("million.svg")
                try Data("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"1000000\" height=\"1000000\"><rect width=\"1000000\" height=\"1000000\" fill=\"white\"/><circle cx=\"500000\" cy=\"500000\" r=\"250000\" fill=\"red\"/></svg>".utf8).write(to: svg)
                let pdf = root.appendingPathComponent("million.pdf")
                let data = NSMutableData()
                var box = CGRect(x: 0, y: 0, width: 1_000_000, height: 1_000_000)
                let consumer = CGDataConsumer(data: data as CFMutableData)!
                let pdfContext = CGContext(consumer: consumer, mediaBox: &box, nil)!
                pdfContext.beginPDFPage(nil)
                pdfContext.setFillColor(CGColor(gray: 1, alpha: 1)); pdfContext.fill(box)
                pdfContext.setFillColor(NSColor.systemBlue.cgColor)
                pdfContext.fillEllipse(in: CGRect(x: 250_000, y: 250_000, width: 500_000, height: 500_000))
                pdfContext.endPDFPage(); pdfContext.closePDF(); try (data as Data).write(to: pdf)
                let window = NSWindow(contentRect: CGRect(x: 100, y: 100, width: 1000, height: 800), styleMask: [.titled], backing: .buffered, defer: false)
                window.isReleasedWhenClosed = false
                let canvas = PhotoCanvas(frame: CGRect(x: 0, y: 0, width: 1000, height: 800))
                canvas.animationsEnabled = false; window.contentView = canvas
                window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
                for url in [svg, pdf] {
                    let media = try DocumentMedia(url: url)
                    var loadedPage: Result<DocumentPage, Error>?
                    media.loadPage(at: 0, previewMaxPixelDimension: 2048) { loadedPage = $0 }
                    let loadDeadline = Date().addingTimeInterval(10)
                    while loadedPage == nil && Date() < loadDeadline { spin(0.01) }
                    guard let loadedPage else { throw NSError(domain: "LargeDocumentTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Page preview timed out"]) }
                    let page = try loadedPage.get()
                    DocumentTileLayer.metricsLock.lock()
                    DocumentTileLayer.drawCount = 0; DocumentTileLayer.drawScales = []; DocumentTileLayer.maxTileBytes = 0
                    DocumentTileLayer.metricsLock.unlock()
                    canvas.setDocumentPage(page, animated: false)
                    let initialFit = canvas.isFit, fitZoom = canvas.zoom
                    // Commit the complete first frame before a separate user zoom
                    // event, as the application does. CATiledLayer initializes its
                    // visible region on that first Core Animation transaction.
                    window.display(); spin(0.3)
                    let fitTilesHidden = tiles(canvas.layer)!.isHidden
                    DocumentTileLayer.metricsLock.lock()
                    let fitTileDraws = DocumentTileLayer.drawCount
                    DocumentTileLayer.metricsLock.unlock()
                    // The fit page is already sharp at this monitor's resolution;
                    // manual zoom must then enable native source-detail rendering.
                    canvas.zoomBy(1.01)
                    window.display(); spin(1.5)
                    let tile = tiles(canvas.layer)!
                    DocumentTileLayer.metricsLock.lock()
                    let count = DocumentTileLayer.drawCount, scales = DocumentTileLayer.drawScales, maxBytes = DocumentTileLayer.maxTileBytes
                    DocumentTileLayer.metricsLock.unlock()
                    let unique = Set(scales.map { String(format: "%.9f", $0) }).sorted()
                    // Count actual Core Animation draw callbacks after the visible
                    // window has committed. A million-point page must choose a
                    // reduced LOD instead of allocating source-resolution tiles.
                    let valid = page.size == CGSize(width: 1_000_000, height: 1_000_000)
                        && initialFit && fitZoom > 0 && fitZoom < 0.001 && page.presentationPreview != nil
                        && fitTilesHidden && fitTileDraws == 0 && !tile.isHidden && !canvas.isFit
                        && count > 0 && count <= 64 && maxBytes > 0 && maxBytes <= 4_194_304
                        && (scales.max() ?? 1) < 0.01
                    lines.append("\(valid ? "PASS" : "FAIL") \(url.pathExtension) size=\(page.size) fitZoom=\(fitZoom) fitTilesHidden=\(fitTilesHidden) fitTileDraws=\(fitTileDraws) preview=\(page.presentationPreview!.width)×\(page.presentationPreview!.height) LOD=\(tile.levelsOfDetail) bias=\(tile.levelsOfDetailBias) manualZoom=\(canvas.zoom) isFit=\(canvas.isFit) hidden=\(tile.isHidden) opacity=\(tile.opacity) bounds=\(tile.bounds) tileDraws=\(count) maxTileBytes=\(maxBytes) contextScales=\(unique)")
                    if let rep = canvas.bitmapImageRepForCachingDisplay(in: canvas.bounds) {
                        canvas.cacheDisplay(in: canvas.bounds, to: rep)
                        try rep.representation(using: .png, properties: [:])?.write(to: root.appendingPathComponent("\(url.pathExtension)-fit.png"))
                    }
                    canvas.clearImage(); spin(0.05)
                }
                window.close()
            } catch { lines.append("FAIL \(error)") }
            print(lines.joined(separator: "\n")); fflush(stdout)
            exit(lines.contains(where: { $0.hasPrefix("FAIL") }) ? 1 : 0)
        }
        app.run()
    }
}
