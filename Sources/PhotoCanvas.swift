import AppKit
import AVFoundation
import QuartzCore

enum CanvasBackground: Int, CaseIterable {
    case translucent, dark, light
}

/// Pixel-aware media display, deliberately separate from the window's controls.
final class PhotoCanvas: NSView {
    var image: CGImage? {
        didSet {
            if image != nil { removePlaceholder() }
            needsDisplay = true
        }
    }
    private(set) var documentPage: DocumentPage?
    var pixelSize: CGSize = .zero
    var quarterTurns: Int = 0 {
        didSet {
            guard !updatingImage else { return }
            if isFit { updateFitScale() }
            clampPan()
            applyGeometry(animated: false)
            needsDisplay = true
        }
    }
    var backgroundMode: CanvasBackground = .translucent {
        didSet { needsDisplay = true; onBackgroundModeChanged?() }
    }
    var onBackgroundModeChanged: (() -> Void)?
    var onNavigate: ((Int) -> Void)?
    var onInteraction: (() -> Void)?
    var onBackgroundClick: (() -> Void)?
    /// Controller-owned chrome regions are excluded at both ends of a click, even during fades.
    var onShouldBeginMouseSequence: ((NSPoint) -> Bool)?
    var onOpen: (([URL]) -> Void)?
    var onZoomChanged: ((Double) -> Void)?
    /// Called once for the current video's first displayable frame, on main.
    var onVideoReady: (() -> Void)?
    var onKey: ((NSEvent) -> Bool)?
    var onContextMenu: ((NSPoint) -> NSMenu?)?
    var hasMedia: Bool { image != nil || photo?.video != nil || documentPage != nil }
    var additionalBottomInset: CGFloat = 0 {
        didSet {
            if isFit { updateFitScale() }
            clampPan()
            applyGeometry(animated: false)
            placeholderCacheKey = ""
            needsDisplay = true
        }
    }
    var wheelNavigates = false
    func refreshLocalization() {
        placeholderCacheKey = ""
        setAccessibilityLabel(L10n.tr("图片与音视频浏览区域"))
        setAccessibilityHelp(L10n.tr("单击切换适合窗口与实际像素，拖动平移，滚轮缩放。"))
        needsDisplay = true
    }
    var placeholderText: String? { didSet { needsDisplay = true } }
    var animationsEnabled = true {
        didSet { if !animationsEnabled { finishAnimations() } }
    }
    var isAnimating: Bool {
        outgoingLayer != nil || !(photo?.container.animationKeys() ?? []).isEmpty || !(photo?.content.animationKeys() ?? []).isEmpty
    }

    private(set) var zoom: Double = 1
    private(set) var isFit = true
    private var pan = NSPoint.zero
    private var mouseDownPoint = NSPoint.zero
    private var mouseDownPan = NSPoint.zero
    private var mouseStartedOnImage = false
    private var ownsMouseSequence = false
    private var isDraggingImage = false
    private var tracking: NSTrackingArea?
    private var wheelNavigationAccumulation: CGFloat = 0
    private var lastWheelNavigation: TimeInterval = 0
    private var isDropTarget = false
    private var updatingImage = false
    private let imageHost = CALayer()
    private let placeholderLayer = CALayer()
    private let dropLayer = CAShapeLayer()
    private var photo: PhotoLayers?
    private var outgoingLayer: CALayer?
    private var outgoingHasVideo = false
    private var transitionCleanup: DispatchWorkItem?
    private var placeholderCacheKey = ""
    private var mediaGeneration: UInt64 = 0
    private var videoReadyObservation: NSKeyValueObservation?
    private var awaitingVideoFrame = false

    private struct PhotoLayers {
        let container: CALayer
        let content: CALayer
        let bitmap: CALayer
        let matte: CALayer
        let video: AVPlayerLayer?
    }

