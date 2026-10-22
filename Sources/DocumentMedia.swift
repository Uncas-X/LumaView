import AppKit
import Foundation
import ImageIO
import QuartzCore

/// A document owns its source and serializes access to native PDF/SVG decoders.
/// Pages retain that owner, so asynchronous tile draws remain valid after a file switch.
final class DocumentMedia {
    let url: URL
    let pageCount: Int
    let isVector: Bool
    let format: String
    private let source: Source
    fileprivate let drawLock = NSRecursiveLock()
    private let pageRequestLock = NSLock()
    private var pageRequestGeneration: UInt64 = 0
    private static let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "LumaView.DocumentMedia"
        queue.maxConcurrentOperationCount = 2
        queue.qualityOfService = .userInitiated
        return queue
    }()

    private enum Source {
        case pdf(CGPDFDocument)
        case image(NSImage)
        case tiff(CGImageSource)
        case embeddedPreview(EmbeddedEPSPreview.Preview)
    }

    static func canOpen(_ url: URL) -> Bool {
        ["pdf", "ai", "svg", "eps", "epsf", "ps", "tif", "tiff"].contains(url.pathExtension.lowercased())
    }

    @discardableResult
    static func load(url: URL, completion: @escaping (Result<DocumentMedia, Error>) -> Void) -> ThumbnailRequest {
        let request = ThumbnailRequest()
        queue.addOperation {
            guard !request.isCancelled else { return }
            let result = Result { try DocumentMedia(url: url, request: request) }
            DispatchQueue.main.async { request.finish { completion(result) } }
        }
        return request
    }

    init(url: URL, request: ThumbnailRequest? = nil) throws {
        guard url.isFileURL, FileManager.default.isReadableFile(atPath: url.path) else { throw VectorRenderError.invalidDocument }
        self.url = url
        let ext = url.pathExtension.lowercased()
        if ext == "svg" {
            let image = try VectorRenderer.validatedSVGImage(url: url)
            source = .image(image)
            pageCount = 1
            isVector = true
            format = "SVG"
        } else if ["tif", "tiff"].contains(ext),
                  let raster = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary),
                  CGImageSourceGetCount(raster) > 0 {
            source = .tiff(raster)
            pageCount = CGImageSourceGetCount(raster)
            isVector = false
            format = "TIFF"
        } else if let pdf = CGPDFDocument(url as CFURL), pdf.numberOfPages > 0, !pdf.isEncrypted || pdf.isUnlocked {
            source = .pdf(pdf)
            pageCount = pdf.numberOfPages
            isVector = true
            format = ext == "ai" ? "AI / PDF" : "PDF"
        } else if ["ai", "eps", "epsf", "ps"].contains(ext) {
            do {
                let converted = try PostScriptDocument.convert(url: url, request: request)
                guard let pdf = CGPDFDocument(converted as CFURL), pdf.numberOfPages > 0 else { throw VectorRenderError.cannotRender }
                source = .pdf(pdf)
                pageCount = pdf.numberOfPages
                isVector = true
                format = ext == "ai" ? "AI / PostScript" : (ext == "ps" ? "PostScript" : "EPS")
            } catch {
                if error is CancellationError { throw error }
                guard let preview = EmbeddedEPSPreview.load(url: url) else { throw error }
                source = .embeddedPreview(preview)
                pageCount = 1
                isVector = false
                format = "EPS（内嵌 TIFF 预览）"
            }
        } else {
            throw VectorRenderError.invalidDocument
        }
    }

    /// Zero-based page index. PDF/SVG pages carry source instructions, not a fixed bitmap.
    func page(at index: Int, maxPixelDimension: Int = 8192) throws -> DocumentPage {
        let page = try makePage(at: index, maxPixelDimension: maxPixelDimension)
        // Synchronous callers still get a complete, bounded first presentation.
        // Interactive loads use the viewport-sized asynchronous path below.
        try page.preparePresentationPreview(maxPixelDimension: 1024)
        return page
    }

    private func makePage(at index: Int, maxPixelDimension: Int = 8192) throws -> DocumentPage {
        guard index >= 0, index < pageCount else { throw VectorRenderError.invalidDocument }
        drawLock.lock()
        defer { drawLock.unlock() }
        switch source {
        case .pdf(let document):
            guard let page = document.page(at: index + 1) else { throw VectorRenderError.invalidDocument }
            let crop = page.getBoxRect(.cropBox)
            let box: CGPDFBox = Self.valid(crop.size) ? .cropBox : .mediaBox
            let bounds = page.getBoxRect(box)
            guard Self.valid(bounds.size) else { throw VectorRenderError.invalidDocument }
            let rotation = ((page.rotationAngle % 360) + 360) % 360
            let size = rotation == 90 || rotation == 270 ? CGSize(width: bounds.height, height: bounds.width) : bounds.size
            return DocumentPage(document: self, index: index, size: size, content: .pdf(page, box))
        case .image(let image):
            return DocumentPage(document: self, index: index, size: image.size, content: .vectorImage(image))
        case .embeddedPreview(let preview):
            return DocumentPage(document: self, index: index, size: preview.size, content: .raster(preview.image))
        case .tiff(let source):
            guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [String: Any],
                  let width = properties[kCGImagePropertyPixelWidth as String] as? NSNumber,
                  let height = properties[kCGImagePropertyPixelHeight as String] as? NSNumber else { throw VectorRenderError.invalidDocument }
            var size = CGSize(width: width.doubleValue, height: height.doubleValue)
            guard Self.valid(size) else { throw VectorRenderError.invalidDocument }
            let orientation = (properties[kCGImagePropertyOrientation as String] as? NSNumber)?.intValue ?? 1
            if [5, 6, 7, 8].contains(orientation) { size = CGSize(width: size.height, height: size.width) }
            let target = DocumentPage.bitmapSize(for: size, maxDimension: maxPixelDimension)
            let options: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                                          kCGImageSourceCreateThumbnailWithTransform: true,
                                          kCGImageSourceThumbnailMaxPixelSize: Int(max(target.width, target.height)),
                                          kCGImageSourceShouldCacheImmediately: true]
            guard let image = CGImageSourceCreateThumbnailAtIndex(source, index, options as CFDictionary) else { throw VectorRenderError.cannotRender }
            return DocumentPage(document: self, index: index, size: size, content: .raster(image))
        }
    }

    /// A page is published only after its complete initial image is ready. The
    /// canvas keeps the previous page visible while this work runs off main.
    func loadPage(at index: Int, previewMaxPixelDimension: Int = 4096,
                  completion: @escaping (Result<DocumentPage, Error>) -> Void) {
        let request = nextPageRequest()
        let operation = BlockOperation { [weak self] in
            guard let self, self.isCurrentPageRequest(request) else { return }
            let result = Result { () throws -> DocumentPage in
                let page = try self.makePage(at: index)
                guard self.isCurrentPageRequest(request) else { throw CancellationError() }
                try page.preparePresentationPreview(maxPixelDimension: previewMaxPixelDimension)
                return page
            }
            guard self.isCurrentPageRequest(request) else { return }
            DispatchQueue.main.async { [weak self] in
                guard self?.isCurrentPageRequest(request) == true else { return }
                completion(result)
            }
        }
        operation.queuePriority = .veryHigh
        Self.queue.addOperation(operation)
    }

    /// Invalidates pending/finished callbacks without blocking on a native draw.
    /// A Core Graphics draw already in progress finishes into its bounded buffer.
    func cancelPendingPageLoads() { _ = nextPageRequest() }

    private func nextPageRequest() -> UInt64 {
        pageRequestLock.lock(); defer { pageRequestLock.unlock() }
        pageRequestGeneration &+= 1
        return pageRequestGeneration
    }

    private func isCurrentPageRequest(_ request: UInt64) -> Bool {
        pageRequestLock.lock(); defer { pageRequestLock.unlock() }
        return request == pageRequestGeneration
    }

    func thumbnail(at index: Int, maxPixelDimension: Int = 160, completion: @escaping (CGImage?) -> Void) {
        Self.queue.addOperation {
            let image = try? self.makePage(at: index, maxPixelDimension: maxPixelDimension).preview(maxPixelDimension: maxPixelDimension)
            DispatchQueue.main.async { completion(image) }
        }
    }

    fileprivate static func valid(_ size: CGSize) -> Bool {
        size.width.isFinite && size.height.isFinite && size.width > 0 && size.height > 0 && size.width <= 1e9 && size.height <= 1e9
    }
}

