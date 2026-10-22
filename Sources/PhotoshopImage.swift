import Foundation
import ImageIO
import zlib

/// Reads the flattened composite, never Photoshop layers. PSB uses 64-bit
/// section lengths and 32-bit PackBits row lengths (Adobe file specification).
/// ImageIO handles native colors/ICC; its missing ZIP support is supplied here
/// with bounded rows and a sampled composite, not a full-document allocation.
enum PhotoshopImage {
    enum Failure: LocalizedError {
        case invalid, noComposite, unsupported, cancelled
        var errorDescription: String? {
            switch self {
            case .noComposite: return L10n.tr("此 Photoshop 文件没有兼容合成图。请启用“最大兼容性”后重新保存。")
            case .unsupported: return L10n.tr("此 Photoshop 文件的颜色模式暂不支持预览。")
            case .invalid: return L10n.tr("Photoshop 文件数据不完整或格式无效。")
            case .cancelled: return nil
            }
        }
    }
    struct Header {
        let version, channels, width, height, depth, mode, compression: Int
        let dataOffset, fileSize: UInt64
        let colorData: Data
        let resources: Data
        let embeddedThumbnail: Data?
        let hasMergedTransparency: Bool
        var pixelSize: CGSize { CGSize(width: width, height: height) }
        var rowBytes: Int { (width * depth + 7) / 8 }
        var isPSB: Bool { version == 2 }
        var colorChannels: Int {
            switch mode { case 3, 9: return 3; case 4: return 4; case 7: return channels; default: return 1 }
        }
    }
    struct Preview { let image: CGImage; let header: Header }
    static func isPhotoshop(_ url: URL) -> Bool { ["psd", "psb"].contains(url.pathExtension.lowercased()) }

    private final class Reader {
        let handle: FileHandle
        let size: UInt64
        var position: UInt64 = 0
        init(_ url: URL) throws {
            handle = try FileHandle(forReadingFrom: url)
            size = try handle.seekToEnd()
            try handle.seek(toOffset: 0)
        }
        deinit { try? handle.close() }
        func seek(_ offset: UInt64) throws {
            guard offset <= size else { throw Failure.invalid }
            try handle.seek(toOffset: offset); position = offset
        }
        func read(_ count: Int) throws -> Data {
            guard count >= 0, UInt64(count) <= size - position else { throw Failure.invalid }
            let data = try handle.read(upToCount: count) ?? Data()
            guard data.count == count else { throw Failure.invalid }
            position += UInt64(count); return data
        }
        func integer(_ count: Int) throws -> UInt64 {
            try read(count).reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
        }
        func skip(_ count: UInt64) throws {
            guard count <= size - position else { throw Failure.invalid }
            try seek(position + count)
        }
    }