    override var wantsUpdateLayer: Bool { true }
    private var shouldAnimate: Bool {
        animationsEnabled && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    override var acceptsFirstResponder: Bool { true }
    override var isOpaque: Bool { backgroundMode != .translucent }

    private var screenScale: CGFloat {
        max(1, window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2)
    }

    /// Fit keeps the photo clear of the title strip and filmstrip controls.
    private var viewport: NSRect {
        let horizontal = min(40.0, bounds.width * 0.08)
        let verticalScale = min(1, bounds.height / 300)
        let bottom = (170 + max(0, additionalBottomInset)) * verticalScale
        let top = 80 * verticalScale
        return NSRect(x: bounds.minX + horizontal,
                      y: bounds.minY + bottom,
                      width: max(1, bounds.width - horizontal * 2),
                      height: max(1, bounds.height - bottom - top))
    }

    private var sourceSize: CGSize {
        if let documentPage, documentPage.isVector {
            return CGSize(width: documentPage.size.width * screenScale, height: documentPage.size.height * screenScale)
        }
        if pixelSize.width > 0, pixelSize.height > 0 { return pixelSize }
        guard let image else { return .zero }
        return CGSize(width: image.width, height: image.height)
    }

    private var rotatedSize: CGSize {
        let size = sourceSize
        return abs(quarterTurns) % 2 == 0 ? size : CGSize(width: size.height, height: size.width)
    }

    private var imageRect: NSRect {
        let dimensions = rotatedSize
        let pointScale = CGFloat(zoom) / screenScale
        let size = CGSize(width: dimensions.width * pointScale, height: dimensions.height * pointScale)
        return NSRect(x: viewport.midX + pan.x - size.width / 2,
                      y: viewport.midY + pan.y - size.height / 2,
                      width: size.width, height: size.height)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
        setAccessibilityRole(.image)
        setAccessibilityLabel(L10n.tr("图片与音视频浏览区域"))
        setAccessibilityHelp(L10n.tr("单击切换适合窗口与实际像素，拖动平移，滚轮缩放。"))
        configureLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([.fileURL])
        configureLayers()
    }

    deinit {
        videoReadyObservation?.invalidate()
        transitionCleanup?.cancel()
        photo?.video?.player?.pause()
        photo?.video?.player = nil
        if let outgoingLayer { detachVideoPlayers(in: outgoingLayer) }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.acceptsMouseMovedEvents = true
        if isFit { updateFitScale() }
        applyGeometry(animated: false)
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        if isFit { updateFitScale() }
        clampPan()
        applyGeometry(animated: false)
        placeholderCacheKey = ""
        needsDisplay = true
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        if isFit { updateFitScale() }
        clampPan()
        applyGeometry(animated: false)
        needsDisplay = true
    }

    /// Keep the current pixels visible until the next decoder result is ready.
    func beginImageLoading() {
        if !hasMedia { placeholderText = "正在打开…" }
    }

    func setImage(_ cg: CGImage?, pixelSize: CGSize, reset: Bool = true, quarterTurns: Int = 0, animated: Bool = true) {
        if !reset, let cg, let photo, photo.video == nil, documentPage == nil, self.pixelSize == pixelSize {
            // GIF/APNG frames only replace texture contents. Transform and arrival animations survive.
            image = cg
            self.pixelSize = pixelSize
            withoutActions { photo.bitmap.contents = cg }
            return
        }
        _ = beginMediaReplacement(keepingOutgoing: cg != nil && animated && shouldAnimate)
        updatingImage = true
        image = cg
        self.pixelSize = pixelSize
        if reset {
            self.quarterTurns = ((quarterTurns % 4) + 4) % 4
            isFit = true
            pan = .zero
            updateFitScale()
        } else {
            if isFit { updateFitScale() }
            clampPan()
        }
        updatingImage = false
        if let cg {
            placeholderText = nil
            let layers = makePhotoLayers(cg)
            photo = layers
            imageHost.addSublayer(layers.container)
            applyGeometry(animated: false)
            showIncoming(layers, animated: animated)
        }
        needsDisplay = true
        window?.invalidateCursorRects(for: self)
    }

    /// A complete page is presented in one crossfade. Native vector tiles provide
    /// detail beyond that initial surface, always with a complete page underneath.
    /// TIFF keeps its bounded raster preview and original pixel geometry.
    func setDocumentPage(_ page: DocumentPage, animated: Bool = true) {
        if !page.isVector, let raster = page.rasterImage {
            setImage(raster, pixelSize: page.size, animated: animated)
            documentPage = page
            return
        }
        _ = beginMediaReplacement(keepingOutgoing: animated && shouldAnimate)
        updatingImage = true
        documentPage = page
        image = nil
        pixelSize = CGSize(width: page.size.width * screenScale, height: page.size.height * screenScale)
        quarterTurns = 0
        isFit = true
        pan = .zero
        updateFitScale()
        updatingImage = false
        placeholderText = nil
        let layers = makeDocumentLayers(page)
        photo = layers
        imageHost.addSublayer(layers.container)
        removePlaceholder()
        applyGeometry(animated: false)
        showIncoming(layers, animated: animated)
        needsDisplay = true
        window?.invalidateCursorRects(for: self)
    }

    /// `size` is the video's oriented presentation size, not its encoded raster.
    /// Playback ownership stays with the controller; this view owns display layers.
    func setVideo(player: AVPlayer, size: CGSize, animated: Bool = true) {
        guard size.width.isFinite, size.height.isFinite, size.width > 0, size.height > 0 else { return }
        if photo?.video?.player === player {
            pixelSize = size
            if isFit { updateFitScale() }
            clampPan()
            applyGeometry(animated: false)
            return
        }
        // Retain the previous visible frame even without animation until the new
        // player layer actually has pixels; item readiness alone is insufficient.
        _ = beginMediaReplacement(keepingOutgoing: true)
        updatingImage = true
        image = nil
        pixelSize = size
        quarterTurns = 0
        isFit = true
        pan = .zero
        updateFitScale()
        updatingImage = false
        placeholderText = nil
        let layers = makeVideoLayers(player)
        photo = layers
        awaitingVideoFrame = true
        withoutActions { layers.container.opacity = 0 }
        imageHost.addSublayer(layers.container)
        removePlaceholder()
        applyGeometry(animated: false)
        let generation = mediaGeneration
        if let video = layers.video {
            videoReadyObservation = video.observe(\.isReadyForDisplay, options: [.initial, .new]) { [weak self, weak video] _, _ in
                DispatchQueue.main.async { [weak self, weak video] in
                    guard let self, let video, self.mediaGeneration == generation,
                          self.photo?.video === video, self.awaitingVideoFrame, video.isReadyForDisplay,
                          let current = self.photo else { return }
                    self.videoReadyObservation?.invalidate()
                    self.videoReadyObservation = nil
                    self.awaitingVideoFrame = false
                    self.showIncoming(current, animated: animated)
                    self.needsDisplay = true
                    self.onVideoReady?()
                }
            }
        }
        needsDisplay = true
        window?.invalidateCursorRects(for: self)
    }

    func clearImage() {
        placeholderText = nil
        setImage(nil, pixelSize: .zero, animated: false)
    }

    /// Invalidate readiness before replacing layers so a late frame cannot reveal
    /// an older selection. The current and one frozen outgoing container are the limit.
    private func beginMediaReplacement(keepingOutgoing: Bool) -> CALayer? {
        mediaGeneration &+= 1
        videoReadyObservation?.invalidate()
        videoReadyObservation = nil
        cancelMouseSequence()
        let outgoing = keepingOutgoing ? prepareOutgoingLayer() : nil
        if outgoing == nil { removeOutgoingLayer() }
        if let current = photo, current.container !== outgoing {
            detachVideoPlayers(in: current.container)
            current.container.removeFromSuperlayer()
        }
        photo = nil
        documentPage = nil
        awaitingVideoFrame = false
        return outgoing
    }

    private func showIncoming(_ layers: PhotoLayers, animated: Bool) {
        withoutActions { layers.container.opacity = 1 }
        guard animated && shouldAnimate else {
            removeOutgoingLayer()
            return
        }
        animate(layers.container, keyPath: "opacity", from: 0, to: 1, duration: 0.18, key: "imageFade")
        animate(layers.content, keyPath: "transform.scale", from: 0.987, to: 1, duration: 0.2, key: "imageArrival")
        if let outgoing = outgoingLayer {
            let opacity = outgoing.presentation()?.opacity ?? outgoing.opacity
            animate(outgoing, keyPath: "opacity", from: opacity, to: 0, duration: 0.18, key: "imageFade")
            withoutActions { outgoing.opacity = 0 }
            let cleanup = DispatchWorkItem { [weak self, weak outgoing] in
                guard let self, let outgoing, self.outgoingLayer === outgoing else { return }
                self.removeOutgoingLayer()
            }
            transitionCleanup = cleanup
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22, execute: cleanup)
        }
    }

