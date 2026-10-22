import AppKit
import AVFoundation
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct ImageItem {
    let url: URL
    var name: String { url.lastPathComponent }
    var isVideo: Bool { ImageLibrary.isVideo(url) }
    var isAudio: Bool { MediaFormats.isAudio(url) }
    var isTimeBased: Bool { isVideo || isAudio }
    var isVector: Bool { MediaFormats.isVector(url) }
}

enum ImageSort: String, CaseIterable {
    case name
    case modified
}

enum ImageLoadError: LocalizedError {
    case noImages
    case unreadable(URL)
    case invalidImage(URL)
    case decodeFailed(URL)

    var errorDescription: String? {
        switch self {
        case .noImages:
            return L10n.tr("此位置没有可查看的图片、矢量文件、视频或音频。")
        case .unreadable(let url):
            return L10n.format("无法读取“%@”。请确认文件仍然存在，并且具有访问权限。", url.lastPathComponent)
        case .invalidImage(let url):
            return L10n.format("“%@”不是系统能够解码的有效图片。", url.lastPathComponent)
        case .decodeFailed(let url):
            return L10n.format("无法解码“%@”，文件可能已损坏。", url.lastPathComponent)
        }
    }
}

enum ImageLibrary {
    private static let sourceTypes = Set(CGImageSourceCopyTypeIdentifiers() as! [String])
    // Keep common formats usable even when Launch Services cannot resolve UTIs
    // (for example, a command-line test process or a newly installed system).
    private static let knownExtensions: [String: String] = [
        "jpg": "public.jpeg", "jpeg": "public.jpeg", "jpe": "public.jpeg",
        "png": "public.png", "apng": "public.png", "gif": "com.compuserve.gif",
        "tif": "public.tiff", "tiff": "public.tiff", "bmp": "com.microsoft.bmp",
        "heic": "public.heic", "heif": "public.heif", "heics": "public.heics",
        "webp": "org.webmproject.webp", "avif": "public.avif", "jxl": "public.jpeg-xl",
        "jp2": "public.jpeg-2000", "j2k": "public.jpeg-2000",
        "ico": "com.microsoft.ico", "cur": "com.microsoft.cur", "icns": "com.apple.icns",
        "psd": "com.adobe.photoshop-image", "psb": "com.adobe.photoshop-image", "tga": "com.truevision.tga-image",
        "exr": "com.ilm.openexr-image", "hdr": "public.radiance",
        "pbm": "public.pbm", "pgm": "public.pbm", "ppm": "public.pbm",
        "dng": "com.adobe.raw-image", "cr2": "com.canon.cr2-raw-image", "cr3": "com.canon.cr3-raw-image",
        "nef": "com.nikon.raw-image", "nrw": "com.nikon.nrw-raw-image",
        "arw": "com.sony.arw-raw-image", "sr2": "com.sony.sr2-raw-image",
        "orf": "com.olympus.raw-image", "raf": "com.fuji.raw-image", "rw2": "com.panasonic.rw2-raw-image",
        "pef": "com.pentax.raw-image", "srw": "com.samsung.raw-image"
    ]

    static func isVideo(_ url: URL) -> Bool { MediaFormats.isVideo(url) }

    static func isSupported(_ url: URL) -> Bool {
        guard url.isFileURL else { return false }
        if isVideo(url) || MediaFormats.isAudio(url) || MediaFormats.isVector(url) { return true }
        if let identifier = knownExtensions[url.pathExtension.lowercased()] { return sourceTypes.contains(identifier) }
        guard let type = UTType(filenameExtension: url.pathExtension) else { return false }
        return sourceTypes.contains(type.identifier)
            || sourceTypes.contains(where: { UTType($0).map { type.conforms(to: $0) } ?? false })
    }

    /// Opening one media file selects it while making sibling images/videos navigable.
    /// Folders are deliberately scanned one level deep; originals are never modified.
    static func collect(from urls: [URL], sort: ImageSort = .name) throws -> (items: [ImageItem], selectedIndex: Int) {
        let fileManager = FileManager.default
        let inputs = urls.filter(\.isFileURL).map { $0.standardizedFileURL.resolvingSymlinksInPath() }
        let keys: Set<URLResourceKey> = [.isDirectoryKey, .isRegularFileKey, .contentModificationDateKey]
        var selectedURL: URL?
        var candidates: [URL] = []

        func images(in directory: URL) throws -> [URL] {
            try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: Array(keys), options: [.skipsHiddenFiles])
                .filter { url in
                    guard isSupported(url), let values = try? url.resourceValues(forKeys: keys) else { return false }
                    return values.isRegularFile == true
                }
        }

