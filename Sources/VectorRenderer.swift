import AppKit
import Foundation
import ImageIO

enum VectorRenderError: LocalizedError {
    case invalidDocument
    case unsafeSVG
    case unsupportedPostScript
    case cannotRender

    var errorDescription: String? {
        switch self {
        case .invalidDocument: return L10n.tr("这个矢量文件无效，或没有可显示的页面。")
        case .unsafeSVG: return L10n.tr("此 SVG 包含脚本、动态内容或外部资源。离线预览支持内部引用及嵌入的位图，请先将外部资源嵌入文件。")
        case .unsupportedPostScript: return L10n.tr("此 AI / EPS / PostScript 文件无法由当前 macOS 渲染。请另存为启用 PDF 兼容的 AI、PDF 或 SVG 后打开。")
        case .cannotRender: return L10n.tr("系统无法渲染这个矢量文件。")
        }
    }
}

struct RenderedVector {
    let image: CGImage
    /// SVG coordinates or PDF page points, before rasterization.
    let originalSize: CGSize
    let format: String
    let pageCount: Int
}

/// Static, offline rendering. SVG uses AppKit's native vector image rep, never a
/// web view. References are checked before AppKit receives the source bytes.
enum VectorRenderer {
    static let defaultMaximumDimension = 4096
    private static let renderQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "LumaView.VectorRender"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        return queue
    }()

    /// Shared with the live vector canvas. Disable AppKit bitmap caching so each
    /// tiled draw retains the SVG representation at the requested display scale.
    static func validatedSVGImage(url: URL) throws -> NSImage {
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        let safeData = try SVGInspector.validatedData(data)
        guard let image = NSImage(data: safeData), valid(image.size) else { throw VectorRenderError.cannotRender }
        image.cacheMode = .never
        return image
    }

    static func render(url: URL, maxPixelDimension: Int = defaultMaximumDimension, request: ThumbnailRequest? = nil) throws -> RenderedVector {
        guard url.isFileURL, FileManager.default.isReadableFile(atPath: url.path) else { throw VectorRenderError.invalidDocument }
        if url.pathExtension.lowercased() == "svg" {
            let image = try validatedSVGImage(url: url)
            return RenderedVector(image: try rasterize(image, maxDimension: maxPixelDimension),
                                  originalSize: image.size, format: "SVG 矢量预览", pageCount: 1)
        }
        // Illustrator's PDF-compatible files are ordinary PDF data even when
        // their suffix is .ai. Core Graphics never runs PDF JavaScript or links.
        if let document = CGPDFDocument(url as CFURL), let page = document.page(at: 1) {
            var boxType: CGPDFBox = .cropBox
            var box = page.getBoxRect(boxType)
            if !valid(box.size) { boxType = .mediaBox; box = page.getBoxRect(boxType) }
            guard valid(box.size) else { throw VectorRenderError.invalidDocument }
            let rotation = ((page.rotationAngle % 360) + 360) % 360
            let size = rotation == 90 || rotation == 270 ? CGSize(width: box.height, height: box.width) : box.size
            let target = bitmapSize(for: size, maxDimension: maxPixelDimension)
            guard let context = makeContext(target) else { throw VectorRenderError.cannotRender }
            context.setFillColor(NSColor.white.cgColor)
            context.fill(CGRect(origin: .zero, size: target))
            // getDrawingTransform preserves page-point scale when the target is
            // larger. Scale the context explicitly for a crisp high-resolution
            // preview, then let PDF geometry handle crop origins and rotation.
            context.scaleBy(x: target.width / size.width, y: target.height / size.height)
            context.concatenate(page.getDrawingTransform(boxType, rect: CGRect(origin: .zero, size: size), rotate: 0, preserveAspectRatio: true))
            context.drawPDFPage(page)
            guard let image = context.makeImage() else { throw VectorRenderError.cannotRender }
            return RenderedVector(image: image, originalSize: size,
                                  format: url.pathExtension.lowercased() == "ai" ? "AI（PDF 兼容）矢量预览" : "PDF 页面预览",
                                  pageCount: document.numberOfPages)
        }
        if ["ai", "eps", "epsf", "ps"].contains(url.pathExtension.lowercased()) {
            do {
                let converted = try PostScriptDocument.convert(url: url, request: request)
                let rendered = try render(url: converted, maxPixelDimension: maxPixelDimension, request: request)
                return RenderedVector(image: rendered.image, originalSize: rendered.originalSize,
                                      format: "PostScript", pageCount: rendered.pageCount)
            } catch {
                if error is CancellationError { throw error }
                if let preview = EmbeddedEPSPreview.load(url: url, maxPixelDimension: maxPixelDimension) {
                    return RenderedVector(image: preview.image, originalSize: preview.size,
                                          format: "EPS（内嵌 TIFF 预览）", pageCount: 1)
                }
                throw error
            }
        }
        throw VectorRenderError.invalidDocument
    }

    /// Optional higher-resolution rerendering. Output remains bounded to 8192
    /// pixels per side / 32 MP; callers must discard results for old selections.
    static func renderAsync(url: URL, maxPixelDimension: Int, completion: @escaping (Result<RenderedVector, Error>) -> Void) {
        renderQueue.addOperation {
            let result = Result { try render(url: url, maxPixelDimension: maxPixelDimension) }
            DispatchQueue.main.async { completion(result) }
        }
    }

    private static func valid(_ size: CGSize) -> Bool {
        size.width.isFinite && size.height.isFinite && size.width > 0 && size.height > 0
    }

    private static func bitmapSize(for size: CGSize, maxDimension: Int) -> CGSize {
        let longest = max(size.width, size.height)
        let requested = CGFloat(max(1, min(8192, maxDimension)))
        let widthRatio = size.width / longest, heightRatio = size.height / longest
        let maximum = min(requested, sqrt(32_000_000 / (widthRatio * heightRatio)))
        return CGSize(width: max(1, floor(widthRatio * maximum)), height: max(1, floor(heightRatio * maximum)))
    }

    private static func makeContext(_ size: CGSize) -> CGContext? {
        CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0,
                  space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    }

    private static func rasterize(_ image: NSImage, maxDimension: Int) throws -> CGImage {
        let size = bitmapSize(for: image.size, maxDimension: maxDimension)
        guard let context = makeContext(size) else { throw VectorRenderError.cannotRender }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        image.draw(in: CGRect(origin: .zero, size: size), from: .zero, operation: .copy, fraction: 1,
                   respectFlipped: false, hints: [.interpolation: NSImageInterpolation.high])
        NSGraphicsContext.restoreGraphicsState()
        guard let result = context.makeImage() else { throw VectorRenderError.cannotRender }
        return result
    }
}