    func fit() {
        isFit = true
        pan = .zero
        updateFitScale()
        applyGeometry(animated: true)
        needsDisplay = true
        window?.invalidateCursorRects(for: self)
    }

    private func updateFitScale() {
        let size = rotatedSize
        guard size.width > 0, size.height > 0 else {
            zoom = 1
            onZoomChanged?(zoom)
            return
        }
        let maximumFit: CGFloat = documentPage?.isVector == true ? 32 : 1
        zoom = Double(min(maximumFit, min(viewport.width * screenScale / size.width,
                                         viewport.height * screenScale / size.height)))
        onZoomChanged?(zoom)
    }

    func toggleActualSize(at point: NSPoint? = nil) {
        guard hasMedia else { return }
        if isFit {
            setZoom(1, at: point)
        } else {
            fit()
        }
    }

    func zoomBy(_ factor: Double, at point: NSPoint? = nil) {
        guard hasMedia, factor.isFinite, factor > 0 else { return }
        setZoom(zoom * factor, at: point)
    }

    private func setZoom(_ requested: Double, at point: NSPoint?, animated: Bool = true) {
        let oldZoom = max(zoom, 0.000001)
        // The lower limit also accommodates very large panoramic photographs.
        let size = rotatedSize
        let fitting = Double(min(viewport.width * screenScale / max(size.width, 1),
                                 viewport.height * screenScale / max(size.height, 1)))
        let minimum = min(0.01, fitting * 0.2)
        let nextZoom = min(32, max(minimum, requested))
        let anchor = point ?? NSPoint(x: viewport.midX, y: viewport.midY)
        let center = NSPoint(x: viewport.midX + pan.x, y: viewport.midY + pan.y)
        let ratio = CGFloat(nextZoom / oldZoom)
        pan.x = anchor.x - (anchor.x - center.x) * ratio - viewport.midX
        pan.y = anchor.y - (anchor.y - center.y) * ratio - viewport.midY
        zoom = nextZoom
        isFit = false
        clampPan()
        applyGeometry(animated: animated, preserveRotation: !animated)
        onZoomChanged?(zoom)
        needsDisplay = true
        window?.invalidateCursorRects(for: self)
    }

    func rotate(_ delta: Int) {
        guard hasMedia else { return }
        let radians = -CGFloat(delta) * .pi / 2
        let rotatedPan = NSPoint(x: pan.x * cos(radians) - pan.y * sin(radians),
                                 y: pan.x * sin(radians) + pan.y * cos(radians))
        pan = rotatedPan
        updatingImage = true
        quarterTurns = ((quarterTurns + delta) % 4 + 4) % 4
        updatingImage = false
        if isFit { updateFitScale() }
        clampPan()
        applyGeometry(animated: true)
        needsDisplay = true
        window?.invalidateCursorRects(for: self)
    }

    private func clampPan() {
        let size = rotatedSize
        let halfExtraWidth = max(0, (size.width * CGFloat(zoom) / screenScale - viewport.width) / 2)
        let halfExtraHeight = max(0, (size.height * CGFloat(zoom) / screenScale - viewport.height) / 2)
        pan.x = min(halfExtraWidth, max(-halfExtraWidth, pan.x))
        pan.y = min(halfExtraHeight, max(-halfExtraHeight, pan.y))
    }

    private func configureLayers() {
        wantsLayer = true
        imageHost.name = "photo-host"
        imageHost.masksToBounds = true
        placeholderLayer.name = "photo-placeholder"
        dropLayer.name = "drop-highlight"
        layer?.addSublayer(imageHost)
        layer?.addSublayer(placeholderLayer)
        layer?.addSublayer(dropLayer)
        withoutActions { imageHost.frame = bounds }
        needsDisplay = true
    }

