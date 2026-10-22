import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers
import QuartzCore

private struct DocumentTestFailure: Error, CustomStringConvertible { let description: String }

@main
struct DocumentMediaTests {
    private static var checks = 0
    static func main() throws {
        _ = NSApplication.shared
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("LumaViewDocuments-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let pdfURL = root.appendingPathComponent("cropped-rotated.pdf")
        try makePDF(pages: [
            ("[0 0 200 200]", "[20 30 120 80]", 90, "1 0 0 rg 20 30 100 50 re f 0 1 0 rg 20 30 50 50 re f"),
            ("[0 0 100 100]", "[0 0 100 100]", 0, "0 0 1 rg 0 0 100 100 re f"),
            ("[0 0 100 100]", "[0 0 100 100]", 0, "1 0 0 rg 49.95 0 0.1 100 re f")
        ]).write(to: pdfURL)
        let document = try DocumentMedia(url: pdfURL)
        try check(document.pageCount == 3 && document.isVector && document.format == "PDF", "PDF reports every page and vector source")
        let first = try document.page(at: 0)
        try check(first.size == CGSize(width: 50, height: 100), "crop box and page rotation determine oriented page size")
        let crop = try first.preview(maxPixelDimension: 200)
        try check(crop.width == 100 && crop.height == 200, "rotated page preview has correct aspect ratio")
        let c1 = try pixel(crop, x: 50, y: 30), c2 = try pixel(crop, x: 50, y: 170)
        try check((c1.r > 220 && c2.g > 220) || (c2.r > 220 && c1.g > 220), "cropped rotated page retains both halves without blank margins")
        let second = try document.page(at: 1).preview(maxPixelDimension: 100)
        try check(try pixel(second, x: 50, y: 50).b > 240, "arbitrary PDF page renders independently of first page")
        do { _ = try document.page(at: 3); throw DocumentTestFailure(description: "out-of-range PDF page accepted") }
        catch VectorRenderError.invalidDocument { checks += 1 }
        do { _ = try document.page(at: -1); throw DocumentTestFailure(description: "negative PDF page accepted") }
        catch VectorRenderError.invalidDocument { checks += 1 }
        try testVectorDetail(page: document.page(at: 2), name: "PDF")

        let ai = root.appendingPathComponent("illustrator.ai")
        try Data(contentsOf: pdfURL).write(to: ai)
        let aiDocument = try DocumentMedia(url: ai)
        try check(aiDocument.pageCount == 3 && aiDocument.isVector, "PDF-compatible Illustrator preserves all artboard pages")

        let svg = root.appendingPathComponent("fine.svg")
        try Data("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"100\" height=\"100\" viewBox=\"0 0 100 100\"><rect x=\"49.95\" y=\"0\" width=\"0.1\" height=\"100\" fill=\"red\"/></svg>".utf8).write(to: svg)
        let svgDocument = try DocumentMedia(url: svg)
        let svgPage = try svgDocument.page(at: 0)
        try check(svgDocument.pageCount == 1 && svgPage.size == CGSize(width: 100, height: 100) && svgPage.isVector, "SVG keeps native dimensions and vector source")
        // Drawing a low-resolution preview first must not freeze AppKit's SVG cache.
        _ = try svgPage.preview(maxPixelDimension: 32)
        try testVectorDetail(page: svgPage, name: "SVG")
        let svgPreview = try svgPage.preview(maxPixelDimension: 100)
        let white = try pixel(svgPreview, x: 5, y: 5)
        try check(white.r > 250 && white.g > 250 && white.b > 250 && white.a == 255, "transparent SVG canvas uses solid white paper, not checkerboard")
        let unsafe = root.appendingPathComponent("unsafe.svg")
        try Data("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"10\" height=\"10\"><image href=\"https://example.com/picture.png\"/></svg>".utf8).write(to: unsafe)
        do { _ = try DocumentMedia(url: unsafe); throw DocumentTestFailure(description: "external SVG resource accepted") }
        catch VectorRenderError.unsafeSVG { checks += 1 }

        let tiff = root.appendingPathComponent("multipage.tiff")
        guard let destination = CGImageDestinationCreateWithURL(tiff as CFURL, UTType.tiff.identifier as CFString, 2, nil) else { throw DocumentTestFailure(description: "TIFF destination unavailable") }
        CGImageDestinationAddImage(destination, try solidImage(width: 40, height: 20, color: CGColor(red: 1, green: 0, blue: 0, alpha: 1)), nil)
        CGImageDestinationAddImage(destination, try solidImage(width: 40, height: 20, color: CGColor(red: 0, green: 0, blue: 1, alpha: 1)), [kCGImagePropertyOrientation: 6] as CFDictionary)
        try check(CGImageDestinationFinalize(destination), "TIFF fixture written")
        let tiffDocument = try DocumentMedia(url: tiff)
        try check(tiffDocument.pageCount == 2 && !tiffDocument.isVector, "TIFF pages are raster pages, not a vector claim")
        let tiffPage = try tiffDocument.page(at: 1)
        try check(tiffPage.size == CGSize(width: 20, height: 40), "TIFF page orientation and original pixel dimensions preserved")
        let tiffPreview = try tiffPage.preview(maxPixelDimension: 100)
        try check(try pixel(tiffPreview, x: 25, y: 50).b > 240, "second TIFF page selected and decoded")

        var asyncDocument: Result<DocumentMedia, Error>?
        DocumentMedia.load(url: pdfURL) { asyncDocument = $0; try? check(Thread.isMainThread, "document callback arrives on main") }
        try wait { asyncDocument != nil }
        try check(try asyncDocument!.get().pageCount == 3, "asynchronous document open returns full page count")
        var asyncPage: Result<DocumentPage, Error>?
        document.loadPage(at: 1) { asyncPage = $0 }
        try wait { asyncPage != nil }
        try check(try asyncPage!.get().index == 1, "async page load returns requested zero-based index")
        var thumbnail: CGImage?
        document.thumbnail(at: 1, maxPixelDimension: 80) { thumbnail = $0 }
        try wait { thumbnail != nil }
        try check(thumbnail!.width == 80 && thumbnail!.height == 80, "page thumbnail is bounded to requested size")
        var invalidThumbnailDone = false
        document.thumbnail(at: 1000) { image in invalidThumbnailDone = image == nil }
        try wait { invalidThumbnailDone }
        try check(invalidThumbnailDone, "invalid thumbnail index fails safely")

        let canvas = PhotoCanvas(frame: NSRect(x: 0, y: 0, width: 1000, height: 800))
        canvas.animationsEnabled = false
        canvas.setDocumentPage(svgPage)
        try check(canvas.hasMedia && canvas.image == nil && canvas.documentPage === svgPage, "canvas retains vector source instead of bitmap preview")
        let layer = try requireTiles(canvas.layer)
        try check(layer.tileSize == CGSize(width: 512, height: 512) && layer.levelsOfDetailBias >= 5, "vector canvas tiles bound allocation and cover 3200% magnification")
        try check(layer.documentPage === svgPage && layer.contents == nil, "CATiledLayer retains live page without assigning raster contents")
        canvas.zoomBy(1000)
        try check(canvas.zoom == 32 && canvas.documentPage === svgPage, "high zoom continues using native vector source")
        canvas.rotate(1)
        try check(canvas.quarterTurns == 1 && canvas.documentPage === svgPage, "rotation preserves vector source")
        canvas.setDocumentPage(first)
        try check(canvas.isFit && canvas.quarterTurns == 0 && canvas.documentPage === first, "page switch resets fit and orientation without losing document ownership")
        canvas.setDocumentPage(tiffPage)
        try check(canvas.image != nil && canvas.pixelSize == tiffPage.size && canvas.documentPage === tiffPage, "TIFF canvas retains original pixel geometry")
        canvas.clearImage()
        try check(!canvas.hasMedia && canvas.documentPage == nil, "clearing canvas releases document page and placeholder returns normally")
        let oldPreview = try VectorRenderer.render(url: svg, maxPixelDimension: 200)
        try check(oldPreview.image.width == 200 && oldPreview.originalSize.width == 100, "existing raster preview API remains compatible for file thumbnails")
        var preparedPage: Result<DocumentPage, Error>?
        document.loadPage(at: 0, previewMaxPixelDimension: 2048) { preparedPage = $0 }
        try wait { preparedPage != nil }
        let completePage = try preparedPage!.get()
        try check(completePage.presentationPreview?.height == 2048 && completePage.presentationPreview?.width == 1024,
                  "async page load prepares a full viewport-sized page before publication")
        canvas.setFrameSize(CGSize(width: 1000, height: 800))
        canvas.setDocumentPage(completePage)
        let completeTiles = try requireTiles(canvas.layer)
        let baseLayer = completeTiles.superlayer?.sublayers?.first
        try check(baseLayer?.name == "document-page-preview" && isBitmap(baseLayer?.contents),
                  "complete page surface is installed synchronously under native vector tiles")
        try check(completeTiles.isHidden && canvas.isFit, "fit page is displayed atomically without piecemeal tile reveal")
        try check(completeTiles.backgroundColor == nil && !completeTiles.isOpaque,
                  "unrendered vector tiles are transparent and cannot cover the complete page")
        canvas.zoomBy(2)
        try check(!completeTiles.isHidden && completeTiles.documentPage === completePage && isBitmap(baseLayer?.contents),
                  "manual zoom restores native vector detail while retaining complete page beneath")
        canvas.fit()
        try check(completeTiles.isHidden, "returning to fit immediately restores the complete-page display")
        canvas.setFrameSize(CGSize(width: 6000, height: 5000))
        try check(!completeTiles.isHidden, "display enlargement beyond prepared pixels automatically enables vector tiles")
        canvas.setFrameSize(CGSize(width: 1000, height: 800))
        try check(completeTiles.isHidden, "smaller fit view uses existing complete surface without another render")

        var obsoleteCallbacks = 0, newestPage: Result<DocumentPage, Error>?
        document.loadPage(at: 1, previewMaxPixelDimension: 512) { _ in obsoleteCallbacks += 1 }
        document.loadPage(at: 2, previewMaxPixelDimension: 512) { newestPage = $0 }
        try wait { newestPage != nil }
        try check(obsoleteCallbacks == 0 && (try newestPage!.get()).index == 2,
                  "a newer page request cancels old pending presentation callbacks")
        var cancelledCallback = false, cancellationBarrier = false
        document.loadPage(at: 0, previewMaxPixelDimension: 512) { _ in cancelledCallback = true }
        document.cancelPendingPageLoads()
        document.thumbnail(at: 0, maxPixelDimension: 32) { _ in cancellationBarrier = true }
        try wait { cancellationBarrier }
        try check(!cancelledCallback, "file switch cancellation prevents a completed old page from publishing")
        try check(try document.page(at: 1).presentationPreview != nil && svgPage.presentationPreview != nil,
                  "synchronous vector page access also provides complete bounded first frame")
        try check(tiffPage.presentationPreview === tiffPage.rasterImage,
                  "raster document page reuses its decoded image without allocating another preview")
        canvas.animationsEnabled = true
        for page in [svgPage, first, completePage, svgPage, completePage] { canvas.setDocumentPage(page) }
        let currentLayer = canvas.layer?.sublayers?.first(where: { $0.name == "photo-host" })?.sublayers?.first(where: { $0.name == "photo-current" })
        let latestTiles = try requireTiles(currentLayer)
        try check(canvas.documentPage === completePage && isBitmap(latestTiles.superlayer?.sublayers?.first?.contents),
                  "rapid page replacement always installs the newest complete-page surface")
        canvas.animationsEnabled = false
        try check(!canvas.isAnimating && canvas.documentPage === completePage,
                  "reduced-motion path exposes complete page immediately with no readiness delay")
        canvas.clearImage()
        print("PASS: \(checks) document/vector checks")
    }

    private static func testVectorDetail(page: DocumentPage, name: String) throws {
        guard let context = context(width: 256, height: 256) else { throw DocumentTestFailure(description: "tile allocation failed") }
        context.scaleBy(x: 1000, y: 1000)
        context.translateBy(x: -49.872, y: -49.872)
        page.draw(in: context, rect: CGRect(origin: .zero, size: page.size))
        guard let image = context.makeImage() else { throw DocumentTestFailure(description: "tile image failed") }
        let mid = try pixel(image, x: 128, y: 128), left = try pixel(image, x: 60, y: 128), right = try pixel(image, x: 195, y: 128)
        try check(mid.r > 245 && mid.g < 10 && mid.b < 10, "\(name) sub-point vector stroke stays solid at 1000× context scale")
        try check(left.r > 245 && left.g > 245 && right.r > 245 && right.g > 245, "\(name) high-zoom vector edges remain exact without enlarged bitmap blocks")
        let edge0 = try pixel(image, x: 76, y: 128), edge1 = try pixel(image, x: 80, y: 128)
        try check(edge0.g > 240 && edge1.g < 15, "\(name) high-zoom edge transition is under four device pixels")
    }

    private static func context(width: Int, height: Int) -> CGContext? {
        CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                  space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    }
    private static func solidImage(width: Int, height: Int, color: CGColor) throws -> CGImage {
        guard let context = context(width: width, height: height) else { throw DocumentTestFailure(description: "fixture context failed") }
        context.setFillColor(color); context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()!
    }
    private static func pixel(_ image: CGImage, x: Int, y: Int) throws -> (r: Int, g: Int, b: Int, a: Int) {
        guard let context = context(width: image.width, height: image.height), let data = context.data else { throw DocumentTestFailure(description: "pixel context failed") }
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        let offset = y * context.bytesPerRow + x * 4
        let p = data.assumingMemoryBound(to: UInt8.self)
        return (Int(p[offset]), Int(p[offset + 1]), Int(p[offset + 2]), Int(p[offset + 3]))
    }
    private static func isBitmap(_ contents: Any?) -> Bool {
        guard let contents else { return false }
        return CFGetTypeID(contents as CFTypeRef) == CGImage.typeID
    }
    private static func requireTiles(_ layer: CALayer?) throws -> DocumentTileLayer {
        if let tiles = layer as? DocumentTileLayer { return tiles }
        for child in layer?.sublayers ?? [] { if let found = try? requireTiles(child) { return found } }
        throw DocumentTestFailure(description: "canvas has no document tiles")
    }
    private static func wait(_ ready: () -> Bool) throws {
        let deadline = Date().addingTimeInterval(10)
        while !ready(), Date() < deadline { RunLoop.current.run(until: Date().addingTimeInterval(0.01)) }
        try check(ready(), "async document operation completed before timeout")
    }
    private static func check(_ condition: @autoclosure () throws -> Bool, _ message: String) throws {
        guard try condition() else { throw DocumentTestFailure(description: message) }; checks += 1
    }
    private static func makePDF(pages: [(String, String, Int, String)]) -> Data {
        var objects = ["<< /Type /Catalog /Pages 2 0 R >>", "<< /Type /Pages /Count \(pages.count) /Kids [\(pages.indices.map { "\(3 + $0 * 2) 0 R" }.joined(separator: " "))] >>"]
        for (index, page) in pages.enumerated() {
            objects.append("<< /Type /Page /Parent 2 0 R /MediaBox \(page.0) /CropBox \(page.1) /Rotate \(page.2) /Resources << >> /Contents \(4 + index * 2) 0 R >>")
            objects.append("<< /Length \(page.3.utf8.count) >>\nstream\n\(page.3)\nendstream")
        }
        var result = "%PDF-1.4\n", offsets = [0]
        for (index, object) in objects.enumerated() { offsets.append(result.utf8.count); result += "\(index + 1) 0 obj\n\(object)\nendobj\n" }
        let xref = result.utf8.count
        result += "xref\n0 \(objects.count + 1)\n0000000000 65535 f \n"
        for offset in offsets.dropFirst() { result += String(format: "%010d 00000 n \n", offset) }
        result += "trailer\n<< /Size \(objects.count + 1) /Root 1 0 R >>\nstartxref\n\(xref)\n%%EOF\n"
        return Data(result.utf8)
    }
}