final class DocumentPage {
    let document: DocumentMedia
    let index: Int
    /// Oriented PDF points, SVG coordinates, or original TIFF pixels.
    let size: CGSize
    var isVector: Bool { document.isVector }
    var rasterImage: CGImage? { if case .raster(let image) = content { return image }; return nil }
    /// Complete page used for immediate, atomic presentation. It is prepared
    /// before publishing the page; original vector instructions remain retained.
    var presentationPreview: CGImage? { rasterImage ?? vectorPresentationPreview }
    private var vectorPresentationPreview: CGImage?
    fileprivate enum Content {
        case pdf(CGPDFPage, CGPDFBox)
        case vectorImage(NSImage)
        case raster(CGImage)
    }
    private let content: Content

    fileprivate init(document: DocumentMedia, index: Int, size: CGSize, content: Content) {
        self.document = document
        self.index = index
        self.size = size
        self.content = content
    }

    /// Draws native vector instructions at the requested context scale. Callers
    /// may clip to a tiny tile even at 3200% zoom; no full-page bitmap is allocated.
    func draw(in context: CGContext, rect: CGRect) {
        guard rect.width > 0, rect.height > 0, rect.width.isFinite, rect.height.isFinite else { return }
        document.drawLock.lock()
        defer { document.drawLock.unlock() }
        context.saveGState()
        defer { context.restoreGState() }
        context.clip(to: rect)
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(rect)
        context.translateBy(x: rect.minX, y: rect.minY)
        context.scaleBy(x: rect.width / size.width, y: rect.height / size.height)
        switch content {
        case .pdf(let page, let box):
            context.concatenate(page.getDrawingTransform(box, rect: CGRect(origin: .zero, size: size), rotate: 0, preserveAspectRatio: true))
            context.drawPDFPage(page)
        case .vectorImage(let image):
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
            image.draw(in: CGRect(origin: .zero, size: size), from: .zero, operation: .sourceOver, fraction: 1,
                       respectFlipped: false, hints: [.interpolation: NSImageInterpolation.high])
            NSGraphicsContext.restoreGraphicsState()
        case .raster(let image):
            context.interpolationQuality = .high
            context.draw(image, in: CGRect(origin: .zero, size: size))
        }
    }