    private func withoutActions(_ changes: () -> Void) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        changes()
        CATransaction.commit()
    }

    private var canvasColor: NSColor {
        switch backgroundMode {
        case .translucent: return .black.withAlphaComponent(0.22)
        case .dark: return NSColor(srgbRed: 16.0 / 255, green: 17.0 / 255, blue: 19.0 / 255, alpha: 1)
        case .light: return NSColor(srgbRed: 239.0 / 255, green: 239.0 / 255, blue: 237.0 / 255, alpha: 1)
        }
    }

    /// Image textures are installed immediately, so empty-state content must disappear
    /// in the same transaction rather than waiting for AppKit's next display pass.
    private func removePlaceholder() {
        placeholderCacheKey = ""
        placeholderLayer.removeAllAnimations()
        withoutActions {
            placeholderLayer.isHidden = true
            placeholderLayer.contents = nil
            placeholderLayer.removeFromSuperlayer()
            layer?.contents = nil
        }
    }

    /// The screen uses composited textures. draw(_:) below remains a deterministic export path.
    override func updateLayer() {
        withoutActions {
            layer?.backgroundColor = canvasColor.cgColor
            layer?.contents = nil
            imageHost.frame = bounds
            placeholderLayer.frame = CGRect(x: viewport.midX - 300, y: viewport.midY - 160, width: 600, height: 320)
            dropLayer.frame = bounds
            dropLayer.isHidden = !isDropTarget
            dropLayer.path = CGPath(roundedRect: bounds.insetBy(dx: 15, dy: 15), cornerWidth: 16, cornerHeight: 16, transform: nil)
            dropLayer.fillColor = NSColor.controlAccentColor.withAlphaComponent(0.12).cgColor
            dropLayer.strokeColor = NSColor.controlAccentColor.withAlphaComponent(0.8).cgColor
            dropLayer.lineWidth = 2
        }
        guard !hasMedia else {
            removePlaceholder()
            return
        }
        withoutActions {
            if placeholderLayer.superlayer !== layer {
                layer?.insertSublayer(placeholderLayer, above: imageHost)
            }
            placeholderLayer.isHidden = false
        }
        let key = "\(placeholderText ?? "welcome")|\(backgroundMode.rawValue)|\(screenScale)"
        guard key != placeholderCacheKey else { return }
        placeholderCacheKey = key
        let scale = screenScale
        guard let context = CGContext(data: nil, width: Int(600 * scale), height: Int(320 * scale), bitsPerComponent: 8,
                                      bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return }
        context.scaleBy(x: scale, y: scale)
        context.translateBy(x: 300 - viewport.midX, y: 160 - viewport.midY)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        if let placeholderText {
            let foreground: NSColor = backgroundMode == .light ? .darkGray : .white
            drawCentered(L10n.tr(placeholderText), y: viewport.midY - 8,
                         font: .systemFont(ofSize: 14), color: foreground.withAlphaComponent(0.65))
        } else {
            drawEmptyState()
        }
        NSGraphicsContext.restoreGraphicsState()
        withoutActions { placeholderLayer.contents = context.makeImage(); placeholderLayer.contentsScale = scale }
    }

    private func makePhotoLayers(_ image: CGImage) -> PhotoLayers {
        let container = CALayer(), content = CALayer(), bitmap = CALayer(), matte = CALayer()
        container.name = "photo-current"
        content.name = "photo-content"
        bitmap.name = "photo-bitmap"
        container.shadowColor = NSColor.black.cgColor
        container.shadowOpacity = 0.35
        container.shadowRadius = 11
        container.shadowOffset = CGSize(width: 0, height: -7)
        // Raster transparency reveals the viewer background in every format.
        // No rectangular matte/border may contribute to the shadow silhouette;
        // PSB soft masks can contain transparency even when alphaInfo says none.
        bitmap.contents = image
        bitmap.contentsGravity = .resize
        bitmap.minificationFilter = .trilinear
        bitmap.magnificationFilter = .linear
        content.addSublayer(bitmap)
        container.addSublayer(content)
        return PhotoLayers(container: container, content: content, bitmap: bitmap, matte: matte, video: nil)
    }

    private func makeDocumentLayers(_ page: DocumentPage) -> PhotoLayers {
        let container = CALayer(), content = CALayer(), matte = CALayer()
        let tiles = DocumentTileLayer()
        container.name = "photo-current"
        content.name = "photo-content"
        tiles.name = "document-vector-tiles"
        tiles.documentPage = page
        tiles.contentsScale = screenScale
        container.shadowColor = NSColor.black.cgColor
        container.shadowOpacity = 0.35
        container.shadowRadius = 11
        container.shadowOffset = CGSize(width: 0, height: -7)
        content.borderColor = NSColor.black.withAlphaComponent(0.12).cgColor
        content.borderWidth = 0.5
        // The page preview is a single complete surface prepared off-main before
        // this page replaces its predecessor. No empty tile can reveal white gaps.
        matte.name = "document-page-preview"
        matte.contents = page.presentationPreview
        matte.contentsGravity = .resize
        matte.minificationFilter = .trilinear
        matte.magnificationFilter = .linear
        content.backgroundColor = NSColor.white.cgColor
        content.addSublayer(matte)
        content.addSublayer(tiles)
        container.addSublayer(content)
        tiles.setNeedsDisplay()
        return PhotoLayers(container: container, content: content, bitmap: tiles, matte: matte, video: nil)
    }

    private func makeVideoLayers(_ player: AVPlayer) -> PhotoLayers {
        let container = CALayer(), content = CALayer(), matte = CALayer()
        let video = AVPlayerLayer(player: player)
        container.name = "photo-current"
        content.name = "photo-content"
        video.name = "video-player"
        container.shadowColor = NSColor.black.cgColor
        container.shadowOpacity = 0.35
        container.shadowRadius = 11
        container.shadowOffset = CGSize(width: 0, height: -7)
        content.borderColor = NSColor.black.withAlphaComponent(0.12).cgColor
        content.borderWidth = 0.5
        video.videoGravity = .resizeAspect
        video.backgroundColor = NSColor.black.cgColor
        content.addSublayer(video)
        container.addSublayer(content)
        return PhotoLayers(container: container, content: content, bitmap: video, matte: matte, video: video)
    }

    private func animate(_ layer: CALayer, keyPath: String, from: Any, to: Any, duration: TimeInterval = 0.2, key: String) {
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.fromValue = from
        animation.toValue = to
        animation.duration = duration
        animation.beginTime = layer.convertTime(CACurrentMediaTime(), from: nil)
        animation.isRemovedOnCompletion = true
        animation.fillMode = .removed
        animation.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.65, 0.25, 1)
        let identifier = UUID().uuidString
        animation.setValue(identifier, forKey: "lumaTransitionID")
        layer.add(animation, forKey: key)
        // Core Animation can retain a completed explicit key while a window is idle.
        // Identity checking makes cleanup safe when wheel input retargets the same key.
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.035) { [weak layer] in
            guard let layer, layer.animation(forKey: key)?.value(forKey: "lumaTransitionID") as? String == identifier else { return }
            layer.removeAnimation(forKey: key)
        }
    }

    private func applyGeometry(animated: Bool, preserveRotation: Bool = false) {
        guard let photo else { return }
        let container = photo.container
        let shown = container.presentation() ?? container
        let fromPosition = shown.position
        let fromScale = sqrt(shown.transform.m11 * shown.transform.m11 + shown.transform.m12 * shown.transform.m12)
        let fromAngle = atan2(shown.transform.m12, shown.transform.m11)
        let targetPosition = CGPoint(x: viewport.midX + pan.x, y: viewport.midY + pan.y)
        let targetAngle = -CGFloat(quarterTurns) * .pi / 2
        var nearestAngle = targetAngle
        while nearestAngle - fromAngle > .pi { nearestAngle -= 2 * .pi }
        while nearestAngle - fromAngle < -.pi { nearestAngle += 2 * .pi }
        let base = CGRect(origin: .zero, size: CGSize(width: sourceSize.width / screenScale, height: sourceSize.height / screenScale))
        container.removeAnimation(forKey: "zoom")
        container.removeAnimation(forKey: "pan")
        if !preserveRotation { container.removeAnimation(forKey: "rotation") }
        withoutActions {
            container.bounds = base
            container.position = targetPosition
            container.transform = CATransform3DScale(CATransform3DMakeRotation(targetAngle, 0, 0, 1), CGFloat(zoom), CGFloat(zoom), 1)
            // A nil path makes Core Animation use the current composited alpha,
            // including soft masks and each newly installed GIF/APNG frame.
            // Paper pages and video surfaces still cast rectangular shadows.
            container.shadowPath = (photo.video != nil || photo.bitmap is DocumentTileLayer)
                ? CGPath(rect: base, transform: nil) : nil
            photo.content.frame = base
            photo.bitmap.frame = base
            photo.matte.frame = base
            if let tiles = photo.bitmap as? DocumentTileLayer {
                tiles.contentsScale = screenScale
                if let page = documentPage, let preview = page.presentationPreview {
                    let requiredWidth = page.size.width * screenScale * CGFloat(zoom)
                    let requiredHeight = page.size.height * screenScale * CGFloat(zoom)
                    // At fit, an exact-or-better screen-resolution page is already
                    // complete. Keep tiles hidden to avoid piecemeal page arrivals.
                    // Manual zoom and larger displays use the retained vector data.
                    tiles.isHidden = isFit && requiredWidth <= CGFloat(preview.width) + 1
                        && requiredHeight <= CGFloat(preview.height) + 1
                } else { tiles.isHidden = false }
            } else if photo.video == nil {
                photo.bitmap.magnificationFilter = zoom >= 4 ? .nearest : .linear
            }
        }
        if animated && shouldAnimate {
            if abs(fromScale - CGFloat(zoom)) > 0.000001 {
                animate(container, keyPath: "transform.scale", from: fromScale, to: zoom, key: "zoom")
            }
            if abs(nearestAngle - fromAngle) > 0.000001 {
                animate(container, keyPath: "transform.rotation.z", from: fromAngle, to: nearestAngle, duration: 0.22, key: "rotation")
            }
            if hypot(fromPosition.x - targetPosition.x, fromPosition.y - targetPosition.y) > 0.01 {
                animate(container, keyPath: "position", from: NSValue(point: fromPosition), to: NSValue(point: targetPosition), key: "pan")
            }
        }
    }

    private func prepareOutgoingLayer() -> CALayer? {
        guard let current = photo else { return nil }
        transitionCleanup?.cancel()
        transitionCleanup = nil
        current.video?.player?.pause()
        // A not-yet-visible video must not displace the last visible frame. For
        // overlapping video fades retain the more visible container, since a
        // CALayer bitmap snapshot cannot capture AVPlayerLayer's video surface.
        if let previous = outgoingLayer {
            let currentOpacity = current.container.presentation()?.opacity ?? current.container.opacity
            let previousOpacity = previous.presentation()?.opacity ?? previous.opacity
            if awaitingVideoFrame || ((current.video != nil || outgoingHasVideo) && previousOpacity > currentOpacity) {
                let shown = previous.presentation() ?? previous
                let transform = shown.transform, position = shown.position, opacity = shown.opacity
                previous.removeAllAnimations()
                withoutActions {
                    previous.transform = transform
                    previous.position = position
                    previous.opacity = opacity
                }
                return previous
            }
        }
        let outgoing: CALayer
        if outgoingLayer != nil, current.video == nil, !outgoingHasVideo, let snapshot = snapshotComposite() {
            removeOutgoingLayer()
            current.container.removeFromSuperlayer()
            outgoing = snapshot
            imageHost.addSublayer(outgoing)
            outgoingHasVideo = false
        } else {
            removeOutgoingLayer()
            let presented = current.container.presentation() ?? current.container
            let transform = presented.transform, position = presented.position, opacity = presented.opacity
            let contentTransform = current.content.presentation()?.transform ?? current.content.transform
            current.container.removeAllAnimations()
            current.content.removeAllAnimations()
            withoutActions {
                current.container.transform = transform
                current.container.position = position
                current.container.opacity = opacity
                current.content.transform = contentTransform
            }
            outgoing = current.container
            outgoingHasVideo = current.video != nil
        }
        outgoing.name = "photo-outgoing"
        outgoingLayer = outgoing
        return outgoing
    }

    /// A rapid second file switch freezes the composed frame once, rather than retaining a growing layer stack.
    private func snapshotComposite() -> CALayer? {
        guard photo?.video == nil, !outgoingHasVideo, !(photo?.bitmap is DocumentTileLayer),
              !containsDocumentTiles(outgoingLayer), bounds.width > 0, bounds.height > 0 else { return nil }
        let scale = min(screenScale, 4096 / max(bounds.width, bounds.height))
        guard let context = CGContext(data: nil, width: max(1, Int(bounds.width * scale)), height: max(1, Int(bounds.height * scale)),
                                      bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        context.scaleBy(x: scale, y: scale)
        (imageHost.presentation() ?? imageHost).render(in: context)
        guard let image = context.makeImage() else { return nil }
        let snapshot = CALayer()
        snapshot.frame = bounds
        snapshot.contents = image
        snapshot.contentsScale = scale
        return snapshot
    }

    private func containsDocumentTiles(_ layer: CALayer?) -> Bool {
        guard let layer else { return false }
        return layer is DocumentTileLayer || (layer.sublayers ?? []).contains { containsDocumentTiles($0) }
    }

    private func removeOutgoingLayer() {
        transitionCleanup?.cancel()
        transitionCleanup = nil
        if let outgoingLayer { detachVideoPlayers(in: outgoingLayer) }
        outgoingLayer?.removeAllAnimations()
        outgoingLayer?.removeFromSuperlayer()
        outgoingLayer = nil
        outgoingHasVideo = false
    }

    private func detachVideoPlayers(in container: CALayer) {
        if let video = container as? AVPlayerLayer {
            video.player?.pause()
            video.player = nil
        }
        for child in container.sublayers ?? [] { detachVideoPlayers(in: child) }
    }

    private func finishAnimations() {
        // Disabling motion must not expose a player layer before its first frame.
        if !awaitingVideoFrame { removeOutgoingLayer() }
        photo?.container.removeAllAnimations()
        photo?.content.removeAllAnimations()
        withoutActions {
            photo?.container.opacity = awaitingVideoFrame ? 0 : 1
            photo?.content.transform = CATransform3DIdentity
        }
        applyGeometry(animated: false)
    }

    /// Direct gestures take over the currently visible scale, avoiding a snap to a queued wheel target.
    private func takeOverPresentation() {
        guard let photo else { return }
        let presented = photo.container.presentation() ?? photo.container
        zoom = Double(sqrt(presented.transform.m11 * presented.transform.m11 + presented.transform.m12 * presented.transform.m12))
        pan = NSPoint(x: presented.position.x - viewport.midX, y: presented.position.y - viewport.midY)
        isFit = false
        photo.content.removeAnimation(forKey: "imageArrival")
        withoutActions { photo.content.transform = CATransform3DIdentity }
        applyGeometry(animated: false, preserveRotation: true)
        onZoomChanged?(zoom)
    }

    private var displayedImageRect: CGRect {
        guard let photo else { return imageRect }
        return (photo.container.presentation() ?? photo.container).frame
    }

    override func draw(_ dirtyRect: NSRect) {
        let background: NSColor
        switch backgroundMode {
        case .translucent: background = .black.withAlphaComponent(0.22)
        case .dark: background = NSColor(srgbRed: 16.0 / 255, green: 17.0 / 255, blue: 19.0 / 255, alpha: 1)
        case .light: background = NSColor(srgbRed: 239.0 / 255, green: 239.0 / 255, blue: 237.0 / 255, alpha: 1)
        }
        background.setFill()
        bounds.fill(using: .copy)

        guard let cg = NSGraphicsContext.current?.cgContext else { return }
        if let page = documentPage, page.isVector {
            let rect = imageRect
            cg.saveGState()
            cg.setShadow(offset: CGSize(width: 0, height: -7), blur: 22,
                         color: NSColor.black.withAlphaComponent(0.35).cgColor)
            cg.setFillColor(NSColor.white.cgColor)
            cg.fill(rect)
            cg.restoreGState()
            cg.saveGState()
            cg.translateBy(x: rect.midX, y: rect.midY)
            cg.rotate(by: -CGFloat(quarterTurns) * .pi / 2)
            let size = sourceSize
            let scale = CGFloat(zoom) / screenScale
            page.draw(in: cg, rect: CGRect(x: -size.width * scale / 2, y: -size.height * scale / 2,
                                          width: size.width * scale, height: size.height * scale))
            cg.restoreGState()
        } else if let image {
            let rect = imageRect
            cg.saveGState()
            cg.setShadow(offset: CGSize(width: 0, height: -7), blur: 22,
                         color: NSColor.black.withAlphaComponent(0.35).cgColor)
            cg.interpolationQuality = zoom >= 4 ? .none : .high
            cg.translateBy(x: rect.midX, y: rect.midY)
            cg.rotate(by: -CGFloat(quarterTurns) * .pi / 2)
            let size = sourceSize
            let scale = CGFloat(zoom) / screenScale
            cg.draw(image, in: CGRect(x: -size.width * scale / 2, y: -size.height * scale / 2,
                                     width: size.width * scale, height: size.height * scale))
            cg.restoreGState()
        } else if hasMedia {
            // Video is a compositor-owned surface. Bitmap export must not draw
            // the welcome text over it or pretend render(in:) captures a frame.
        } else if let placeholderText {
            let foreground: NSColor = backgroundMode == .light ? .darkGray : .white
            drawCentered(L10n.tr(placeholderText), y: viewport.midY - 8,
                         font: .systemFont(ofSize: 14, weight: .regular), color: foreground.withAlphaComponent(0.65))
        } else {
            drawEmptyState()
        }

        if isDropTarget {
            let highlight = NSBezierPath(roundedRect: bounds.insetBy(dx: 15, dy: 15), xRadius: 16, yRadius: 16)
            NSColor.controlAccentColor.withAlphaComponent(0.12).setFill()
            highlight.fill()
            NSColor.controlAccentColor.withAlphaComponent(0.8).setStroke()
            highlight.lineWidth = 2
            highlight.stroke()
        }
    }

    private func drawEmptyState() {
        let center = NSPoint(x: viewport.midX, y: viewport.midY)
        let foreground: NSColor = backgroundMode == .light ? NSColor(white: 0.18, alpha: 1) : .white
        let iconRect = NSRect(x: center.x - 32, y: center.y + 72, width: 64, height: 48)
        let icon = NSBezierPath(roundedRect: iconRect, xRadius: 8, yRadius: 8)
        foreground.withAlphaComponent(0.5).setStroke()
        icon.lineWidth = 1.8
        icon.stroke()
        let mountain = NSBezierPath()
        mountain.move(to: NSPoint(x: iconRect.minX + 9, y: iconRect.minY + 10))
        mountain.line(to: NSPoint(x: iconRect.minX + 25, y: iconRect.minY + 28))
        mountain.line(to: NSPoint(x: iconRect.minX + 37, y: iconRect.minY + 16))
        mountain.line(to: NSPoint(x: iconRect.minX + 45, y: iconRect.minY + 23))
        mountain.line(to: NSPoint(x: iconRect.maxX - 8, y: iconRect.minY + 10))
        mountain.lineWidth = 1.8
        mountain.stroke()
        foreground.withAlphaComponent(0.5).setFill()
        NSBezierPath(ovalIn: NSRect(x: iconRect.maxX - 19, y: iconRect.maxY - 16, width: 5, height: 5)).fill()

        drawCentered("LumaView", y: center.y + 29,
                     font: .systemFont(ofSize: 32, weight: .medium), color: foreground.withAlphaComponent(0.94))
        drawCentered(L10n.tr("让目光，只停留在画面上。"), y: center.y - 6,
                     font: .systemFont(ofSize: 15, weight: .regular), color: foreground.withAlphaComponent(0.7))
        drawCentered(L10n.tr("拖入图片、音视频或文件夹，开始浏览"), y: center.y - 44,
                     font: .systemFont(ofSize: 12, weight: .regular), color: foreground.withAlphaComponent(0.5))
        drawCentered(L10n.tr("⌘ O  打开图片、音视频或文件夹"), y: center.y - 69,
                     font: .systemFont(ofSize: 11, weight: .regular), color: foreground.withAlphaComponent(0.35))
    }

    private func drawCentered(_ text: String, y: CGFloat, font: NSFont, color: NSColor) {
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let size = (text as NSString).size(withAttributes: attributes)
        (text as NSString).draw(at: NSPoint(x: viewport.midX - size.width / 2, y: y), withAttributes: attributes)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking { removeTrackingArea(tracking) }
        let area = NSTrackingArea(rect: .zero,
                                  options: [.activeInKeyWindow, .mouseMoved, .mouseEnteredAndExited, .inVisibleRect],
                                  owner: self, userInfo: nil)
        tracking = area
        addTrackingArea(area)
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        guard hasMedia else { return }
        let rect = imageRect.intersection(bounds)
        if !rect.isEmpty { addCursorRect(rect, cursor: isFit ? .pointingHand : .openHand) }
    }

    override func mouseMoved(with event: NSEvent) { onInteraction?() }
    override func mouseEntered(with event: NSEvent) { onInteraction?() }

    /// Call before dispatching each new primary mouse-down, including clicks on other controls.
    func cancelMouseSequence() {
        if isDraggingImage { NSCursor.pop(); isDraggingImage = false }
        ownsMouseSequence = false
        mouseStartedOnImage = false
    }

    private func acceptsCanvasClick(at point: NSPoint) -> Bool {
        guard bounds.contains(point), onShouldBeginMouseSequence?(point) != false else { return false }
        if let content = window?.contentView {
            let hitPoint = content.superview.map { convert(point, to: $0) } ?? convert(point, to: nil)
            guard content.hitTest(hitPoint) === self else { return false }
        }
        return true
    }

    /// PDF hit testing uses the exact displayed page, including the in-flight
    /// zoom/rotation transform. The result has the page's lower-left origin.
    func documentPoint(at point: NSPoint) -> CGPoint? {
        guard let page = documentPage, let photo, let rootLayer = layer else { return nil }
        let content: CALayer, root: CALayer
        if let shownContent = photo.content.presentation(), let shownRoot = rootLayer.presentation() {
            content = shownContent; root = shownRoot
        } else { content = photo.content; root = rootLayer }
        let local = content.convert(point, from: root)
        let rect = content.bounds
        guard rect.width > 0, rect.height > 0, rect.contains(local) else { return nil }
        return CGPoint(x: (local.x - rect.minX) / rect.width * page.size.width,
                       y: (local.y - rect.minY) / rect.height * page.size.height)
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        cancelMouseSequence()
        let point = convert(event.locationInWindow, from: nil)
        guard acceptsCanvasClick(at: point) else { return nil }
        window?.makeFirstResponder(self)
        onInteraction?()
        return onContextMenu?(point)
    }

    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.control) {
            if let menu = menu(for: event) { NSMenu.popUpContextMenu(menu, with: event, for: self) }
            return
        }
        cancelMouseSequence()
        let point = convert(event.locationInWindow, from: nil)
        guard acceptsCanvasClick(at: point) else { return }
        ownsMouseSequence = true
        window?.makeFirstResponder(self)
        onInteraction?()
        mouseDownPoint = point
        mouseDownPan = pan
        mouseStartedOnImage = hasMedia && displayedImageRect.contains(mouseDownPoint)
        isDraggingImage = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard ownsMouseSequence, mouseStartedOnImage else { return }
        let point = convert(event.locationInWindow, from: nil)
        let movement = NSPoint(x: point.x - mouseDownPoint.x, y: point.y - mouseDownPoint.y)
        if !isDraggingImage, hypot(movement.x, movement.y) > 4 {
            takeOverPresentation()
            mouseDownPan = pan
            isDraggingImage = true
            NSCursor.closedHand.push()
        }
        if isDraggingImage {
            pan = NSPoint(x: mouseDownPan.x + movement.x, y: mouseDownPan.y + movement.y)
            clampPan()
            applyGeometry(animated: false, preserveRotation: true)
            needsDisplay = true
            onInteraction?()
        }
    }

    override func mouseUp(with event: NSEvent) {
        guard ownsMouseSequence else { return }
        ownsMouseSequence = false
        defer { mouseStartedOnImage = false }
        if isDraggingImage {
            NSCursor.pop()
            isDraggingImage = false
            window?.invalidateCursorRects(for: self)
            return
        }
        guard event.clickCount == 1 else { return }
        let point = convert(event.locationInWindow, from: nil)
        guard acceptsCanvasClick(at: point), hypot(point.x - mouseDownPoint.x, point.y - mouseDownPoint.y) <= 4 else { return }
        if mouseStartedOnImage {
            toggleActualSize(at: point)
        } else if hasMedia, !displayedImageRect.contains(point) {
            onBackgroundClick?()
        }
    }

    override func scrollWheel(with event: NSEvent) {
        guard hasMedia else { return }
        onInteraction?()
        let modified = !event.modifierFlags.intersection([.control, .command]).isEmpty
        let navigate = wheelNavigates != modified
        if navigate {
            let delta = abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) ? event.scrollingDeltaX : event.scrollingDeltaY
            if wheelNavigationAccumulation * delta < 0 { wheelNavigationAccumulation = 0 }
            wheelNavigationAccumulation += delta
            let threshold: CGFloat = event.hasPreciseScrollingDeltas ? 24 : 1
            if abs(wheelNavigationAccumulation) >= threshold, event.timestamp - lastWheelNavigation > 0.22 {
                onNavigate?(wheelNavigationAccumulation > 0 ? -1 : 1)
                wheelNavigationAccumulation = 0
                lastWheelNavigation = event.timestamp
            }
        } else {
            let delta = event.scrollingDeltaY
            guard abs(delta) > 0.001 else { return }
            let exponent = Double(delta) * (event.hasPreciseScrollingDeltas ? 0.012 : 0.10)
            zoomBy(exp(max(-1, min(1, exponent))), at: convert(event.locationInWindow, from: nil))
        }
    }

    override func magnify(with event: NSEvent) {
        onInteraction?()
        guard hasMedia else { return }
        if event.phase == .began || photo?.container.animation(forKey: "zoom") != nil || photo?.container.animation(forKey: "pan") != nil {
            takeOverPresentation()
        }
        setZoom(zoom * max(0.05, 1 + Double(event.magnification)),
                at: convert(event.locationInWindow, from: nil), animated: false)
    }

    override func swipe(with event: NSEvent) {
        onInteraction?()
        let delta = event.deltaX != 0 ? event.deltaX : event.deltaY
        if delta != 0 { onNavigate?(delta > 0 ? -1 : 1) }
    }

    override func keyDown(with event: NSEvent) {
        onInteraction?()
        if onKey?(event) == true { return }
        switch event.keyCode {
        case 123: onNavigate?(-1)
        case 124: onNavigate?(1)
        default: super.keyDown(with: event)
        }
    }

    private func droppedURLs(from sender: NSDraggingInfo) -> [URL] {
        let objects = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self],
                                                            options: [.urlReadingFileURLsOnly: true]) ?? []
        return objects.compactMap { ($0 as? NSURL).map { $0 as URL } }
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        isDropTarget = !droppedURLs(from: sender).isEmpty
        needsDisplay = true
        return isDropTarget ? .copy : []
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        isDropTarget ? .copy : []
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        isDropTarget = false
        needsDisplay = true
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        isDropTarget = false
        needsDisplay = true
        let urls = droppedURLs(from: sender)
        guard !urls.isEmpty else { return false }
        onOpen?(urls)
        return true
    }
}