/// DOS EPS files may carry an independently decodable TIFF preview. Extract only
/// that bounded section; PostScript instructions are never interpreted here.
enum EmbeddedEPSPreview {
    struct Preview {
        let image: CGImage
        /// Native, oriented preview pixels, not the PostScript artwork's points.
        let size: CGSize
    }

    static func load(url: URL, maxPixelDimension: Int = 8192) -> Preview? {
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else { return nil }
        return load(data: data, maxPixelDimension: maxPixelDimension)
    }

    static func load(data: Data, maxPixelDimension: Int = 8192) -> Preview? {
        guard data.count >= 30, Array(data.prefix(4)) == [0xC5, 0xD0, 0xD3, 0xC6] else { return nil }
        func uint32(_ offset: Int) -> Int {
            (0..<4).reduce(0) { $0 | (Int(data[data.startIndex + offset + $1]) << ($1 * 8)) }
        }
        func section(offset: Int, length: Int) -> Range<Int>? {
            guard offset >= 30, length > 0, offset <= data.count, length <= data.count - offset else { return nil }
            return offset..<(offset + length)
        }
        guard let postScript = section(offset: uint32(4), length: uint32(8)),
              let tiff = section(offset: uint32(20), length: uint32(24)),
              !postScript.overlaps(tiff), postScript.count >= 4,
              data.subdata(in: postScript.lowerBound..<(postScript.lowerBound + 4)) == Data("%!PS".utf8) else { return nil }
        let originalBytes = data.subdata(in: tiff)
        // Some Illustrator exporters store 8-bit palette + alpha TIFFs. ImageIO
        // treats their two interleaved samples as palette indices, producing
        // vertical stripes. Normalize that precise encoding in memory first.
        let bytes = normalizedPaletteTIFF(originalBytes) ?? originalBytes
        guard let source = CGImageSourceCreateWithData(bytes as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
              CGImageSourceGetType(source) as String? == "public.tiff",
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
              let width = properties[kCGImagePropertyPixelWidth as String] as? NSNumber,
              let height = properties[kCGImagePropertyPixelHeight as String] as? NSNumber else { return nil }
        var size = CGSize(width: width.doubleValue, height: height.doubleValue)
        guard size.width.isFinite, size.height.isFinite, size.width > 0, size.height > 0,
              size.width <= 1e9, size.height <= 1e9 else { return nil }
        let orientation = (properties[kCGImagePropertyOrientation as String] as? NSNumber)?.intValue ?? 1
        if [5, 6, 7, 8].contains(orientation) { size = CGSize(width: size.height, height: size.width) }
        let longest = max(size.width, size.height)
        let pixelLimit = sqrt(32_000_000 / ((size.width / longest) * (size.height / longest)))
        let maximum = Int(min(longest, min(pixelLimit, CGFloat(max(1, min(8192, maxPixelDimension))))))
        let options: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                                      kCGImageSourceCreateThumbnailWithTransform: true,
                                      kCGImageSourceThumbnailMaxPixelSize: max(1, maximum),
                                      kCGImageSourceShouldCacheImmediately: true]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return Preview(image: image, size: size)
    }