        for url in inputs {
            guard let values = try? url.resourceValues(forKeys: keys) else { throw ImageLoadError.unreadable(url) }
            if values.isDirectory == true {
                candidates.append(contentsOf: try images(in: url))
            } else if values.isRegularFile == true && isSupported(url) {
                if selectedURL == nil { selectedURL = url }
                if inputs.count == 1 {
                    // A readable file can still be opened when its enclosing directory
                    // cannot be enumerated (for example, a restricted network share).
                    candidates.append(contentsOf: (try? images(in: url.deletingLastPathComponent())) ?? [])
                }
                candidates.append(url)
            }
        }

        var seen = Set<String>()
        let unique = candidates.map { $0.standardizedFileURL.resolvingSymlinksInPath() }
            .filter { seen.insert($0.path).inserted }
        let dates: [String: Date] = sort == .modified ? Dictionary(uniqueKeysWithValues: unique.map {
            ($0.path, (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast)
        }) : [:]
        let ordered = unique.sorted { lhs, rhs in
            if sort == .modified, dates[lhs.path] != dates[rhs.path] {
                return dates[lhs.path, default: .distantPast] > dates[rhs.path, default: .distantPast]
            }
            let result = lhs.lastPathComponent.localizedStandardCompare(rhs.lastPathComponent)
            return result == .orderedSame ? lhs.path < rhs.path : result == .orderedAscending
        }
        guard !ordered.isEmpty else { throw ImageLoadError.noImages }
        return (ordered.map { ImageItem(url: $0) }, ordered.firstIndex(where: { $0 == selectedURL }) ?? 0)
    }
}

final class LoadedImage {
    let image: CGImage
    let pixelSize: CGSize
    let metadata: [(String, String)]
    let frameCount: Int
    let isVectorPreview: Bool
    var previewPixelSize: CGSize { CGSize(width: image.width, height: image.height) }
    var isDownsampledPreview: Bool {
        !isVectorPreview && (CGFloat(image.width) < pixelSize.width || CGFloat(image.height) < pixelSize.height)
    }

    private let source: CGImageSource?
    private let url: URL
    private let previewMaximumDimension: Int
    private let frameLock = NSLock()
    private var frames: [Int: CGImage] = [:]
    private var frameOrder: [Int] = []
    private var frameBytes = 0
    private let frameBudget = 64 * 1_024 * 1_024
    private var durations: [Int: TimeInterval] = [:]
    private var durationOrder: [Int] = []

