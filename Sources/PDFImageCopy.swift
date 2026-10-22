import Foundation
import CoreGraphics
import ImageIO

/// Finds actual raster image paints in a PDF page. Coordinates match DocumentPage:
/// the cropped, rotated page with its origin at the lower left. Create and render
/// off the main thread; a Selection keeps its PDF alive until copying completes.
final class PDFImageCopy {
    enum Failure: Error { case invalidDocument, cannotRender }

    final class Selection {
        let bounds: CGRect
        let pixelSize: CGSize
        private let owner: PDFImageCopy
        private let paint: ImagePaint

        fileprivate init(owner: PDFImageCopy, paint: ImagePaint) {
            self.owner = owner
            self.paint = paint
            bounds = paint.bounds
            pixelSize = CGSize(width: paint.width, height: paint.height)
        }

        /// Returns a bounded, color-managed RGBA bitmap. Simple images are copied
        /// from their original samples; masks and unusual PDF color spaces use
        /// Core Graphics to render only the hit image's visible region.
        func render(maxPixelDimension: Int = 8192) throws -> CGImage {
            owner.lock.lock(); defer { owner.lock.unlock() }
            let xLength = hypot(paint.transform.a, paint.transform.b)
            let yLength = hypot(paint.transform.c, paint.transform.d)
            let nativeScale = max(CGFloat(paint.width) / max(xLength, 0.0001),
                                  CGFloat(paint.height) / max(yLength, 0.0001))
            let limit = CGFloat(min(8192, max(1, maxPixelDimension)))
            let scale = min(nativeScale, limit / max(bounds.width, bounds.height),
                            sqrt(32_000_000 / (bounds.width * bounds.height)))
            guard scale.isFinite, scale > 0 else { throw Failure.cannotRender }
            let width = max(1, Int(ceil(bounds.width * scale)))
            let height = max(1, Int(ceil(bounds.height * scale)))
            guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                          bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
                throw Failure.cannotRender
            }
            context.scaleBy(x: CGFloat(width) / bounds.width, y: CGFloat(height) / bounds.height)
            context.translateBy(x: -bounds.minX, y: -bounds.minY)
            context.interpolationQuality = .high
            if let original = owner.originalImage(paint) {
                for clip in paint.clips {
                    context.addPath(clip.path)
                    context.clip(using: clip.rule)
                }
                context.concatenate(paint.transform)
                context.draw(original, in: CGRect(x: 0, y: 0, width: 1, height: 1))
            } else {
                context.concatenate(owner.pageTransform)
                context.drawPDFPage(owner.page)
                // Drawing the same antialiased clip a second time squares edge
                // coverage and darkens rotated image borders. Restrict the
                // region using minimum coverage after the native PDF draw.
                guard let mask = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                           bytesPerRow: 0, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: 0),
                      let pixels = context.data?.assumingMemoryBound(to: UInt8.self),
                      let coverage = mask.data?.assumingMemoryBound(to: UInt8.self) else {
                    throw Failure.cannotRender
                }
                mask.scaleBy(x: CGFloat(width) / bounds.width, y: CGFloat(height) / bounds.height)
                mask.translateBy(x: -bounds.minX, y: -bounds.minY)
                for clip in paint.clips { mask.addPath(clip.path); mask.clip(using: clip.rule) }
                mask.addPath(paint.outline); mask.clip()
                mask.setFillColor(gray: 1, alpha: 1); mask.fill(bounds)
                for y in 0..<height {
                    for x in 0..<width {
                        let offset = y * context.bytesPerRow + x * 4
                        let alpha = Int(pixels[offset + 3])
                        let clipped = min(alpha, Int(coverage[y * mask.bytesPerRow + x]))
                        if clipped < alpha {
                            for channel in 0..<3 { pixels[offset + channel] = UInt8(Int(pixels[offset + channel]) * clipped / max(1, alpha)) }
                            pixels[offset + 3] = UInt8(clipped)
                        }
                    }
                }
            }
            guard let image = context.makeImage() else { throw Failure.cannotRender }
            return image
        }
    }

    let pageSize: CGSize
    private let document: CGPDFDocument
    private let page: CGPDFPage
    private let pageTransform: CGAffineTransform
    private let lock = NSLock()
    private var images: [ImagePaint] = []
    private var remainingOperators = 200_000
    private var scanDeadline = Double.infinity
    private var activeForms = Set<UInt>()
    private var scanFailed = false

    fileprivate struct Clip {
        let path: CGPath
        let rule: CGPathFillRule
    }
    fileprivate struct ImagePaint {
        let stream: CGPDFStreamRef?
        let transform: CGAffineTransform
        let outline: CGPath
        fileprivate let clips: [Clip]
        let bounds: CGRect
        let width: Int
        let height: Int
        let canExtract: Bool
    }
    private struct GraphicsState {
        var transform: CGAffineTransform
        var clips: [Clip]
        var canExtract = true
    }
    private final class ScannerState {
        let owner: PDFImageCopy
        var graphics: GraphicsState
        var saved: [GraphicsState] = []
        var path = CGMutablePath()
        var pendingClip: CGPathFillRule?
        let depth: Int
        let resources: CGPDFDictionaryRef
        init(owner: PDFImageCopy, graphics: GraphicsState, resources: CGPDFDictionaryRef, depth: Int) {
            self.owner = owner; self.graphics = graphics; self.resources = resources; self.depth = depth
        }
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: x, y: y).applying(graphics.transform)
        }
        func finishPath() {
            if let rule = pendingClip {
                graphics.clips.append(Clip(path: path.copy()!, rule: rule))
            }
            pendingClip = nil
            path = CGMutablePath()
        }
    }

    init(url: URL, pageIndex: Int) throws {
        guard url.isFileURL, pageIndex >= 0, let document = CGPDFDocument(url as CFURL),
              !document.isEncrypted || document.isUnlocked,
              pageIndex < document.numberOfPages, let page = document.page(at: pageIndex + 1),
              let pageDictionary = page.dictionary else {
            throw Failure.invalidDocument
        }
        self.document = document
        self.page = page
        let crop = page.getBoxRect(.cropBox)
        let box: CGPDFBox = Self.valid(crop) ? .cropBox : .mediaBox
        let rect = page.getBoxRect(box)
        guard Self.valid(rect) else { throw Failure.invalidDocument }
        let rotation = ((page.rotationAngle % 360) + 360) % 360
        pageSize = rotation == 90 || rotation == 270 ? CGSize(width: rect.height, height: rect.width) : rect.size
        let visible = CGRect(origin: .zero, size: pageSize)
        pageTransform = page.getDrawingTransform(box, rect: visible, rotate: 0, preserveAspectRatio: true)
        let content = CGPDFContentStreamCreateWithPage(page)
        defer { CGPDFContentStreamRelease(content) }
        let state = GraphicsState(transform: pageTransform,
                                  clips: [Clip(path: CGPath(rect: visible, transform: nil), rule: .winding)])
        var resourceOwner = pageDictionary
        var resources: CGPDFDictionaryRef?
        // The page tree may inherit its resource dictionary from a parent.
        for _ in 0..<64 {
            if CGPDFDictionaryGetDictionary(resourceOwner, "Resources", &resources) { break }
            var parent: CGPDFDictionaryRef?
            guard CGPDFDictionaryGetDictionary(resourceOwner, "Parent", &parent), let parent else { break }
            resourceOwner = parent
        }
        scanDeadline = ProcessInfo.processInfo.systemUptime + 2
        scan(content, state: state, resources: resources ?? resourceOwner, depth: 0)
        // An incomplete parse must not offer a misleading selection.
        if scanFailed { images.removeAll() }
    }

    func image(at point: CGPoint) -> Selection? {
        guard point.x.isFinite, point.y.isFinite else { return nil }
        for paint in images.reversed() {
            guard paint.bounds.contains(point), paint.outline.contains(point),
                  paint.clips.allSatisfy({ $0.path.contains(point, using: $0.rule) }) else { continue }
            return Selection(owner: self, paint: paint)
        }
        return nil
    }

    private static func valid(_ rect: CGRect) -> Bool {
        !rect.isNull && !rect.isInfinite && rect.minX.isFinite && rect.minY.isFinite &&
        rect.width.isFinite && rect.height.isFinite && rect.width > 0 && rect.height > 0 &&
        rect.width <= 1e9 && rect.height <= 1e9
    }
    private static func finite(_ t: CGAffineTransform) -> Bool {
        [t.a, t.b, t.c, t.d, t.tx, t.ty].allSatisfy { $0.isFinite && abs($0) <= 1e12 } &&
        abs(t.a * t.d - t.b * t.c) > 1e-12
    }

    private static func state(_ scanner: CGPDFScannerRef, _ info: UnsafeMutableRawPointer?) -> ScannerState? {
        guard let info else { return nil }
        let state = Unmanaged<ScannerState>.fromOpaque(info).takeUnretainedValue()
        state.owner.remainingOperators -= 1
        guard !state.owner.scanFailed, state.owner.remainingOperators > 0,
              ProcessInfo.processInfo.systemUptime < state.owner.scanDeadline,
              state.graphics.clips.count < 1024 else {
            state.owner.scanFailed = true
            CGPDFScannerStop(scanner)
            return nil
        }
        return state
    }
    private static func numbers(_ scanner: CGPDFScannerRef, _ count: Int) -> [CGFloat]? {
        var values = [CGFloat](repeating: 0, count: count)
        for i in (0..<count).reversed() {
            guard CGPDFScannerPopNumber(scanner, &values[i]), values[i].isFinite, abs(values[i]) <= 1e12 else { return nil }
        }
        return values
    }
    private static func arrayNumbers(_ dictionary: CGPDFDictionaryRef, _ key: String, count: Int) -> [CGFloat]? {
        var array: CGPDFArrayRef?
        guard CGPDFDictionaryGetArray(dictionary, key, &array), let array, CGPDFArrayGetCount(array) == count else { return nil }
        var result = [CGFloat](repeating: 0, count: count)
        for i in 0..<count {
            guard CGPDFArrayGetNumber(array, i, &result[i]), result[i].isFinite, abs(result[i]) <= 1e12 else { return nil }
        }
        return result
    }

    private func scan(_ content: CGPDFContentStreamRef, state: GraphicsState, resources: CGPDFDictionaryRef, depth: Int) {
        guard depth <= 24, !scanFailed, let table = CGPDFOperatorTableCreate() else { scanFailed = true; return }
        defer { CGPDFOperatorTableRelease(table) }
        CGPDFOperatorTableSetCallback(table, "q") { scanner, info in
            guard let s = PDFImageCopy.state(scanner, info) else { return }
            guard s.saved.count < 128 else { s.owner.scanFailed = true; CGPDFScannerStop(scanner); return }
            s.saved.append(s.graphics)
        }
        CGPDFOperatorTableSetCallback(table, "Q") { scanner, info in
            guard let s = PDFImageCopy.state(scanner, info) else { return }
            if let saved = s.saved.popLast() { s.graphics = saved }
        }
        CGPDFOperatorTableSetCallback(table, "cm") { scanner, info in
            guard let s = PDFImageCopy.state(scanner, info), let n = PDFImageCopy.numbers(scanner, 6) else { return }
            let transform = CGAffineTransform(a: n[0], b: n[1], c: n[2], d: n[3], tx: n[4], ty: n[5]).concatenating(s.graphics.transform)
            guard PDFImageCopy.finite(transform) else { s.owner.scanFailed = true; CGPDFScannerStop(scanner); return }
            s.graphics.transform = transform
        }
        CGPDFOperatorTableSetCallback(table, "Do") { scanner, info in
            guard let s = PDFImageCopy.state(scanner, info) else { return }
            var name: UnsafePointer<CChar>?
            guard CGPDFScannerPopName(scanner, &name), let name,
                  let object = CGPDFContentStreamGetResource(CGPDFScannerGetContentStream(scanner), "XObject", name) else { return }
            var stream: CGPDFStreamRef?
            guard CGPDFObjectGetValue(object, .stream, &stream), let stream else { return }
            s.owner.paint(stream, scanner: scanner, state: s)
        }
        CGPDFOperatorTableSetCallback(table, "EI") { scanner, info in
            guard let s = PDFImageCopy.state(scanner, info) else { return }
            var stream: CGPDFStreamRef?
            if CGPDFScannerPopStream(scanner, &stream), let stream { s.owner.addImage(stream, state: s.graphics, inline: true) }
        }
        CGPDFOperatorTableSetCallback(table, "gs") { scanner, info in
            guard let s = PDFImageCopy.state(scanner, info) else { return }
            // The fallback respects blend modes, alpha, soft masks and rendering
            // intents without trying to reimplement the PDF compositor.
            s.graphics.canExtract = false
        }
        CGPDFOperatorTableSetCallback(table, "m") { scanner, info in
            guard let s = PDFImageCopy.state(scanner, info), let n = PDFImageCopy.numbers(scanner, 2) else { return }
            s.path.move(to: s.point(n[0], n[1]))
        }
        CGPDFOperatorTableSetCallback(table, "l") { scanner, info in
            guard let s = PDFImageCopy.state(scanner, info), let n = PDFImageCopy.numbers(scanner, 2) else { return }
            s.path.addLine(to: s.point(n[0], n[1]))
        }
        CGPDFOperatorTableSetCallback(table, "c") { scanner, info in
            guard let s = PDFImageCopy.state(scanner, info), let n = PDFImageCopy.numbers(scanner, 6) else { return }
            s.path.addCurve(to: s.point(n[4], n[5]), control1: s.point(n[0], n[1]), control2: s.point(n[2], n[3]))
        }
        CGPDFOperatorTableSetCallback(table, "v") { scanner, info in
            guard let s = PDFImageCopy.state(scanner, info), let n = PDFImageCopy.numbers(scanner, 4) else { return }
            s.path.addCurve(to: s.point(n[2], n[3]), control1: s.path.currentPoint, control2: s.point(n[0], n[1]))
        }
        CGPDFOperatorTableSetCallback(table, "y") { scanner, info in
            guard let s = PDFImageCopy.state(scanner, info), let n = PDFImageCopy.numbers(scanner, 4) else { return }
            s.path.addCurve(to: s.point(n[2], n[3]), control1: s.point(n[0], n[1]), control2: s.point(n[2], n[3]))
        }
        CGPDFOperatorTableSetCallback(table, "re") { scanner, info in
            guard let s = PDFImageCopy.state(scanner, info), let n = PDFImageCopy.numbers(scanner, 4) else { return }
            s.path.move(to: s.point(n[0], n[1])); s.path.addLine(to: s.point(n[0] + n[2], n[1]))
            s.path.addLine(to: s.point(n[0] + n[2], n[1] + n[3])); s.path.addLine(to: s.point(n[0], n[1] + n[3])); s.path.closeSubpath()
        }
        CGPDFOperatorTableSetCallback(table, "h") { scanner, info in PDFImageCopy.state(scanner, info)?.path.closeSubpath() }
        CGPDFOperatorTableSetCallback(table, "W") { scanner, info in PDFImageCopy.state(scanner, info)?.pendingClip = .winding }
        CGPDFOperatorTableSetCallback(table, "W*") { scanner, info in PDFImageCopy.state(scanner, info)?.pendingClip = .evenOdd }
        for op in ["n", "S", "s", "f", "F", "f*", "B", "B*", "b", "b*"] {
            CGPDFOperatorTableSetCallback(table, op) { scanner, info in PDFImageCopy.state(scanner, info)?.finishPath() }
        }
        let scannerState = ScannerState(owner: self, graphics: state, resources: resources, depth: depth)
        let scanner = CGPDFScannerCreate(content, table, Unmanaged.passUnretained(scannerState).toOpaque())
        defer { CGPDFScannerRelease(scanner) }
        // The C scanner stores an unretained pointer. Keep its callback state
        // alive across the whole scan, including under release optimization.
        let scanned = withExtendedLifetime(scannerState) { CGPDFScannerScan(scanner) }
        if !scanned { scanFailed = true }
    }

    private func paint(_ stream: CGPDFStreamRef, scanner: CGPDFScannerRef, state: ScannerState) {
        guard let dictionary = CGPDFStreamGetDictionary(stream) else { return }
        var subtype: UnsafePointer<CChar>?
        guard CGPDFDictionaryGetName(dictionary, "Subtype", &subtype), let subtype else { return }
        switch String(cString: subtype) {
        case "Image": addImage(stream, state: state.graphics)
        case "Form":
            let identity = UInt(bitPattern: stream.rawValue)
            guard !activeForms.contains(identity), state.depth < 24 else { return }
            var graphics = state.graphics
            if let m = Self.arrayNumbers(dictionary, "Matrix", count: 6) {
                graphics.transform = CGAffineTransform(a: m[0], b: m[1], c: m[2], d: m[3], tx: m[4], ty: m[5]).concatenating(graphics.transform)
            }
            guard Self.finite(graphics.transform) else { return }
            if let b = Self.arrayNumbers(dictionary, "BBox", count: 4) {
                var transform = graphics.transform
                let rect = CGRect(x: b[0], y: b[1], width: b[2] - b[0], height: b[3] - b[1]).standardized
                graphics.clips.append(Clip(path: CGPath(rect: rect, transform: &transform), rule: .winding))
            }
            var resources: CGPDFDictionaryRef?
            CGPDFDictionaryGetDictionary(dictionary, "Resources", &resources)
            let parent = CGPDFScannerGetContentStream(scanner)
            let inheritedResources = resources ?? state.resources
            let content = CGPDFContentStreamCreateWithStream(stream, inheritedResources, parent)
            activeForms.insert(identity)
            scan(content, state: graphics, resources: inheritedResources, depth: state.depth + 1)
            activeForms.remove(identity)
            CGPDFContentStreamRelease(content)
        default: break
        }
    }

    private func addImage(_ stream: CGPDFStreamRef, state: GraphicsState, inline: Bool = false) {
        guard images.count < 4096 else { scanFailed = true; return }
        guard Self.finite(state.transform), let dictionary = CGPDFStreamGetDictionary(stream) else { return }
        var width = 0, height = 0
        guard (CGPDFDictionaryGetInteger(dictionary, "Width", &width) || CGPDFDictionaryGetInteger(dictionary, "W", &width)),
              (CGPDFDictionaryGetInteger(dictionary, "Height", &height) || CGPDFDictionaryGetInteger(dictionary, "H", &height)),
              width > 0, height > 0, width <= 1_000_000, height <= 1_000_000 else { return }
        var transform = state.transform
        let outline = CGPath(rect: CGRect(x: 0, y: 0, width: 1, height: 1), transform: &transform)
        var bounds = outline.boundingBoxOfPath
        for clip in state.clips { bounds = bounds.intersection(clip.path.boundingBoxOfPath) }
        guard Self.valid(bounds) else { return }
        // Inline streams belong to the scanner's operand stack, rather than the
        // document object graph. Never retain their borrowed pointer after EI.
        images.append(ImagePaint(stream: inline ? nil : stream, transform: state.transform, outline: outline, clips: state.clips,
                                 bounds: bounds, width: width, height: height, canExtract: state.canExtract))
    }

    private func originalImage(_ paint: ImagePaint) -> CGImage? {
        guard paint.canExtract, paint.width <= 32_000_000 / paint.height, let stream = paint.stream,
              let dictionary = CGPDFStreamGetDictionary(stream) else { return nil }
        for key in ["SMask", "Mask", "Decode", "D", "ImageMask", "IM"] {
            var object: CGPDFObjectRef?
            if CGPDFDictionaryGetObject(dictionary, key, &object) { return nil }
        }
        var colorName: UnsafePointer<CChar>?
        guard (CGPDFDictionaryGetName(dictionary, "ColorSpace", &colorName) || CGPDFDictionaryGetName(dictionary, "CS", &colorName)),
              let colorName else { return nil }
        let color: CGColorSpace
        let components: Int
        switch String(cString: colorName) {
        case "DeviceRGB", "RGB": color = CGColorSpaceCreateDeviceRGB(); components = 3
        case "DeviceGray", "G": color = CGColorSpaceCreateDeviceGray(); components = 1
        case "DeviceCMYK", "CMYK": color = CGColorSpaceCreateDeviceCMYK(); components = 4
        default: return nil
        }
        var bits = 0
        guard (CGPDFDictionaryGetInteger(dictionary, "BitsPerComponent", &bits) || CGPDFDictionaryGetInteger(dictionary, "BPC", &bits)), bits == 8 else { return nil }
        var format = CGPDFDataFormat.raw
        guard let data = CGPDFStreamCopyData(stream, &format) else { return nil }
        if format == .jpegEncoded || format == .JPEG2000 {
            guard let source = CGImageSourceCreateWithData(data, nil),
                  let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                  let width = props[kCGImagePropertyPixelWidth] as? Int,
                  let height = props[kCGImagePropertyPixelHeight] as? Int,
                  width == paint.width, height == paint.height else { return nil }
            return CGImageSourceCreateImageAtIndex(source, 0, [kCGImageSourceShouldCacheImmediately: true] as CFDictionary)
        }
        let rowBytes = paint.width * components
        guard format == .raw, CFDataGetLength(data) == rowBytes * paint.height,
              let provider = CGDataProvider(data: data) else { return nil }
        return CGImage(width: paint.width, height: paint.height, bitsPerComponent: 8, bitsPerPixel: components * 8,
                       bytesPerRow: rowBytes, space: color, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                       provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
    }
}