    private static func normalizedPaletteTIFF(_ data: Data) -> Data? {
        guard data.count >= 8 else { return nil }
        let little: Bool
        if data.prefix(4) == Data([0x49, 0x49, 0x2A, 0]) { little = true }
        else if data.prefix(4) == Data([0x4D, 0x4D, 0, 0x2A]) { little = false }
        else { return nil }
        func integer(_ offset: Int, _ width: Int) -> Int? {
            guard offset >= 0, offset <= data.count, width <= data.count - offset else { return nil }
            return (0..<width).reduce(0) { result, index in
                let shift = (little ? index : width - 1 - index) * 8
                return result | (Int(data[data.startIndex + offset + index]) << shift)
            }
        }
        guard let ifd = integer(4, 4), let tagCount = integer(ifd, 2), tagCount <= 4096,
              ifd <= data.count - 2, tagCount <= (data.count - ifd - 2) / 12 else { return nil }
        var tags: [Int: [Int]] = [:]
        for index in 0..<tagCount {
            let entry = ifd + 2 + index * 12
            guard let tag = integer(entry, 2), let type = integer(entry + 2, 2),
                  let count = integer(entry + 4, 4), let pointer = integer(entry + 8, 4) else { return nil }
            guard [256, 257, 258, 259, 262, 273, 274, 277, 278, 279, 284, 320, 338].contains(tag) else { continue }
            guard tags[tag] == nil, [1, 3, 4].contains(type), count > 0, count <= 8192 else { return nil }
            let width = type == 3 ? 2 : (type == 4 ? 4 : 1)
            let start = count * width <= 4 ? entry + 8 : pointer
            guard start <= data.count, count * width <= data.count - start else { return nil }
            tags[tag] = (0..<count).compactMap { integer(start + $0 * width, width) }
        }
        guard tags[262] == [3], tags[277] == [2], tags[259] == [1],
              (tags[284] ?? [1]) == [1], tags[258] == [8] || tags[258] == [8, 8],
              let alpha = tags[338]?.first, [1, 2].contains(alpha),
              let width = tags[256]?.first, let height = tags[257]?.first,
              width > 0, height > 0, width <= 32_000_000, height <= 32_000_000 / width,
              let palette = tags[320], palette.count == 768,
              let offsets = tags[273], let counts = tags[279], offsets.count == counts.count else { return nil }
        let rowsPerStrip = tags[278]?.first ?? height
        guard rowsPerStrip > 0, rowsPerStrip <= Int(UInt32.max),
              offsets.count == (height + rowsPerStrip - 1) / rowsPerStrip else { return nil }
        var pixels = Data(count: width * height * 4)
        var destinationIndex = 0
        for strip in offsets.indices {
            let rows = min(rowsPerStrip, height - strip * rowsPerStrip)
            let required = width * rows * 2
            guard offsets[strip] <= data.count, required <= counts[strip], counts[strip] <= data.count - offsets[strip] else { return nil }
            for sample in stride(from: offsets[strip], to: offsets[strip] + required, by: 2) {
                let colorIndex = Int(data[data.startIndex + sample])
                let opacity = Int(data[data.startIndex + sample + 1])
                for component in 0..<3 {
                    let color = palette[component * 256 + colorIndex] / 257
                    pixels[destinationIndex + component] = UInt8(alpha == 2 ? (color * opacity + 127) / 255 : min(color, opacity))
                }
                pixels[destinationIndex + 3] = UInt8(opacity)
                destinationIndex += 4
            }
        }
        guard let provider = CGDataProvider(data: pixels as CFData),
              let image = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
                                  space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                                  provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else { return nil }
        let normalized = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(normalized, "public.tiff" as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, image, [kCGImagePropertyOrientation: tags[274]?.first ?? 1] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return normalized as Data
    }
}

private final class SVGInspector: NSObject, XMLParserDelegate {
    private var rejected = false
    private var depth = 0
    private var rootIsSVG = false
    private var styleDepth: Int?
    private var styleText = ""