    static func inspect(url: URL, isCancelled: () -> Bool = { false }) throws -> Header {
        let reader = try Reader(url)
        guard try reader.read(4) == Data("8BPS".utf8) else { throw Failure.invalid }
        let version = Int(try reader.integer(2))
        guard [1, 2].contains(version), try reader.read(6).allSatisfy({ $0 == 0 }) else { throw Failure.invalid }
        let channels = Int(try reader.integer(2)), height = Int(try reader.integer(4)), width = Int(try reader.integer(4))
        let depth = Int(try reader.integer(2)), mode = Int(try reader.integer(2))
        let limit = version == 2 ? 300_000 : 30_000
        guard (1...56).contains(channels), (1...limit).contains(width), (1...limit).contains(height),
              [1, 8, 16, 32].contains(depth), [0, 1, 2, 3, 4, 7, 8, 9].contains(mode) else { throw Failure.invalid }
        let colorsLength = try reader.integer(4)
        // Indexed palettes fit in 768 bytes; larger duotone tables stay native.
        let colors: Data
        if colorsLength <= 1_048_576 { colors = try reader.read(Int(colorsLength)) }
        else { try reader.skip(colorsLength); colors = Data() }
        let resourcesLength = try reader.integer(4)
        guard resourcesLength <= reader.size - reader.position else { throw Failure.invalid }
        let resourcesEnd = reader.position + resourcesLength
        var resources = Data()
        var embeddedThumbnail: Data?
        var resourceCount = 0
        while reader.position < resourcesEnd {
            if resourceCount % 64 == 0, isCancelled() { throw Failure.cancelled }
            resourceCount += 1
            guard resourceCount <= 100_000 else { throw Failure.invalid }
            guard resourcesEnd - reader.position >= 12 else { throw Failure.invalid }
            let signature = try reader.read(4), id = try reader.integer(2)
            guard signature == Data("8BIM".utf8) else { throw Failure.invalid }
            let nameLength = try reader.integer(1)
            try reader.skip(nameLength + ((nameLength + 1) % 2))
            guard reader.position + 4 <= resourcesEnd else { throw Failure.invalid }
            let length = try reader.integer(4)
            guard length <= resourcesEnd - reader.position,
                  length + (length % 2) <= resourcesEnd - reader.position else { throw Failure.invalid }
            // ICC is all that is needed to color-manage the sampled composite.
            if id == 1039, resources.isEmpty, length <= 4 * 1_024 * 1_024 {
                let profile = try reader.read(Int(length))
                resources.append(signature); resources.append(be(id, 2)); resources.append(contentsOf: [0, 0])
                resources.append(be(length, 4)); resources.append(profile)
                if length % 2 != 0 { resources.append(0) }
            } else if id == 1036, embeddedThumbnail == nil, (28...4 * 1_024 * 1_024).contains(length) {
                // Photoshop's saved RGB JPEG is enough for the filmstrip. Keep
                // its small header too, so dimensions and encoding can be checked.
                embeddedThumbnail = try reader.read(Int(length))
            } else if id == 1057, length >= 5 {
                _ = try reader.integer(4)
                guard try reader.integer(1) != 0 else { throw Failure.noComposite }
                try reader.skip(length - 5)
            } else { try reader.skip(length) }
            if length % 2 != 0 { try reader.skip(1) }
        }
        let layersLength = try reader.integer(version == 2 ? 8 : 4)
        let mergedTransparency = try readMergedTransparency(reader: reader, length: layersLength,
                                                            version: version, depth: depth, isCancelled: isCancelled)
        guard reader.size - reader.position >= 2 else { throw Failure.noComposite }
        let compression = Int(try reader.integer(2))
        guard (0...3).contains(compression) else { throw Failure.invalid }
        let header = Header(version: version, channels: channels, width: width, height: height, depth: depth,
                            mode: mode, compression: compression, dataOffset: reader.position,
                            fileSize: reader.size, colorData: colors, resources: resources,
                            embeddedThumbnail: embeddedThumbnail,
                            hasMergedTransparency: mergedTransparency)
        let remaining = reader.size - reader.position
        if compression == 0 {
            guard UInt64(header.rowBytes) * UInt64(height) * UInt64(channels) <= remaining else { throw Failure.noComposite }
        } else if compression == 1 {
            let countBytes = version == 2 ? 4 : 2
            let tableBytes = UInt64(height) * UInt64(channels) * UInt64(countBytes)
            guard tableBytes < remaining else { throw Failure.noComposite }
            var left = tableBytes, total: UInt64 = 0
            while left > 0 {
                if isCancelled() { throw Failure.cancelled }
                let bytes = try reader.read(Int(min(left, 65_536)))
                for start in stride(from: 0, to: bytes.count, by: countBytes) {
                    let count = bytes[start..<(start + countBytes)].reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
                    guard count <= remaining - tableBytes - total else { throw Failure.invalid }
                    total += count
                }
                left -= UInt64(bytes.count)
            }
        } else { guard remaining >= 6 else { throw Failure.noComposite } }
        return header
    }