    fileprivate func preparePresentationPreview(maxPixelDimension: Int) throws {
        guard isVector else { return }
        // At most a 4096 × 4096 surface (64 MiB), independent of page coordinates.
        // This does not cap vector zoom: the tile layer draws the original source.
        vectorPresentationPreview = try preview(maxPixelDimension: min(4096, max(1, maxPixelDimension)))
    }

    func preview(maxPixelDimension: Int = 1024) throws -> CGImage {
        let dimensions = Self.bitmapSize(for: size, maxDimension: maxPixelDimension)
        guard let context = CGContext(data: nil, width: Int(dimensions.width), height: Int(dimensions.height), bitsPerComponent: 8,
                                      bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { throw VectorRenderError.cannotRender }
        draw(in: context, rect: CGRect(origin: .zero, size: dimensions))
        guard let image = context.makeImage() else { throw VectorRenderError.cannotRender }
        return image
    }

    fileprivate static func bitmapSize(for size: CGSize, maxDimension: Int) -> CGSize {
        let longest = max(size.width, size.height)
        let requested = CGFloat(max(1, min(8192, maxDimension)))
        let widthRatio = size.width / longest, heightRatio = size.height / longest
        let maximum = min(requested, sqrt(32_000_000 / (widthRatio * heightRatio)))
        return CGSize(width: max(1, floor(widthRatio * maximum)), height: max(1, floor(heightRatio * maximum)))
    }
}

/// Core Animation asks for only the visible 512-pixel tiles at the current
/// transform's resolution. Strong page ownership also covers in-flight draws.
final class DocumentTileLayer: CATiledLayer {
    var documentPage: DocumentPage?

    override init() {
        super.init()
        tileSize = CGSize(width: 512, height: 512)
        // The bias consumes six levels for magnification. Keep enough lower
        // resolutions for huge page coordinate systems at fit-to-window scale;
        // Core Animation clamps unused levels to the actual layer dimensions.
        levelsOfDetail = 27
        levelsOfDetailBias = 6
        // Unrendered tiles must reveal the complete page beneath them. Individual
        // tile draws still paint opaque white paper through DocumentPage.draw.
        isOpaque = false
        backgroundColor = nil
    }

    override init(layer: Any) {
        super.init(layer: layer)
        documentPage = (layer as? DocumentTileLayer)?.documentPage
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }
    override class func fadeDuration() -> CFTimeInterval { 0 }
    override func draw(in context: CGContext) {
        documentPage?.draw(in: context, rect: bounds)
    }
}