    static func validatedData(_ data: Data) throws -> Data {
        // Common SVG exporters include the W3C declaration even for entirely
        // self-contained graphics. Remove recognized declarations before either
        // parser sees them; no external DTD is loaded and no entities are expanded.
        guard var text = String(data: data, encoding: .utf8),
              text.range(of: "<!\\s*ENTITY", options: [.regularExpression, .caseInsensitive]) == nil else {
            throw VectorRenderError.unsafeSVG
        }
        if text.range(of: "<!\\s*DOCTYPE", options: [.regularExpression, .caseInsensitive]) != nil {
            let declarations = [
                ("-//W3C//DTD SVG 1.0//EN", "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd"),
                ("-//W3C//DTD SVG 1.1//EN", "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd"),
                ("-//W3C//DTD SVG 1.1 Basic//EN", "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11-basic.dtd"),
                ("-//W3C//DTD SVG 1.1 Tiny//EN", "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11-tiny.dtd")
            ]
            let pattern = #"<!DOCTYPE\s+svg\s+PUBLIC\s+(["'])([^"']+)\1\s+(["'])([^"']+)\3\s*>"#
            let regex = try NSRegularExpression(pattern: pattern)
            let ns = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
            guard matches.count == 1, let match = matches.first else { throw VectorRenderError.unsafeSVG }
            let publicID = ns.substring(with: match.range(at: 2))
            let systemID = ns.substring(with: match.range(at: 4))
            guard declarations.contains(where: { publicID == $0.0 && (systemID == $0.1 || systemID == $0.1.replacingOccurrences(of: "http://", with: "https://")) }) else {
                throw VectorRenderError.unsafeSVG
            }
            text = ns.replacingCharacters(in: match.range, with: "")
            guard text.range(of: "<!\\s*DOCTYPE", options: [.regularExpression, .caseInsensitive]) == nil else { throw VectorRenderError.unsafeSVG }
        }
        let safeData = Data(text.utf8)
        let inspector = SVGInspector()
        let parser = XMLParser(data: safeData)
        parser.shouldResolveExternalEntities = false
        parser.externalEntityResolvingPolicy = .never
        parser.delegate = inspector
        let parsed = parser.parse()
        guard !inspector.rejected else { throw VectorRenderError.unsafeSVG }
        guard parsed, inspector.rootIsSVG else { throw VectorRenderError.invalidDocument }
        return safeData
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String]) {
        depth += 1
        let name = localName(elementName)
        if depth == 1 { rootIsSVG = name == "svg" }
        if name.hasPrefix("animate") || ["script", "handler", "foreignobject", "iframe", "object", "embed", "set"].contains(name) {
            reject(parser); return
        }
        if name == "style" { styleDepth = depth; styleText = "" }
        for (key, value) in attributeDict {
            let attribute = localName(key)
            if attribute.hasPrefix("on") || attribute == "base" { reject(parser); return }
            if ["href", "src"].contains(attribute), !safeReference(value) { reject(parser); return }
            if !safeCSS(value) { reject(parser); return }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if styleDepth != nil { styleText += string }
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        if styleDepth != nil {
            guard let text = String(data: CDATABlock, encoding: .utf8) else { reject(parser); return }
            styleText += text
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if styleDepth == depth {
            if !safeCSS(styleText) { reject(parser) }
            styleDepth = nil; styleText = ""
        }
        depth -= 1
    }

    func parser(_ parser: XMLParser, foundProcessingInstructionWithTarget target: String, data: String?) {
        reject(parser) // Includes external xml-stylesheet instructions.
    }

    private func localName(_ name: String) -> String { String(name.split(separator: ":").last ?? "").lowercased() }
    private func reject(_ parser: XMLParser) { rejected = true; parser.abortParsing() }

    private func safeCSS(_ text: String) -> Bool {
        let css = text.replacingOccurrences(of: "/\\*[\\s\\S]*?\\*/", with: "", options: .regularExpression)
        guard !css.contains("\\"), css.range(of: "@import", options: .caseInsensitive) == nil else { return false }
        // CSS image()/image-set() can express URL strings without url(...).
        // These are unnecessary for a static SVG preview and are refused.
        guard css.range(of: "(?:image-set|image)\\s*\\(", options: [.regularExpression, .caseInsensitive]) == nil else { return false }
        guard let regex = try? NSRegularExpression(pattern: "url\\s*\\(\\s*([^)]*)\\)", options: .caseInsensitive) else { return false }
        let ns = css as NSString
        for match in regex.matches(in: css, range: NSRange(location: 0, length: ns.length)) {
            let reference = ns.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            if !safeReference(reference) { return false }
        }
        return true
    }

    private func safeReference(_ text: String) -> Bool {
        let reference = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if reference.hasPrefix("#") { return true }
        guard let comma = reference.firstIndex(of: ",") else { return false }
        let header = String(reference[..<comma]).lowercased()
        let allowed = ["data:image/png;base64", "data:image/jpeg;base64", "data:image/jpg;base64", "data:image/gif;base64",
                       "data:image/webp;base64", "data:image/bmp;base64", "data:image/tiff;base64", "data:image/heic;base64"]
        guard allowed.contains(header),
              let data = Data(base64Encoded: String(reference[reference.index(after: comma)...]), options: .ignoreUnknownCharacters),
              let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
              let type = CGImageSourceGetType(source) as String? else { return false }
        // Validate the data rather than trusting a forged image/png MIME label
        // hiding another SVG with its own external references.
        return ["public.png", "public.jpeg", "com.compuserve.gif", "org.webmproject.webp", "com.microsoft.bmp", "public.tiff", "public.heic"].contains(type)
    }
}