    fileprivate init(url: URL, isCancelled: () -> Bool = { false }) throws {
        self.url = url
        guard FileManager.default.isReadableFile(atPath: url.path) else { throw ImageLoadError.unreadable(url) }
        if PhotoshopImage.isPhotoshop(url) {
            let header = try PhotoshopImage.inspect(url: url, isCancelled: isCancelled)
            // PSB's layer section can dwarf its flattened image. Our header has
            // the required geometry, so avoid asking ImageIO to scan it again.
            var properties: [String: Any] = [:]
            if !header.isPSB,
               let nativeSource = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary) {
                properties = CGImageSourceCopyPropertiesAtIndex(nativeSource, 0, nil) as? [String: Any] ?? [:]
            }
            properties[kCGImagePropertyPixelWidth as String] = header.width
            properties[kCGImagePropertyPixelHeight as String] = header.height
            properties[kCGImagePropertyDepth as String] = header.depth
            previewMaximumDimension = Self.previewDimension(width: header.width, height: header.height, properties: properties)
            let rendered = try PhotoshopImage.render(url: url, maxPixelDimension: previewMaximumDimension,
                                                     header: header, isCancelled: isCancelled)
            if properties[kCGImagePropertyProfileName as String] == nil,
               let colorSpace = rendered.image.colorSpace,
               let profileName = NSColorSpace(cgColorSpace: colorSpace)?.localizedName {
                properties[kCGImagePropertyProfileName as String] = profileName
            }
            image = rendered.image; pixelSize = header.pixelSize; source = nil; frameCount = 1; isVectorPreview = false
            var rows = Self.makeMetadata(url: url, properties: properties, image: rendered.image,
                                         originalSize: pixelSize, frameCount: 1, type: "com.adobe.photoshop-image")
            rows.removeAll { $0.0 == "格式" }
            rows.insert(("格式", header.isPSB ? "Photoshop PSB" : "Photoshop PSD"), at: 1)
            metadata = rows
            return
        }
        if MediaFormats.isVector(url) {
            let rendered = try VectorRenderer.render(url: url)
            image = rendered.image
            pixelSize = CGSize(width: rendered.image.width, height: rendered.image.height)
            source = nil
            frameCount = 1
            isVectorPreview = true
            previewMaximumDimension = max(rendered.image.width, rendered.image.height)
            var rows = [("文件名", url.lastPathComponent), ("格式", rendered.format),
                        ("原始画布", String(format: "%.0f × %.0f", rendered.originalSize.width, rendered.originalSize.height)),
                        ("预览", "\(rendered.image.width) × \(rendered.image.height) 像素（矢量渲染）")]
            if rendered.pageCount > 1 { rows.append(("页面", "第 1 页，共 \(rendered.pageCount) 页")) }
            if let bytes = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                rows.append(("文件大小", ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)))
            }
            rows.append(("位置", url.deletingLastPathComponent().path))
            metadata = rows
            return
        }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary),
              CGImageSourceGetCount(source) > 0 else { throw ImageLoadError.invalidImage(url) }
        self.source = source
        let count = CGImageSourceGetCount(source)
        let properties = (CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any]) ?? [:]
        let dimensions = try Self.dimensions(properties, url: url)
        previewMaximumDimension = Self.previewDimension(width: dimensions.width, height: dimensions.height, properties: properties)
        guard let first = Self.decode(source: source, index: 0, maxDimension: previewMaximumDimension) else {
            throw ImageLoadError.decodeFailed(url)
        }
        image = first
        let orientation = (properties[kCGImagePropertyOrientation as String] as? NSNumber)?.intValue ?? 1
        pixelSize = (5...8).contains(orientation)
            ? CGSize(width: dimensions.height, height: dimensions.width)
            : CGSize(width: dimensions.width, height: dimensions.height)
        isVectorPreview = false
        // Multiple TIFF/ICO representations are not animation frames.
        let type = CGImageSourceGetType(source) as String? ?? ""
        let animated = type == UTType.gif.identifier || type == UTType.png.identifier || type == "public.heics" || type == "org.webmproject.webp"
        frameCount = animated ? count : 1
        metadata = Self.makeMetadata(url: url, properties: properties, image: first, originalSize: pixelSize, frameCount: frameCount, type: type)
    }

    func frame(at index: Int) -> CGImage? {
        guard index >= 0 && index < frameCount else { return nil }
        if index == 0 { return image }
        guard let source else { return nil }
        frameLock.lock()
        defer { frameLock.unlock() }
        if let cached = frames[index] {
            frameOrder.removeAll { $0 == index }
            frameOrder.append(index)
            return cached
        }
        let properties = (CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [String: Any]) ?? [:]
        guard (try? Self.dimensions(properties, url: url)) != nil,
              let decoded = Self.decode(source: source, index: index, maxDimension: previewMaximumDimension),
              decoded.width == image.width, decoded.height == image.height else { return nil }
        let cost = decoded.bytesPerRow * decoded.height
        if cost <= frameBudget {
            while frameBytes + cost > frameBudget || frameOrder.count >= 3 {
                guard let first = frameOrder.first else { break }
                frameOrder.removeFirst()
                if let removed = frames.removeValue(forKey: first) { frameBytes -= removed.bytesPerRow * removed.height }
            }
            frames[index] = decoded
            frameOrder.append(index)
            frameBytes += cost
        }
        return decoded
    }

    func frameDuration(at index: Int) -> TimeInterval {
        guard index >= 0 && index < frameCount, let source else { return 0.1 }
        frameLock.lock()
        defer { frameLock.unlock() }
        if let duration = durations[index] { return duration }
        let frameProperties = (CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [String: Any]) ?? [:]
        let animation = (frameProperties[kCGImagePropertyGIFDictionary as String] as? [String: Any])
            ?? (frameProperties[kCGImagePropertyPNGDictionary as String] as? [String: Any])
            ?? (frameProperties["{WebP}"] as? [String: Any]) ?? [:]
        let seconds = (animation["UnclampedDelayTime"] as? NSNumber)?.doubleValue
            ?? (animation["DelayTime"] as? NSNumber)?.doubleValue ?? 0.1
        let duration = seconds.isFinite && seconds >= 0.011 ? seconds : 0.1
        // Avoid scanning or allocating timing records for every frame up front.
        // Very long animations have the same bounded metadata footprint.
        if durationOrder.count >= 128 { durations.removeValue(forKey: durationOrder.removeFirst()) }
        durations[index] = duration
        durationOrder.append(index)
        return duration
    }

    fileprivate var memoryCost: Int { image.bytesPerRow * image.height }

    private static func dimensions(_ properties: [String: Any], url: URL) throws -> (width: Int, height: Int) {
        guard let width = (properties[kCGImagePropertyPixelWidth as String] as? NSNumber)?.doubleValue,
              let height = (properties[kCGImagePropertyPixelHeight as String] as? NSNumber)?.doubleValue,
              width.isFinite, height.isFinite, width > 0, height > 0,
              width < Double(Int.max), height < Double(Int.max),
              width.rounded(.down) == width, height.rounded(.down) == height else { throw ImageLoadError.invalidImage(url) }
        return (Int(width), Int(height))
    }

    /// Limit decoded working pixels, not the accepted source dimensions. The
    /// original dimensions remain available for geometry and metadata.
    private static func previewDimension(width: Int, height: Int, properties: [String: Any]) -> Int {
        let depth = (properties[kCGImagePropertyDepth as String] as? NSNumber)?.intValue ?? 8
        let bytesPerPixel = max(4, min(16, ((max(1, min(32, depth)) + 7) / 8) * 4))
        let bytes = max(16 * 1_024 * 1_024, min(128 * 1_024 * 1_024, Int(ProcessInfo.processInfo.physicalMemory / 64)))
        let maximumPixels = min(32_000_000.0, Double(bytes / bytesPerPixel))
        let longest = Double(max(width, height))
        let scale = min(1, 8192 / longest, sqrt(maximumPixels / (Double(width) * Double(height))))
        return max(1, Int(floor(longest * scale)))
    }

    private static func decode(source: CGImageSource, index: Int, maxDimension: Int) -> CGImage? {
        CGImageSourceCreateThumbnailAtIndex(source, index, [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension,
            kCGImageSourceShouldAllowFloat: false,
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary)
    }

    private static func makeMetadata(url: URL, properties: [String: Any], image: CGImage, originalSize: CGSize, frameCount: Int, type: String) -> [(String, String)] {
        var rows: [(String, String)] = [("文件名", url.lastPathComponent), ("尺寸", String(format: "%.0f × %.0f 像素", originalSize.width, originalSize.height))]
        if CGFloat(image.width) < originalSize.width || CGFloat(image.height) < originalSize.height {
            rows.append(("大图预览", "\(image.width) × \(image.height) 像素；缩放按原尺寸计算，预览细节有限"))
        }
        if let description = UTType(type)?.localizedDescription { rows.append(("格式", description)) }
        if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
            rows.append(("文件大小", ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)))
        }
        let tiff = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any] ?? [:]
        let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] ?? [:]
        let camera = [tiff[kCGImagePropertyTIFFMake as String], tiff[kCGImagePropertyTIFFModel as String]].compactMap { $0 as? String }.joined(separator: " ")
        if !camera.isEmpty { rows.append(("相机", camera)) }
        if let date = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String { rows.append(("拍摄时间", date)) }
        if let fNumber = exif[kCGImagePropertyExifFNumber as String] as? NSNumber { rows.append(("光圈", "f/\(fNumber.stringValue)")) }
        if let exposure = (exif[kCGImagePropertyExifExposureTime as String] as? NSNumber)?.doubleValue, exposure > 0 {
            rows.append(("快门", exposure < 1 ? "1/\(Int((1 / exposure).rounded())) 秒" : "\(exposure) 秒"))
        }
        if let focal = exif[kCGImagePropertyExifFocalLength as String] as? NSNumber { rows.append(("焦距", "\(focal.stringValue) mm")) }
        if let iso = (exif[kCGImagePropertyExifISOSpeedRatings as String] as? [NSNumber])?.first { rows.append(("ISO", iso.stringValue)) }
        if let profile = properties[kCGImagePropertyProfileName as String] as? String { rows.append(("色彩配置", profile)) }
        if frameCount > 1 { rows.append(("动画帧数", "\(frameCount)")) }
        rows.append(("位置", url.deletingLastPathComponent().path))
        return rows
    }
}