    /// A saved selection/spot channel is not the document's transparency. Only
    /// explicit merged-transparency declarations give an extra plane that role.
    /// Skip layer bodies by checked length; no layer records or pixels are built.
    private static func readMergedTransparency(reader: Reader, length: UInt64, version: Int, depth: Int,
                                                isCancelled: () -> Bool) throws -> Bool {
        guard length <= reader.size - reader.position else { throw Failure.invalid }
        if length == 0 { return false }
        let end = reader.position + length, sizeBytes = version == 2 ? 8 : 4
        guard UInt64(sizeBytes) <= end - reader.position else { throw Failure.invalid }
        let layerBytes = try reader.integer(sizeBytes)
        guard layerBytes <= end - reader.position else { throw Failure.invalid }
        let layerEnd = reader.position + layerBytes
        var merged = false
        if layerBytes >= 2 {
            merged = Int16(bitPattern: UInt16(try reader.integer(2))) < 0
        }
        try reader.seek(layerEnd)
        if reader.position == end { return merged }
        guard end - reader.position >= 4 else { throw Failure.invalid }
        let maskBytes = try reader.integer(4)
        guard maskBytes <= end - reader.position else { throw Failure.invalid }
        try reader.skip(maskBytes)
        let wideKeys: Set<String> = ["LMsk", "Lr16", "Lr32", "Layr", "Mt16", "Mt32", "Mtrn", "Alph", "FMsk", "lnk2", "FEid", "FXid", "PxSD"]
        var blocks = 0, padding = 0
        while reader.position < end {
            if isCancelled() { throw Failure.cancelled }
            let first = try reader.read(1)[0]
            if first == 0 {
                padding += 1
                guard padding <= 3 else { throw Failure.invalid }
                continue
            }
            padding = 0; blocks += 1
            guard blocks <= 100_000, end - reader.position >= 11 else { throw Failure.invalid }
            var signature = Data([first]); signature.append(try reader.read(3))
            guard signature == Data("8BIM".utf8) || signature == Data("8B64".utf8) else { throw Failure.invalid }
            let key = String(data: try reader.read(4), encoding: .ascii) ?? ""
            let lengthBytes = signature == Data("8B64".utf8) || (version == 2 && wideKeys.contains(key)) ? 8 : 4
            guard UInt64(lengthBytes) <= end - reader.position else { throw Failure.invalid }
            let bytes = try reader.integer(lengthBytes)
            guard bytes <= end - reader.position else { throw Failure.invalid }
            let blockEnd = reader.position + bytes
            if bytes >= 2, key == "Layr" || (key == "Lr16" && depth == 16) || (key == "Lr32" && depth == 32) {
                let negative = Int16(bitPattern: UInt16(try reader.integer(2))) < 0
                merged = merged || negative
            }
            if key == "Mtrn" || (key == "Mt16" && depth == 16) || (key == "Mt32" && depth == 32) { merged = true }
            try reader.seek(blockEnd)
        }
        return merged
    }

    /// Use the saved preview only for the filmstrip. The main image always reads
    /// the composite, including its transparency and full available detail.
    static func thumbnail(url: URL, maxPixelDimension: Int = 256,
                          isCancelled: () -> Bool = { false }) throws -> Preview {
        let header = try inspect(url: url, isCancelled: isCancelled)
        guard !isCancelled() else { throw Failure.cancelled }
        if let resource = header.embeddedThumbnail,
           let image = embeddedImage(resource, header: header, dimension: maxPixelDimension) {
            guard !isCancelled() else { throw Failure.cancelled }
            return Preview(image: image, header: header)
        }
        return try render(url: url, maxPixelDimension: maxPixelDimension, header: header, isCancelled: isCancelled)
    }

