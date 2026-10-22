import AppKit
import ImageIO

/// Local audio has the same canvas transitions as photos, without a fake video layer.
enum AudioArtwork {
    /// Album metadata is untrusted and can contain oversized embedded images.
    /// Keep covers independent of the full-resolution photo loading policy.
    static func decodeCover(_ data: Data) -> CGImage? {
        guard !data.isEmpty, data.count <= 32 * 1_024 * 1_024,
              let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
              CGImageSourceGetCount(source) > 0,
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
              let width = properties[kCGImagePropertyPixelWidth as String] as? NSNumber,
              let height = properties[kCGImagePropertyPixelHeight as String] as? NSNumber,
              width.doubleValue > 0, height.doubleValue > 0,
              width.doubleValue * height.doubleValue <= 100_000_000 else { return nil }
        return CGImageSourceCreateThumbnailAtIndex(source, 0, [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 2048,
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary)
    }

    static func make(for url: URL, waveform: AudioWaveform? = nil) -> CGImage? {
        let size = NSSize(width: 960, height: 600)
        let image = NSImage(size: size)
        image.lockFocus()
        let rect = NSRect(origin: .zero, size: size)
        NSGradient(starting: NSColor(calibratedRed: 0.16, green: 0.18, blue: 0.24, alpha: 1),
                   ending: NSColor(calibratedRed: 0.07, green: 0.08, blue: 0.12, alpha: 1))?.draw(in: rect, angle: -35)
        if let waveform, !waveform.peaks.isEmpty {
            let area = NSRect(x: 72, y: 282, width: 816, height: 194)
            NSColor.white.withAlphaComponent(0.12).setStroke()
            let baseline = NSBezierPath()
            baseline.move(to: NSPoint(x: area.minX, y: area.midY))
            baseline.line(to: NSPoint(x: area.maxX, y: area.midY))
            baseline.lineWidth = 1; baseline.stroke()
            let count = min(408, waveform.peaks.count)
            let step = area.width / CGFloat(count)
            for index in 0..<count {
                let start = index * waveform.peaks.count / count
                let end = max(start + 1, (index + 1) * waveform.peaks.count / count)
                let peak = waveform.peaks[start..<min(waveform.peaks.count, end)].max() ?? 0
                // A gentle display curve keeps quiet material legible while
                // the stored envelope remains the actual absolute amplitude.
                let height = max(1.3, CGFloat(pow(Double(peak), 0.65)) * area.height)
                let bar = NSRect(x: area.minX + CGFloat(index) * step, y: area.midY - height / 2,
                                 width: max(1, step - 0.8), height: height)
                NSColor(calibratedRed: 0.99, green: 0.68 + 0.12 * CGFloat(index) / CGFloat(count), blue: 0.34, alpha: 1).setFill()
                NSBezierPath(roundedRect: bar, xRadius: 0.8, yRadius: 0.8).fill()
            }
        } else {
            let baseSymbol = NSImage(systemSymbolName: "music.note", accessibilityDescription: nil)?
                .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 100, weight: .light))
            let symbol = baseSymbol?.withSymbolConfiguration(NSImage.SymbolConfiguration(paletteColors: [.systemOrange]))
            symbol?.draw(in: NSRect(x: 410, y: 315, width: 140, height: 135))
        }
        let style = NSMutableParagraphStyle(); style.alignment = .center; style.lineBreakMode = .byTruncatingMiddle
        let name = url.deletingPathExtension().lastPathComponent as NSString
        name.draw(in: NSRect(x: 60, y: 200, width: 840, height: 45), withAttributes: [
            .font: NSFont.systemFont(ofSize: 28, weight: .medium), .foregroundColor: NSColor.white,
            .paragraphStyle: style
        ])
        (url.pathExtension.uppercased() as NSString).draw(in: NSRect(x: 60, y: 156, width: 840, height: 30), withAttributes: [
            .font: NSFont.systemFont(ofSize: 17), .foregroundColor: NSColor(white: 0.67, alpha: 1),
            .paragraphStyle: style
        ])
        image.unlockFocus()
        return image.cgImage(forProposedRect: nil, context: nil, hints: nil)
    }
}