final class ImageLoader {
    private let decodeQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "LumaView.FullImageDecode"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        return queue
    }()
    private let thumbnailQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "LumaView.ThumbnailDecode"
        queue.maxConcurrentOperationCount = 2
        queue.qualityOfService = .utility
        return queue
    }()
    private let lock = NSLock()
    private var generation: UInt = 0
    private var images: [String: LoadedImage] = [:]
    private var imageOrder: [String] = []
    private var imageBytes = 0
    private var videoDurations: [String: Double] = [:]
    private var videoDurationOrder: [String] = []
    private let imageBudget = 192 * 1_024 * 1_024
    private let thumbnails: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 256
        cache.totalCostLimit = 32 * 1_024 * 1_024
        return cache
    }()

    func load(_ url: URL, completion: @escaping (Result<LoadedImage, Error>) -> Void) {
        let token = currentGeneration()
        let key = cacheKey(url)
        if let image = cachedImage(key) {
            DispatchQueue.main.async { [weak self] in
                guard self?.currentGeneration() == token else { return }
                completion(.success(image))
            }
            return
        }
        let operation = BlockOperation()
        operation.addExecutionBlock { [weak self, weak operation] in
            guard let self = self, operation?.isCancelled == false else { return }
            let result = Result { try LoadedImage(url: url, isCancelled: {
                operation?.isCancelled != false || self.currentGeneration() != token
            }) }
            guard operation?.isCancelled == false, self.currentGeneration() == token else { return }
            if case .success(let image) = result { self.store(image, key: key) }
            DispatchQueue.main.async { [weak self] in
                guard self?.currentGeneration() == token else { return }
                completion(result)
            }
        }
        operation.queuePriority = .veryHigh
        decodeQueue.addOperation(operation)
    }

    @discardableResult
    func thumbnail(_ url: URL, completion: @escaping (NSImage?) -> Void) -> ThumbnailRequest {
        let request = ThumbnailRequest()
        let key = cacheKey(url) as NSString
        if let image = thumbnails.object(forKey: key) {
            DispatchQueue.main.async { request.finish { completion(image) } }
            return request
        }
        // Cache insertion, duration publication and completion happen together
        // on main, only while this individual request is still active.
        let finish: (NSImage?, Int, Double?) -> Void = { [weak self] image, cost, duration in
            DispatchQueue.main.async {
                guard let self else { return }
                request.finish {
                    if let image { self.thumbnails.setObject(image, forKey: key, cost: cost) }
                    if let duration, duration.isFinite, duration > 0 {
                        self.storeVideoDuration(duration, key: key as String)
                    }
                    completion(image)
                }
            }
        }
        let operation = BlockOperation()
        request.onCancel { [weak operation] in operation?.cancel() }
        operation.addExecutionBlock { [weak self, weak operation] in
            guard let self, operation?.isCancelled == false, !request.isCancelled else { return }
            autoreleasepool {
                if MediaFormats.isAudio(url) {
                    let finishAudio: (Double?) -> Void = { duration in
                        guard !request.isCancelled else { return }
                        DispatchQueue.main.async {
                            guard !request.isCancelled else { return }
                            let icon = NSImage(systemSymbolName: "music.note", accessibilityDescription: nil)?
                                .withSymbolConfiguration(NSImage.SymbolConfiguration(paletteColors: [.systemOrange]))
                            finish(icon, 1024, duration)
                        }
                    }
                    if let duration = self.makeAudioDuration(url, request: request) { finishAudio(duration) }
                    else if !request.isCancelled {
                        let job = CompatibilityMedia.thumbnail(url: url) { _, duration in finishAudio(duration) }
                        request.onCancel { job.cancel() }
                    }
                    return
                }
                if ImageLibrary.isVideo(url) {
                    let nativeContainer = ["mp4", "mov", "m4v", "qt"].contains(url.pathExtension.lowercased())
                    if nativeContainer, let decoded = self.makeVideoThumbnail(url, request: request) {
                        let image = NSImage(cgImage: decoded.image, size: NSSize(width: decoded.image.width, height: decoded.image.height))
                        finish(image, decoded.image.bytesPerRow * decoded.image.height, decoded.duration)
                    } else if !request.isCancelled {
                        let job = CompatibilityMedia.thumbnail(url: url) { image, duration in
                            finish(image, 256 * 256 * 4, duration)
                        }
                        request.onCancel { job.cancel() }
                    }
                    return
                }
                var result: CGImage?
                if MediaFormats.isVector(url) {
                    result = (try? VectorRenderer.render(url: url, maxPixelDimension: 256, request: request))?.image
                } else if PhotoshopImage.isPhotoshop(url) {
                    result = (try? PhotoshopImage.thumbnail(url: url, maxPixelDimension: 256,
                                                           isCancelled: { request.isCancelled }))?.image
                } else if let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary) {
                    result = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                        kCGImageSourceCreateThumbnailFromImageAlways: true,
                        kCGImageSourceCreateThumbnailWithTransform: true,
                        kCGImageSourceThumbnailMaxPixelSize: 256,
                        kCGImageSourceShouldCacheImmediately: true
                    ] as CFDictionary)
                }
                guard !request.isCancelled else { return }
                if let result {
                    finish(NSImage(cgImage: result, size: NSSize(width: result.width, height: result.height)),
                           result.bytesPerRow * result.height, nil)
                } else { finish(nil, 0, nil) }
            }
        }
        thumbnailQueue.addOperation(operation)
        return request
    }

    func prefetch(_ urls: [URL]) {
        let token = currentGeneration()
        for url in urls.filter({ !ImageLibrary.isVideo($0) && !MediaFormats.isAudio($0) && !MediaFormats.isVector($0) }).prefix(2) {
            let key = cacheKey(url)
            guard cachedImage(key) == nil else { continue }
            let operation = BlockOperation()
            operation.queuePriority = .veryLow
            operation.addExecutionBlock { [weak self, weak operation] in
                guard let self = self, operation?.isCancelled == false, self.currentGeneration() == token else { return }
                // Prefetch is optional: avoid allocating a second very large image
                // while the current full-resolution image is on screen.
                guard !PhotoshopImage.isPhotoshop(url),
                      let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
                      let width = properties[kCGImagePropertyPixelWidth as String] as? NSNumber,
                      let height = properties[kCGImagePropertyPixelHeight as String] as? NSNumber,
                      width.doubleValue * height.doubleValue <= 32_000_000,
                      let image = try? LoadedImage(url: url),
                      operation?.isCancelled == false, self.currentGeneration() == token else { return }
                self.store(image, key: key)
            }
            decodeQueue.addOperation(operation)
        }
    }

    /// Available before an audio/video thumbnail completion is delivered.
    func videoDuration(for url: URL) -> Double? {
        let key = cacheKey(url)
        lock.lock()
        defer { lock.unlock() }
        return videoDurations[key]
    }

    private func storeVideoDuration(_ duration: Double, key: String) {
        lock.lock()
        defer { lock.unlock() }
        videoDurationOrder.removeAll { $0 == key }
        while videoDurationOrder.count >= 256 { videoDurations.removeValue(forKey: videoDurationOrder.removeFirst()) }
        videoDurations[key] = duration
        videoDurationOrder.append(key)
    }

    /// Runs only on the bounded thumbnail worker queue; unsupported containers
    /// fall back to the bundled probe without producing a converted audio file.
    private func makeAudioDuration(_ url: URL, request: ThumbnailRequest) -> Double? {
        guard !request.isCancelled else { return nil }
        let asset = AVURLAsset(url: url)
        let finished = DispatchSemaphore(value: 0)
        final class ResultBox {
            private let lock = NSLock()
            private var value: Double?
            func set(_ duration: Double) { lock.lock(); value = duration; lock.unlock() }
            func get() -> Double? { lock.lock(); defer { lock.unlock() }; return value }
        }
        let box = ResultBox()
        let task = Task.detached(priority: .utility) {
            defer { finished.signal() }
            guard !Task.isCancelled else { return }
            if let duration = try? await asset.load(.duration).seconds, !Task.isCancelled, duration.isFinite, duration > 0 {
                box.set(duration)
            }
        }
        let cancellation = request.onCancel { task.cancel(); asset.cancelLoading(); finished.signal() }
        defer { request.removeCancellationHandler(cancellation) }
        guard finished.wait(timeout: .now() + 10) == .success else {
            task.cancel(); asset.cancelLoading(); return nil
        }
        return request.isCancelled ? nil : box.get()
    }

    /// Called only on the bounded thumbnail worker queue. Waiting here keeps
    /// at most two AVFoundation thumbnail jobs alive, without blocking AppKit.
    private func makeVideoThumbnail(_ url: URL, request: ThumbnailRequest) -> (image: CGImage, duration: Double)? {
        guard !request.isCancelled else { return nil }
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 256, height: 256)
        let finished = DispatchSemaphore(value: 0)
        final class ResultBox {
            private let lock = NSLock()
            private var value: (CGImage, Double)?
            func set(_ image: CGImage, _ duration: Double) { lock.lock(); value = (image, duration); lock.unlock() }
            func get() -> (CGImage, Double)? { lock.lock(); defer { lock.unlock() }; return value }
        }
        let box = ResultBox()
        let task = Task.detached(priority: .utility) {
            defer { finished.signal() }
            do {
                try Task.checkCancellation()
                let duration = try await asset.load(.duration).seconds
                try Task.checkCancellation()
                let seconds = duration.isFinite && duration > 0 ? min(1, duration * 0.1) : 0
                let generated = try await generator.image(at: CMTime(seconds: seconds, preferredTimescale: 600))
                try Task.checkCancellation()
                box.set(generated.image, duration)
            } catch { }
        }
        let cancellation = request.onCancel {
            task.cancel(); generator.cancelAllCGImageGeneration(); asset.cancelLoading(); finished.signal()
        }
        defer { request.removeCancellationHandler(cancellation) }
        guard finished.wait(timeout: .now() + 15) == .success else {
            task.cancel(); generator.cancelAllCGImageGeneration(); asset.cancelLoading()
            return nil
        }
        guard !request.isCancelled else { return nil }
        return box.get().map { (image: $0.0, duration: $0.1) }
    }

    /// Cancels full-size navigation/prefetch work; filmstrip thumbnails may finish.
    func cancelPending() {
        lock.lock()
        generation &+= 1
        lock.unlock()
        decodeQueue.cancelAllOperations()
    }

    private func currentGeneration() -> UInt {
        lock.lock()
        defer { lock.unlock() }
        return generation
    }

    private func cacheKey(_ url: URL) -> String {
        let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
        return "\(url.standardizedFileURL.path)|\(values?.contentModificationDate?.timeIntervalSince1970 ?? 0)|\(values?.fileSize ?? 0)"
    }

    private func cachedImage(_ key: String) -> LoadedImage? {
        lock.lock()
        defer { lock.unlock() }
        guard let image = images[key] else { return nil }
        imageOrder.removeAll { $0 == key }
        imageOrder.append(key)
        return image
    }

    private func store(_ image: LoadedImage, key: String) {
        guard image.memoryCost <= imageBudget else { return }
        lock.lock()
        defer { lock.unlock() }
        if let existing = images.removeValue(forKey: key) {
            imageBytes -= existing.memoryCost
            imageOrder.removeAll { $0 == key }
        }
        while imageBytes + image.memoryCost > imageBudget || imageOrder.count >= 3 {
            guard let first = imageOrder.first else { break }
            imageOrder.removeFirst()
            if let removed = images.removeValue(forKey: first) { imageBytes -= removed.memoryCost }
        }
        images[key] = image
        imageOrder.append(key)
        imageBytes += image.memoryCost
    }
}
