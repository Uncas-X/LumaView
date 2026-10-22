import AppKit

/// A second, smaller strip for pages inside the selected file.
final class DocumentFilmstrip: NSView {
    var document: DocumentMedia? {
        didSet {
            generation &+= 1; cache.removeAllObjects(); pending.removeAll(); failed.removeAll()
            selected = 0; needsDisplay = true
        }
    }
    var selected = 0 { didSet { needsDisplay = true } }
    var keyboardFocused = false { didSet { needsDisplay = true } }
    var onSelect: ((Int) -> Void)?
    var onInteraction: (() -> Void)?
    private var generation: UInt = 0
    private var wheelTime = 0.0
    private var pending = Set<Int>(), failed = Set<Int>()
    private let cache = NSCache<NSNumber, NSImage>()
    private var count: Int { document?.pageCount ?? 0 }
    private var capacity: Int { max(1, Int((bounds.width - 8) / 40)) }
    private var first: Int { max(0, min(selected - capacity / 2, count - capacity)) }
    private var startX: CGFloat { (bounds.width - CGFloat(min(capacity, count)) * 40) / 2 }

    override init(frame: NSRect) {
        super.init(frame: frame); cache.countLimit = 100
        setAccessibilityRole(.list)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func draw(_ dirtyRect: NSRect) {
        guard let document, count > 0 else { return }
        for index in first..<min(count, first + capacity) {
            let rect = NSRect(x: startX + CGFloat(index - first) * 40 + 3, y: 12, width: 34, height: 32)
            NSColor(white: 1, alpha: 0.06).setFill()
            NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3).fill()
            if let image = cache.object(forKey: NSNumber(value: index)) {
                let scale = min(30 / max(1, image.size.width), 28 / max(1, image.size.height))
                let target = NSRect(x: rect.midX - image.size.width * scale / 2,
                                    y: rect.midY - image.size.height * scale / 2,
                                    width: image.size.width * scale, height: image.size.height * scale)
                image.draw(in: target)
            } else if !pending.contains(index), !failed.contains(index) {
                pending.insert(index)
                let request = generation
                document.thumbnail(at: index, maxPixelDimension: 120) { [weak self] image in
                    guard let self, self.generation == request else { return }
                    self.pending.remove(index)
                    if let image {
                        self.cache.setObject(NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height)), forKey: NSNumber(value: index))
                    } else { self.failed.insert(index) }
                    self.needsDisplay = true
                }
            }
            let color: NSColor = keyboardFocused ? .systemOrange : NSColor(white: 0.7, alpha: 1)
            if index == selected {
                color.setStroke()
                let outline = NSBezierPath(roundedRect: rect.insetBy(dx: -1, dy: -1), xRadius: 4, yRadius: 4)
                outline.lineWidth = keyboardFocused ? 2 : 1; outline.stroke()
            }
            let text = String(index + 1) as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .medium),
                .foregroundColor: index == selected ? color : NSColor.secondaryLabelColor
            ]
            let width = text.size(withAttributes: attributes).width
            text.draw(at: NSPoint(x: rect.midX - width / 2, y: 0), withAttributes: attributes)
        }
    }
    override func mouseDown(with event: NSEvent) {
        onInteraction?()
        let point = convert(event.locationInWindow, from: nil)
        let offset = Int(floor((point.x - startX) / 40))
        guard offset >= 0, offset < capacity else { return }
        let index = first + offset
        if index >= 0 && index < count { onSelect?(index) }
    }
    override func mouseUp(with event: NSEvent) {}
    override func mouseDragged(with event: NSEvent) {}
    override func scrollWheel(with event: NSEvent) {
        onInteraction?()
        guard event.timestamp - wheelTime > 0.1 else { return }
        let delta = abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) ? event.scrollingDeltaX : -event.scrollingDeltaY
        guard abs(delta) > 0.3 else { return }
        wheelTime = event.timestamp
        onSelect?(max(0, min(count - 1, selected + (delta > 0 ? 1 : -1))))
    }
}