    private static func embeddedImage(_ data: Data, header: Header, dimension: Int) -> CGImage? {
        guard data.count > 28 else { return nil }
        func number(_ offset: Int, _ count: Int = 4) -> Int {
            data[offset..<(offset + count)].reduce(0) { ($0 << 8) | Int($1) }
        }
        let width = number(4), height = number(8), rowBytes = number(12)
        // Resource 1036 uses RGB; legacy 1033 uses BGR and falls back to the
        // composite. Never trust claimed JPEG dimensions before decoding.
        guard number(0) == 1, (1...4096).contains(width), (1...4096).contains(height),
              number(24, 2) == 24, number(26, 2) == 1,
              rowBytes == ((width * 24 + 31) / 32) * 4,
              number(16) == rowBytes * height, number(20) == data.count - 28,
              abs(Double(width) - Double(height) * Double(header.width) / Double(header.height)) <= 2,
              let source = CGImageSourceCreateWithData(Data(data.dropFirst(28)) as CFData,
                  [kCGImageSourceShouldCache: false] as CFDictionary),
              CGImageSourceGetType(source) as String? == "public.jpeg",
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
              (properties[kCGImagePropertyPixelWidth as String] as? NSNumber)?.intValue == width,
              (properties[kCGImagePropertyPixelHeight as String] as? NSNumber)?.intValue == height else { return nil }
        return CGImageSourceCreateThumbnailAtIndex(source, 0, [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: min(max(1, dimension), max(width, height)),
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary)
    }

    static func render(url: URL, maxPixelDimension: Int = 8192, header inspectedHeader: Header? = nil,
                       isCancelled: () -> Bool = { false }) throws -> Preview {
        let header = try inspectedHeader ?? inspect(url: url, isCancelled: isCancelled)
        guard !isCancelled() else { throw Failure.cancelled }
        let dimension = min(8192, max(1, maxPixelDimension))
        let sourcePixels = Double(header.width) * Double(header.height)
        // ImageIO provides fast native Raw/1- and 8-bit RLE decoding. Its high-depth
        // PackBits path changes samples on some macOS versions; use our row
        // reader for that case and large composites to bound allocations.
        if header.compression == 0 || (header.compression == 1 && header.depth <= 8), sourcePixels <= 32_000_000,
           header.channels == header.colorChannels,
           sourcePixels * Double(header.channels * max(1, header.depth / 8)) <= 128 * 1_024 * 1_024,
           let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary),
           let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: dimension,
            kCGImageSourceShouldAllowFloat: false,
            kCGImageSourceShouldCacheImmediately: true
           ] as CFDictionary) {
            guard !isCancelled() else { throw Failure.cancelled }
            return Preview(image: image, header: header)
        }
        let image = try sampledComposite(url: url, header: header, dimension: dimension, isCancelled: isCancelled)
        return Preview(image: image, header: header)
    }

    private static func sampledComposite(url: URL, header h: Header, dimension: Int,
                                         isCancelled: () -> Bool) throws -> CGImage {
        guard [8, 16, 32].contains(h.depth), [1, 2, 3, 4, 8, 9].contains(h.mode) else { throw Failure.unsupported }
        let colors = h.colorChannels
        guard h.channels >= colors else { throw Failure.invalid }
        let channels = min(h.channels, colors + (h.hasMergedTransparency ? 1 : 0)), stride = h.depth / 8
        let maxPixels = min(32_000_000.0, Double(96 * 1_024 * 1_024 / (stride * channels)))
        let scale = min(1, Double(dimension) / Double(max(h.width, h.height)), sqrt(maxPixels / (Double(h.width) * Double(h.height))))
        let width = max(1, Int(Double(h.width) * scale)), height = max(1, Int(Double(h.height) * scale))
        let targetRow = width * stride
        var sampled = Data(count: channels * height * targetRow)
        let reader = try Reader(url); try reader.seek(h.dataOffset)
        let tableBytes = UInt64(h.height * h.channels * (h.version == 2 ? 4 : 2))
        var rleOffset = h.dataOffset + (h.compression == 1 ? tableBytes : 0)
        let inflater = h.compression >= 2 ? try Inflater(reader: reader) : nil
        var row = [UInt8](repeating: 0, count: h.rowBytes)
        for channel in 0..<channels {
            if isCancelled() { throw Failure.cancelled }
            var counts = Data()
            let countSize = h.version == 2 ? 4 : 2
            if h.compression == 1 {
                try reader.seek(h.dataOffset + UInt64(channel * h.height * countSize))
                counts = try reader.read(h.height * countSize)
                try reader.seek(rleOffset)
            }
            var targetY = 0
            for y in 0..<h.height {
                if y % 128 == 0, isCancelled() { throw Failure.cancelled }
                let wanted = targetY < height && y == min(h.height - 1, targetY * h.height / height)
                switch h.compression {
                case 0:
                    if wanted {
                        try reader.seek(h.dataOffset + UInt64((channel * h.height + y) * h.rowBytes))
                        row = Array(try reader.read(h.rowBytes))
                    }
                case 1:
                    var length: UInt64 = 0
                    for byte in counts[(y * countSize)..<((y + 1) * countSize)] { length = (length << 8) | UInt64(byte) }
                    guard length <= h.fileSize - reader.position else { throw Failure.invalid }
                    if wanted {
                        // PackBits can contain arbitrary no-op padding. Process
                        // it incrementally rather than allocating a claimed row.
                        row = try unpackRow(reader: reader, length: length, expected: h.rowBytes, isCancelled: isCancelled)
                    } else { try reader.skip(length) }
                    rleOffset = reader.position
                default:
                    try inflater!.read(into: &row)
                    if wanted && h.compression == 3 { undoPrediction(&row, width: h.width, depth: h.depth) }
                }
                if wanted {
                    let start = (channel * height + targetY) * targetRow
                    sampled.withUnsafeMutableBytes { (buffer: UnsafeMutableRawBufferPointer) in
                        for x in 0..<width {
                            let source = min(h.width - 1, x * h.width / width) * stride
                            for byte in 0..<stride { buffer[start + x * stride + byte] = row[source + byte] }
                        }
                    }
                    targetY += 1
                }
            }
        }
        // Complete the zlib stream to check its checksum and reject truncated or
        // excess output; extra Photoshop alpha/spot planes are consumed in rows.
        if let inflater {
            for _ in channels..<h.channels {
                for y in 0..<h.height {
                    if y % 128 == 0, isCancelled() { throw Failure.cancelled }
                    try inflater.read(into: &row)
                }
            }
            try inflater.finish()
        }
        let alphaMask = channels > colors ? try separateTransparency(&sampled, width: width, height: height,
            colors: colors, depth: h.depth, removeWhiteMatte: h.mode == 1 || h.mode == 3, isCancelled: isCancelled) : nil
        func decodeSamples(resources: Data) -> CGImage? {
            var data = Data("8BPS".utf8)
            data.append(be(1, 2)); data.append(Data(repeating: 0, count: 6)); data.append(be(UInt64(colors), 2))
            data.append(be(UInt64(height), 4)); data.append(be(UInt64(width), 4)); data.append(be(UInt64(h.depth), 2)); data.append(be(UInt64(h.mode), 2))
            data.append(be(UInt64(h.colorData.count), 4)); data.append(h.colorData)
            data.append(be(UInt64(resources.count), 4)); data.append(resources)
            data.append(contentsOf: [0, 0, 0, 0, 0, 0]); data.append(sampled.prefix(colors * height * targetRow))
            guard let source = CGImageSourceCreateWithData(data as CFData,
                [kCGImageSourceShouldCache: false] as CFDictionary) else { return nil }
            return CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: dimension,
                kCGImageSourceShouldAllowFloat: false,
                kCGImageSourceShouldCacheImmediately: true
            ] as CFDictionary)
        }
        var decoded = decodeSamples(resources: h.resources)
        if decoded == nil, h.resources.count >= 12 {
            guard !isCancelled() else { throw Failure.cancelled }
            // ImageIO rejects some small sampled PSDs when they include a valid
            // ICC block (the same block works in the full-size document). Decode
            // the sample planes independently, then restore their actual profile.
            // Do not silently discard a profile or assign it to a different model.
            let length = h.resources[8..<12].reduce(0) { ($0 << 8) | Int($1) }
            if length > 0, length <= h.resources.count - 12,
               let profile = CGColorSpace(iccData: Data(h.resources[12..<(12 + length)]) as CFData),
               let untagged = decodeSamples(resources: Data()),
               let space = untagged.colorSpace,
               profile.model == space.model, profile.numberOfComponents == space.numberOfComponents {
                decoded = untagged.copy(colorSpace: profile)
            }
        }
        guard !isCancelled() else { throw Failure.cancelled }
        guard let image = decoded else { throw Failure.unsupported }
        if let alphaMask {
            guard let provider = CGDataProvider(data: alphaMask as CFData),
                  let mask = CGImage(maskWidth: width, height: height, bitsPerComponent: 8, bitsPerPixel: 8,
                                     bytesPerRow: width, provider: provider, decode: nil, shouldInterpolate: true),
                  let transparent = image.masking(mask) else { throw Failure.unsupported }
            return transparent
        }
        return image
    }

    /// ImageIO inconsistently treats Photoshop's extra planes as alpha, and can
    /// discard high-depth grayscale transparency. Decode only base colors there;
    /// attach the explicitly declared composite alpha ourselves at display depth.
    private static func separateTransparency(_ data: inout Data, width: Int, height: Int, colors: Int,
                                               depth: Int, removeWhiteMatte: Bool,
                                               isCancelled: () -> Bool) throws -> Data {
        let pixels = width * height, stride = depth / 8, planeBytes = pixels * stride
        var inverseAlpha = Data(count: pixels)
        try data.withUnsafeMutableBytes { (samples: UnsafeMutableRawBufferPointer) in
            try inverseAlpha.withUnsafeMutableBytes { (mask: UnsafeMutableRawBufferPointer) in
                for pixel in 0..<pixels {
                    if pixel % 16_384 == 0, isCancelled() { throw Failure.cancelled }
                    let rawAlpha = sample(samples, at: colors * planeBytes + pixel * stride, depth: depth)
                    let alpha = rawAlpha.isFinite ? min(1, max(0, rawAlpha)) : 0
                    // Quartz image-mask samples are inverse alpha.
                    mask[pixel] = UInt8((255 * (1 - alpha)).rounded())
                    if removeWhiteMatte && alpha > 0 {
                        for color in 0..<colors {
                            let offset = color * planeBytes + pixel * stride
                            let matted = sample(samples, at: offset, depth: depth)
                            writeSample((matted + alpha - 1) / alpha, to: samples, at: offset, depth: depth)
                        }
                    }
                }
            }
        }
        return inverseAlpha
    }

    private static func sample(_ bytes: UnsafeMutableRawBufferPointer, at offset: Int, depth: Int) -> Double {
        if depth == 8 { return Double(bytes[offset]) / 255 }
        if depth == 16 { return Double(UInt16(bytes[offset]) << 8 | UInt16(bytes[offset + 1])) / 65535 }
        let bits = (0..<4).reduce(UInt32(0)) { ($0 << 8) | UInt32(bytes[offset + $1]) }
        return Double(Float(bitPattern: bits))
    }

    private static func writeSample(_ value: Double, to bytes: UnsafeMutableRawBufferPointer, at offset: Int, depth: Int) {
        let finite = value.isFinite ? value : 0
        if depth == 8 { bytes[offset] = UInt8((min(1, max(0, finite)) * 255).rounded()) }
        else if depth == 16 {
            let bits = UInt16((min(1, max(0, finite)) * 65535).rounded())
            bytes[offset] = UInt8(bits >> 8); bytes[offset + 1] = UInt8(bits & 255)
        } else {
            let bits = Float(finite).bitPattern
            for byte in 0..<4 { bytes[offset + byte] = UInt8((bits >> ((3 - byte) * 8)) & 255) }
        }
    }

    private static func unpackRow(reader: Reader, length: UInt64, expected: Int,
                                  isCancelled: () -> Bool) throws -> [UInt8] {
        let end = reader.position + length
        var result = [UInt8](repeating: 0, count: expected)
        var produced = 0, literalRemaining = 0, repeatCount = 0
        // Read bounded chunks, not a FileHandle syscall for every PackBits byte.
        // A packet may cross a chunk boundary; no-op padding still checks cancel
        // every 64 KiB, without allocating the file's claimed encoded row size.
        try result.withUnsafeMutableBufferPointer { target in
            while reader.position < end {
                if isCancelled() { throw Failure.cancelled }
                let chunk = try reader.read(Int(min(65_536, end - reader.position)))
                try chunk.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
                    let bytes = raw.bindMemory(to: UInt8.self)
                    var index = 0
                    while index < bytes.count {
                        if literalRemaining > 0 {
                            let count = min(literalRemaining, bytes.count - index)
                            target.baseAddress!.advanced(by: produced).update(from: bytes.baseAddress!.advanced(by: index), count: count)
                            index += count; produced += count; literalRemaining -= count
                        } else if repeatCount > 0 {
                            let byte = bytes[index]; index += 1
                            for offset in 0..<repeatCount { target[produced + offset] = byte }
                            produced += repeatCount; repeatCount = 0
                        } else {
                            let marker = Int(bytes[index]); index += 1
                            if marker <= 127 {
                                literalRemaining = marker + 1
                                guard literalRemaining <= expected - produced else { throw Failure.invalid }
                            } else if marker != 128 {
                                repeatCount = 257 - marker
                                guard repeatCount <= expected - produced else { throw Failure.invalid }
                            }
                        }
                    }
                }
            }
        }
        guard produced == expected, literalRemaining == 0, repeatCount == 0 else { throw Failure.invalid }
        return result
    }

    private static func undoPrediction(_ row: inout [UInt8], width: Int, depth: Int) {
        if depth == 16 {
            var prior = UInt16(row[0]) << 8 | UInt16(row[1])
            for x in 1..<width {
                let index = x * 2
                prior = prior &+ (UInt16(row[index]) << 8 | UInt16(row[index + 1]))
                row[index] = UInt8(prior >> 8); row[index + 1] = UInt8(prior & 255)
            }
        } else {
            for x in 1..<row.count { row[x] = row[x] &+ row[x - 1] }
            if depth == 32 {
                let planes = row
                for x in 0..<width { for byte in 0..<4 { row[x * 4 + byte] = planes[byte * width + x] } }
            }
        }
    }
    private static func be(_ value: UInt64, _ bytes: Int) -> Data {
        Data((0..<bytes).reversed().map { UInt8((value >> ($0 * 8)) & 255) })
    }

    private final class Inflater {
        let reader: Reader
        var stream = z_stream()
        var input = [UInt8](), offset = 0
        var ended = false
        init(reader: Reader) throws {
            self.reader = reader
            guard inflateInit_(&stream, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size)) == Z_OK else { throw Failure.invalid }
        }
        deinit { inflateEnd(&stream) }
        func read(into output: inout [UInt8]) throws {
            var written = 0
            while written < output.count {
                guard !ended else { throw Failure.invalid }
                if offset == input.count {
                    let count = Int(min(UInt64(65_536), reader.size - reader.position))
                    guard count > 0 else { throw Failure.invalid }
                    input = Array(try reader.read(count)); offset = 0
                }
                let available = input.count - offset
                let wanted = output.count - written
                var consumed = 0, produced = 0
                let status = input.withUnsafeMutableBufferPointer { source -> Int32 in
                    output.withUnsafeMutableBufferPointer { target -> Int32 in
                        stream.next_in = source.baseAddress!.advanced(by: offset); stream.avail_in = uInt(available)
                        stream.next_out = target.baseAddress!.advanced(by: written); stream.avail_out = uInt(wanted)
                        let result = inflate(&stream, Z_NO_FLUSH)
                        consumed = available - Int(stream.avail_in)
                        produced = wanted - Int(stream.avail_out)
                        return result
                    }
                }
                offset += consumed; written += produced
                if status == Z_STREAM_END { ended = true }
                guard status == Z_OK || status == Z_STREAM_END, consumed > 0 || produced > 0 else { throw Failure.invalid }
            }
        }
        func finish() throws {
            if ended { return }
            var extra = [UInt8](repeating: 0, count: 1)
            // Valid zlib termination may need a final call to consume the Adler
            // checksum, but it must not produce another decompressed byte.
            do { try read(into: &extra); throw Failure.invalid }
            catch { if !ended || stream.avail_out == 0 { throw Failure.invalid } }
        }
    }
}
