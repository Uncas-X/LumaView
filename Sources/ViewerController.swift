import AppKit
import UniformTypeIdentifiers
import QuartzCore
import AVFoundation

/// Keep time updates from moving the thumb while AppKit tracks a drag.
final class PlaybackSlider: NSSlider {
    var onTrackingChanged: ((Bool) -> Void)?
    private(set) var isTracking = false
    override func mouseDown(with event: NSEvent) {
        isTracking = true; onTrackingChanged?(true)
        super.mouseDown(with: event)
        isTracking = false; onTrackingChanged?(false)
    }
}

final class ViewerWindow: NSWindow {
    var preparePointerDown: ((NSEvent) -> Void)?
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown { preparePointerDown?(event) }
        super.sendEvent(event)
    }
}

final class GlassBackdrop: NSVisualEffectView {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

final class SurfaceView: NSView {
    var moved: (() -> Void)?
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.activeInKeyWindow, .mouseMoved, .inVisibleRect], owner: self))
    }
    override func mouseMoved(with event: NSEvent) { moved?() }
}

/// Chrome owns its mouse sequence, including releases over labels and empty panel space.
final class ChromeView: NSView {
    var onInteraction: (() -> Void)?
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) { onInteraction?() }
    override func mouseUp(with event: NSEvent) {}
    override func mouseDragged(with event: NSEvent) {}
}

final class Filmstrip: NSView {
    var items: [ImageItem] = [] {
        didSet {
            generation &+= 1
            pending.values.forEach { $0.request?.cancel() }
            pending.removeAll(); failed.removeAll(); cache.removeAllObjects()
            visibleURLs.removeAll(); visibleImages.removeAll()
            updateVisibleThumbnails(); needsDisplay = true
        }
    }
    var selected = 0 { didSet { updateVisibleThumbnails(); needsDisplay = true } }
    var keyboardFocused = true { didSet { needsDisplay = true } }
    var onSelect: ((Int) -> Void)?
    var onInteraction: (() -> Void)?
    let loader: ImageLoader
    // NSCache is only a reusable offscreen cache. Keep each displayed image alive
    // independently, so memory-pressure eviction cannot erase visible thumbnails.
    private let cache = NSCache<NSURL, NSImage>()
    private var visibleImages: [URL: NSImage] = [:]
    private var visibleURLs = Set<URL>()
    private final class PendingThumbnail { var request: ThumbnailRequest? }
    private var pending: [URL: PendingThumbnail] = [:]
    private var failed = Set<URL>()
    private var generation: UInt = 0
    private var wheelTime = 0.0
    init(loader: ImageLoader) { self.loader = loader; super.init(frame: .zero); cache.countLimit = 120 }
    required init?(coder: NSCoder) { fatalError() }
    deinit { pending.values.forEach { $0.request?.cancel() } }
    private var firstIndex: Int { max(0, min(selected - capacity / 2, items.count - capacity)) }
    private var capacity: Int { max(1, Int((bounds.width - 24) / 72)) }
    private var startX: CGFloat { (bounds.width - CGFloat(min(capacity, items.count)) * 72) / 2 }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        updateVisibleThumbnails()
    }
    override func setBoundsSize(_ newSize: NSSize) {
        super.setBoundsSize(newSize)
        updateVisibleThumbnails()
    }
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        updateVisibleThumbnails()
    }

    /// Schedule on viewport changes, never from draw(). A completion causes one
    /// repaint, not a fresh request if a discardable cache has just been purged.
    private func updateVisibleThumbnails() {
        let indexes = firstIndex..<min(items.count, firstIndex + capacity)
        let urls = indexes.map { items[$0].url }
        let nextVisible = Set(urls)
        for url in Array(pending.keys) where !nextVisible.contains(url) {
            pending.removeValue(forKey: url)?.request?.cancel()
        }
        visibleImages = visibleImages.filter { nextVisible.contains($0.key) }
        // Failed files can retry when the user comes back, but never on every
        // repaint while staying in the same viewport.
        failed.formIntersection(nextVisible)
        visibleURLs = nextVisible
        let epoch = generation
        for url in urls where visibleImages[url] == nil && pending[url] == nil && !failed.contains(url) {
            if let image = cache.object(forKey: url as NSURL) {
                visibleImages[url] = image
                continue
            }
            let entry = PendingThumbnail()
            pending[url] = entry
            entry.request = loader.thumbnail(url) { [weak self, weak entry] image in
                guard let self, let entry, self.generation == epoch,
                      self.pending[url] === entry, self.visibleURLs.contains(url) else { return }
                self.pending.removeValue(forKey: url)
                if let image {
                    self.visibleImages[url] = image
                    self.cache.setObject(image, forKey: url as NSURL)
                } else {
                    self.failed.insert(url)
                }
                self.needsDisplay = true
            }
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        guard !items.isEmpty else { return }
        for index in firstIndex..<min(items.count, firstIndex + capacity) {
            let rect = NSRect(x: startX + CGFloat(index - firstIndex) * 72 + 3, y: 9, width: 64, height: 56)
            NSColor(white: 1, alpha: index == selected ? 0.13 : 0.045).setFill()
            NSBezierPath(roundedRect: rect, xRadius: 7, yRadius: 7).fill()
            let item = items[index]
            if let image = visibleImages[item.url] {
                let size = image.size
                let ratio = min(54 / max(1, size.width), 44 / max(1, size.height))
                let target = NSRect(x: rect.midX - size.width * ratio / 2, y: rect.midY - size.height * ratio / 2,
                                    width: size.width * ratio, height: size.height * ratio)
                image.draw(in: target)
            } else {
                let symbol = item.isAudio ? "music.note" : (item.isVideo ? "video" : "photo")
                NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?
                    .draw(in: NSRect(x: rect.midX - 11, y: rect.midY - 9, width: 22, height: 18),
                          from: .zero, operation: .sourceOver, fraction: 0.25)
            }
            if index == selected {
                (keyboardFocused ? NSColor(calibratedRed: 0.97, green: 0.72, blue: 0.38, alpha: 1) : NSColor(white: 0.58, alpha: 0.75)).setStroke()
                let path = NSBezierPath(roundedRect: rect.insetBy(dx: -1, dy: -1), xRadius: 8, yRadius: 8)
                path.lineWidth = 2; path.stroke()
            }
            if item.isTimeBased {
                let time = loader.videoDuration(for: item.url).map { Self.timeText($0) } ?? "–:––"
                let text = "▶ " + time
                let attributes: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .medium), .foregroundColor: NSColor.white]
                let size = (text as NSString).size(withAttributes: attributes)
                let badge = NSRect(x: rect.maxX - size.width - 6, y: rect.minY + 3, width: size.width + 4, height: 13)
                NSColor.black.withAlphaComponent(0.75).setFill()
                NSBezierPath(roundedRect: badge, xRadius: 3, yRadius: 3).fill()
                (text as NSString).draw(at: NSPoint(x: badge.minX + 2, y: badge.minY + 1), withAttributes: attributes)
            }
        }
    }
    static func timeText(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let value = Int(min(seconds, 359_999))
        return value >= 3600 ? String(format: "%d:%02d:%02d", value / 3600, value / 60 % 60, value % 60)
            : String(format: "%d:%02d", value / 60, value % 60)
    }
    override func mouseDown(with event: NSEvent) {
        onInteraction?()
        let p = convert(event.locationInWindow, from: nil)
        let offset = Int(floor((p.x - startX) / 72))
        if offset >= 0 && offset < capacity {
            let index = firstIndex + offset
            if items.indices.contains(index) { onSelect?(index) }
        }
    }
    override func mouseUp(with event: NSEvent) {}
    override func mouseDragged(with event: NSEvent) {}
    override func scrollWheel(with event: NSEvent) {
        onInteraction?()
        guard event.timestamp - wheelTime > 0.085 else { return }
        let delta = abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) ? event.scrollingDeltaX : -event.scrollingDeltaY
        if abs(delta) > 0.25 { wheelTime = event.timestamp; onSelect?(max(0, min(items.count - 1, selected + (delta > 0 ? 1 : -1)))) }
    }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

enum ViewerNavigationFocus { case files, pages }

final class ViewerController: NSWindowController, NSWindowDelegate, NSMenuItemValidation {
    let loader = ImageLoader()
    let canvas = PhotoCanvas(frame: .zero)
    let root = SurfaceView(frame: .zero)
    let backdrop = GlassBackdrop(frame: .zero)
    let top = ChromeView()
    let dock = ChromeView()
    let infoPanel = ChromeView()
    let fileLabel = NSTextField(labelWithString: "LumaView")
    let detailLabel = NSTextField(labelWithString: "轻盈看图 · 熟悉的操作")
    let countLabel = NSTextField(labelWithString: "")
    let zoomLabel = NSTextField(labelWithString: "适合")
    let toast = NSTextField(labelWithString: "")
    let infoText = NSTextField(wrappingLabelWithString: "")
    let openButton = NSButton(title: "打开图片、音视频或文件夹", target: nil, action: nil)
    let videoSeekSlider = PlaybackSlider(value: 0, minValue: 0, maxValue: 1, target: nil, action: nil)
    let videoVolumeSlider = PlaybackSlider(value: 0.75, minValue: 0, maxValue: 1, target: nil, action: nil)
    let videoTimeLabel = NSTextField(labelWithString: "0:00 / 0:00")
    let pageStrip = DocumentFilmstrip(frame: .zero)
    let pageSeekSlider = PlaybackSlider(value: 1, minValue: 1, maxValue: 1, target: nil, action: nil)
    let pageCountLabel = NSTextField(labelWithString: "")
    lazy var strip = Filmstrip(loader: loader)
    var buttons: [String: NSButton] = [:]
    private(set) var items: [ImageItem] = []
    private(set) var selectedIndex = 0
    private(set) var loaded: LoadedImage?
    private(set) var video: VideoSession?
    private(set) var documentMedia: DocumentMedia?
    private(set) var documentPage: DocumentPage?
    private(set) var selectedPageIndex = 0
    private(set) var navigationFocus: ViewerNavigationFocus = .files
    private var pageGeneration = 0
    lazy var contextActions: CanvasContextActions = {
        let actions = CanvasContextActions(viewer: self)
        actions.onMessage = { [weak self] message in self?.showToast(message, duration: 3) }
        return actions
    }()
    private var pageByURL: [URL: Int] = [:]
    private var languagePreferences: LanguagePreferencesController?
    private var languageObserver: NSObjectProtocol?
    private var buttonTooltipKeys: [String: String] = [:]
    private var videoPrepared = false
    private var videoLoadTimeout: DispatchWorkItem?
    private weak var scrubbingSession: VideoSession?
    private var resumeAfterScrubbing = false
    private var videoVolume: Float = 0.75
    private var videoMuted = false
    private(set) var isPlaying = false
    private var defaultViewerPreferences: DefaultViewerPreferencesController?
    var sort: ImageSort = .name
    var looping = true
    var slideInterval = 3.0
    var showFilmstrip = true
    var closeOnBackground = true
    private var generation = 0
    private var openGeneration = 0
    private var slideTimer: Timer?
    private var animationTimer: Timer?
    private var animationFrame = 0
    private let animationQueue = DispatchQueue(label: "LumaView.Animation", qos: .userInitiated)
    private var hideTimer: Timer?
    private var toastTimer: Timer?
    private var infoVisible = false
    private var scanInProgress = false
    private var rotationByURL: [URL: Int] = [:]
    private var windowFadeTimer: Timer?
    private var visibilityGeneration = 0
    private var loadingToast: DispatchWorkItem?
    private var loadingToastGeneration = 0
    private var closeAfterFullscreen = false
    private var chromeTargets: [ObjectIdentifier: Bool] = [:]
    private var chromeGenerations: [ObjectIdentifier: Int] = [:]
    private(set) var isClosing = false
    private(set) var fullScreenTransitioning = false
    private var allowsTransitions: Bool { canvas.animationsEnabled && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }
    var currentURL: URL? { items.indices.contains(selectedIndex) ? items[selectedIndex].url : nil }
    private var isTimeBasedSelected: Bool { items.indices.contains(selectedIndex) && items[selectedIndex].isTimeBased }
    private var mediaReady: Bool { loaded != nil || videoPrepared || documentPage != nil }
    var showsDocumentNavigation: Bool {
        guard let document = documentMedia else { return false }
        return document.pageCount > 1 || ["pdf", "ai"].contains(document.url.pathExtension.lowercased())
    }

    init() {
        let size = NSSize(width: 1100, height: 760)
        let window = ViewerWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView], backing: .buffered, defer: false)
        super.init(window: window)
        window.title = "LumaView"
        window.titleVisibility = .hidden; window.titlebarAppearsTransparent = true
        window.backgroundColor = .clear; window.isOpaque = false; window.hasShadow = true
        window.minSize = NSSize(width: 800, height: 580)
        window.collectionBehavior = [.fullScreenPrimary]
        window.isReleasedWhenClosed = false
        window.animationBehavior = .none
        window.acceptsMouseMovedEvents = true
        window.delegate = self
        window.appearance = NSAppearance(named: .darkAqua)
        for kind in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] { window.standardWindowButton(kind)?.isHidden = true }
        window.contentView = root
        root.autoresizingMask = [.width, .height]
        backdrop.material = .hudWindow
        backdrop.blendingMode = .behindWindow
        backdrop.state = .active
        backdrop.autoresizingMask = [.width, .height]
        backdrop.frame = root.bounds
        root.addSubview(backdrop)
        canvas.autoresizingMask = [.width, .height]; canvas.frame = root.bounds
        root.addSubview(canvas)
        buildChrome()
        window.preparePointerDown = { [weak self] event in self?.preparePointerDown(event) }
        canvas.onBackgroundModeChanged = { [weak self] in self?.updateBackdrop() }
        canvas.onShouldBeginMouseSequence = { [weak self] point in
            guard let self else { return false }
            return !self.isChromeRegion(self.root.convert(point, from: self.canvas))
        }
        root.moved = { [weak self] in self?.revealChrome() }
        canvas.onNavigate = { [weak self] delta in self?.navigateFocused(delta) }
        canvas.onInteraction = { [weak self] in self?.revealChrome() }
        canvas.onBackgroundClick = { [weak self] in
            guard let self, self.closeOnBackground, !self.items.isEmpty else { return }
            self.closeViewer()
        }
        canvas.onOpen = { [weak self] urls in self?.open(urls) }
        canvas.onZoomChanged = { [weak self] zoom in self?.updateZoom(zoom) }
        canvas.onKey = { [weak self] event in self?.handleKey(event) ?? false }
        canvas.onContextMenu = { [weak self] point in self?.contextActions.menu(at: point) }
        strip.onSelect = { [weak self] index in
            self?.focusFiles(); self?.select(index)
        }
        pageStrip.onSelect = { [weak self] index in self?.focusPages(); self?.selectPage(index) }
        pageStrip.onInteraction = { [weak self] in self?.revealChrome() }
        strip.onInteraction = { [weak self] in self?.revealChrome() }
        for panel in [top, dock, infoPanel] {
            panel.onInteraction = { [weak self] in self?.revealChrome() }
        }
        restorePreferences()
        updateBackdrop()
        layoutChrome()
        window.center()
        refreshLanguage()
        languageObserver = NotificationCenter.default.addObserver(forName: L10n.languageDidChange, object: nil, queue: .main) { [weak self] _ in self?.refreshLanguage() }
    }
    deinit { if let languageObserver { NotificationCenter.default.removeObserver(languageObserver) } }
    required init?(coder: NSCoder) { fatalError() }

    private func updateBackdrop() { backdrop.isHidden = canvas.backgroundMode != .translucent }

    private func isChromeRegion(_ point: NSPoint) -> Bool {
        top.frame.contains(point) || (!items.isEmpty && dock.frame.contains(point))
            || (infoVisible && infoPanel.frame.contains(point))
    }

    private func preparePointerDown(_ event: NSEvent) {
        canvas.cancelMouseSequence()
        guard !isClosing else { return }
        let point = root.convert(event.locationInWindow, from: nil)
        guard isChromeRegion(point) else { return }
        revealChrome()
        // Resolve hit testing before AppKit dispatches the press. A fading panel
        // can otherwise have alpha zero while its controls still appear on screen.
        if top.frame.contains(point) { setVisible(top, true, animated: false) }
        if !items.isEmpty && dock.frame.contains(point) { setVisible(dock, true, animated: false) }
        if infoVisible && infoPanel.frame.contains(point) { setVisible(infoPanel, true, animated: false) }
    }

    private func panelStyle(_ view: NSView, radius: CGFloat = 18) {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(calibratedRed: 0.105, green: 0.11, blue: 0.12, alpha: 0.97).cgColor
        view.layer?.cornerRadius = radius
        view.layer?.borderColor = NSColor(white: 1, alpha: 0.12).cgColor
        view.layer?.borderWidth = 0.5
    }
    private func labelStyle(_ label: NSTextField, size: CGFloat, color: NSColor = .white, weight: NSFont.Weight = .regular) {
        label.font = .systemFont(ofSize: size, weight: weight); label.textColor = color
        label.lineBreakMode = .byTruncatingMiddle
    }
    @discardableResult private func button(_ id: String, symbol: String, tip: String, target: NSView, action: Selector) -> NSButton {
        let b = NSButton(image: NSImage(systemSymbolName: symbol, accessibilityDescription: L10n.tr(tip)) ?? NSImage(), target: self, action: action)
        b.isBordered = false; b.bezelStyle = .regularSquare; b.contentTintColor = NSColor(white: 0.92, alpha: 1)
        buttonTooltipKeys[id] = tip
        b.toolTip = L10n.tr(tip); b.setAccessibilityLabel(L10n.tr(tip)); b.imageScaling = .scaleProportionallyDown
        b.focusRingType = .none; target.addSubview(b); buttons[id] = b
        return b
    }
    private func buildChrome() {
        root.addSubview(top); root.addSubview(dock); root.addSubview(infoPanel)
        panelStyle(dock); panelStyle(infoPanel)
        panelStyle(top, radius: 12)
        top.addSubview(fileLabel); top.addSubview(detailLabel); top.addSubview(countLabel)
        labelStyle(fileLabel, size: 13, weight: .semibold)
        labelStyle(detailLabel, size: 10, color: NSColor(white: 0.66, alpha: 1))
        labelStyle(countLabel, size: 11, color: NSColor(white: 0.72, alpha: 1))
        countLabel.alignment = .right
        button("topOpen", symbol: "folder", tip: "打开图片、音视频或文件夹 ⌘O", target: top, action: #selector(openDialog))
        button("close", symbol: "xmark", tip: "关闭 Esc", target: top, action: #selector(closeViewer))
        button("minimize", symbol: "minus", tip: "最小化 ⌘M", target: top, action: #selector(minimize))
        dock.addSubview(strip)
        button("previous", symbol: "chevron.left", tip: "上一文件 ← / J", target: dock, action: #selector(previous))
        button("play", symbol: "play.rectangle.on.rectangle", tip: "幻灯片 / 连续播放 ⌘4", target: dock, action: #selector(toggleSlideshow))
        button("next", symbol: "chevron.right", tip: "下一文件 → / K", target: dock, action: #selector(nextImage))
        button("zoomOut", symbol: "minus.magnifyingglass", tip: "缩小 − / Page Down", target: dock, action: #selector(zoomOut))
        button("zoomIn", symbol: "plus.magnifyingglass", tip: "放大 + / Page Up", target: dock, action: #selector(zoomIn))
        button("fit", symbol: "arrow.up.left.and.arrow.down.right", tip: "适合窗口 0", target: dock, action: #selector(fit))
        button("rotate", symbol: "rotate.right", tip: "顺时针旋转 ⌘R / Ctrl+R", target: dock, action: #selector(rotateRight))
        button("background", symbol: "circle.lefthalf.filled", tip: "切换透明 / 深色 / 浅色背景 空格", target: dock, action: #selector(toggleBackground))
        button("info", symbol: "info.circle", tip: "文件信息 ⌘I / I", target: dock, action: #selector(toggleInfo))
        button("fullscreen", symbol: "arrow.up.left.and.arrow.down.right.rectangle", tip: "全屏 F / F11", target: dock, action: #selector(toggleFullscreen))
        button("more", symbol: "ellipsis", tip: "更多选项 C", target: dock, action: #selector(showOptions))
        labelStyle(zoomLabel, size: 11, color: NSColor(white: 0.8, alpha: 1)); zoomLabel.alignment = .center; dock.addSubview(zoomLabel)
        dock.addSubview(videoSeekSlider); dock.addSubview(videoVolumeSlider); dock.addSubview(videoTimeLabel)
        labelStyle(videoTimeLabel, size: 10, color: NSColor(white: 0.8, alpha: 1))
        videoTimeLabel.font = .monospacedDigitSystemFont(ofSize: 10, weight: .regular)
        videoSeekSlider.target = self; videoSeekSlider.action = #selector(seekVideo(_:)); videoSeekSlider.isContinuous = true
        videoSeekSlider.setAccessibilityLabel("视频进度"); videoSeekSlider.toolTip = "拖动跳转 · ⌥← / ⌥→ 后退 / 前进 5 秒"
        videoVolumeSlider.target = self; videoVolumeSlider.action = #selector(changeVideoVolume(_:)); videoVolumeSlider.isContinuous = true
        videoVolumeSlider.setAccessibilityLabel("视频音量"); videoVolumeSlider.toolTip = "音量"
        for slider in [videoSeekSlider, videoVolumeSlider] { slider.controlSize = .small; slider.focusRingType = .none }
        videoSeekSlider.onTrackingChanged = { [weak self] tracking in self?.trackVideoSeek(tracking) }
        videoVolumeSlider.onTrackingChanged = { [weak self] tracking in
            self?.revealChrome()
            if !tracking { self?.persistPreferences(); self?.window?.makeFirstResponder(self?.canvas) }
        }
        button("mute", symbol: "speaker.wave.2.fill", tip: "静音 / 恢复声音 M", target: dock, action: #selector(toggleVideoMute))
        button("mediaPlay", symbol: "play.fill", tip: "播放 / 暂停音视频 P", target: dock, action: #selector(togglePlayback))
        button("mediaStop", symbol: "stop.fill", tip: "停止音视频并返回开头 S", target: dock, action: #selector(stopPlayback))
        for view in [pageStrip, pageSeekSlider, pageCountLabel] { dock.addSubview(view) }
        labelStyle(pageCountLabel, size: 10, color: NSColor(white: 0.85, alpha: 1))
        pageCountLabel.font = .monospacedDigitSystemFont(ofSize: 10, weight: .medium)
        pageCountLabel.alignment = .right
        pageSeekSlider.target = self; pageSeekSlider.action = #selector(seekDocumentPage(_:))
        pageSeekSlider.isContinuous = true; pageSeekSlider.controlSize = .small; pageSeekSlider.focusRingType = .none
        pageSeekSlider.onTrackingChanged = { [weak self] tracking in
            self?.revealChrome()
            if !tracking { self?.updateDocumentControls(); self?.window?.makeFirstResponder(self?.canvas) }
        }
        infoPanel.addSubview(infoText)
        labelStyle(infoText, size: 12, color: NSColor(white: 0.88, alpha: 1)); infoText.isSelectable = true
        infoPanel.isHidden = true
        button("closeInfo", symbol: "xmark", tip: "关闭图片信息", target: infoPanel, action: #selector(toggleInfo))
        root.addSubview(openButton)
        openButton.target = self; openButton.action = #selector(openDialog)
        openButton.bezelStyle = .rounded; openButton.controlSize = .large
        openButton.font = .systemFont(ofSize: 13, weight: .semibold)
        openButton.bezelColor = NSColor(calibratedRed: 0.91, green: 0.65, blue: 0.32, alpha: 1)
        root.addSubview(toast)
        labelStyle(toast, size: 12); toast.alignment = .center
        panelStyle(toast, radius: 10); toast.isHidden = true
    }
    func layoutChrome() {
        let w = root.bounds.width, h = root.bounds.height
        backdrop.frame = root.bounds
        canvas.frame = root.bounds
        top.frame = NSRect(x: 18, y: h - 70, width: w - 36, height: 48)
        buttons["topOpen"]?.frame = NSRect(x: 10, y: 8, width: 34, height: 32)
        fileLabel.frame = NSRect(x: 52, y: 25, width: max(100, w - 280), height: 17)
        detailLabel.frame = NSRect(x: 52, y: 8, width: max(100, w - 280), height: 14)
        countLabel.frame = NSRect(x: top.bounds.width - 184, y: 17, width: 84, height: 16)
        buttons["minimize"]?.frame = NSRect(x: top.bounds.width - 82, y: 8, width: 32, height: 32)
        buttons["close"]?.frame = NSRect(x: top.bounds.width - 42, y: 8, width: 32, height: 32)
        let videoHeight: CGFloat = isTimeBasedSelected ? 40 : (showsDocumentNavigation ? 58 : 0)
        let dw = min(860, w - 72), dh: CGFloat = (showFilmstrip ? 132 : 58) + videoHeight
        dock.frame = NSRect(x: (w - dw) / 2, y: 22, width: dw, height: dh)
        canvas.additionalBottomInset = videoHeight
        strip.frame = NSRect(x: 12, y: 56, width: dw - 24, height: 72); strip.isHidden = !showFilmstrip
        let transportY: CGFloat = showFilmstrip ? 132 : 60
        buttons["mediaPlay"]?.frame = NSRect(x: 18, y: transportY - 3, width: 28, height: 28)
        buttons["mediaStop"]?.frame = NSRect(x: 52, y: transportY - 3, width: 28, height: 28)
        videoTimeLabel.frame = NSRect(x: 90, y: transportY + 3, width: 116, height: 16)
        videoSeekSlider.frame = NSRect(x: 212, y: transportY + 1, width: max(140, dw - 365), height: 20)
        buttons["mute"]?.frame = NSRect(x: dw - 145, y: transportY - 3, width: 28, height: 28)
        videoVolumeSlider.frame = NSRect(x: dw - 110, y: transportY + 1, width: 84, height: 20)
        let videoControls: [NSView?] = [videoSeekSlider, videoVolumeSlider, videoTimeLabel, buttons["mute"], buttons["mediaPlay"], buttons["mediaStop"]]
        for view in videoControls.compactMap({ $0 }) { view.isHidden = !isTimeBasedSelected }
        let pageY: CGFloat = showFilmstrip ? 132 : 60
        pageStrip.frame = NSRect(x: 14, y: pageY - 1, width: max(160, dw - 314), height: 48)
        pageSeekSlider.frame = NSRect(x: dw - 290, y: pageY + 14, width: 166, height: 20)
        pageCountLabel.frame = NSRect(x: dw - 116, y: pageY + 17, width: 101, height: 16)
        for view in [pageStrip, pageSeekSlider, pageCountLabel] { view.isHidden = !showsDocumentNavigation }
        let ids = ["previous", "play", "next", "zoomOut", "zoomIn", "fit", "rotate", "background", "info", "fullscreen", "more"]
        let spacing: CGFloat = min(60, (dw - 72) / 11)
        let start = (dw - spacing * 11 - 58) / 2
        for (i, id) in ids.enumerated() {
            let gap: CGFloat = i >= 5 ? 58 : 0
            buttons[id]?.frame = NSRect(x: start + CGFloat(i) * spacing + gap, y: 11, width: 36, height: 36)
        }
        zoomLabel.frame = NSRect(x: start + 5 * spacing - 6, y: 23, width: 58, height: 15)
        infoPanel.frame = NSRect(x: w - 320, y: max(170, h - 445), width: 298, height: min(350, h - 250))
        infoText.frame = infoPanel.bounds.insetBy(dx: 22, dy: 25)
        buttons["closeInfo"]?.frame = NSRect(x: 259, y: infoPanel.bounds.height - 34, width: 26, height: 26)
        openButton.frame = NSRect(x: w / 2 - 100, y: h / 2 - 120, width: 200, height: 38)
        toast.frame = NSRect(x: w / 2 - 240, y: max(174, dh + 48), width: 480, height: 28)
    }
    func windowDidResize(_ notification: Notification) { layoutChrome() }
    func windowDidChangeScreen(_ notification: Notification) { if canvas.isFit { canvas.fit() } }
    func windowWillEnterFullScreen(_ notification: Notification) { fullScreenTransitioning = true }
    func windowWillExitFullScreen(_ notification: Notification) { fullScreenTransitioning = true }
    func windowDidEnterFullScreen(_ notification: Notification) { finishFullscreenTransition() }
    func windowDidExitFullScreen(_ notification: Notification) { finishFullscreenTransition() }
    func windowDidFailToEnterFullScreen(_ window: NSWindow) { finishFullscreenTransition() }
    func windowDidFailToExitFullScreen(_ window: NSWindow) { finishFullscreenTransition() }
    private func finishFullscreenTransition() {
        fullScreenTransitioning = false; layoutChrome()
        if closeAfterFullscreen && isClosing { closeAfterFullscreen = false; fadeAndClose() }
    }
    func windowShouldClose(_ sender: NSWindow) -> Bool { closeViewer(); return false }
    func windowWillClose(_ notification: Notification) {
        contextActions.invalidate()
        stopTimers(); loader.cancelPending(); generation += 1; openGeneration += 1
        pageGeneration += 1
        documentLoadRequest?.cancel(); documentLoadRequest = nil
        documentMedia?.cancelPendingPageLoads()
        stopVideo(); canvas.clearImage()
        windowFadeTimer?.invalidate(); windowFadeTimer = nil
        isClosing = false; scanInProgress = false
    }
    func show() {
        guard let window else { return }
        let shouldFade = !window.isVisible || isClosing || window.alphaValue < 0.999
        visibilityGeneration += 1
        isClosing = false; closeAfterFullscreen = false
        window.ignoresMouseEvents = false
        if !window.isVisible { window.alphaValue = allowsTransitions ? 0 : 1 }
        showWindow(nil); window.makeKeyAndOrderFront(nil); window.makeFirstResponder(canvas)
        if shouldFade { fadeWindow(to: 1, duration: 0.20) }
        NSApp.activate(ignoringOtherApps: true)
        revealChrome()
        if let documentPage {
            if !canvas.hasMedia { canvas.setDocumentPage(documentPage); canvas.quarterTurns = currentURL.flatMap { rotationByURL[$0] } ?? 0 }
            if selectedPageIndex != documentPage.index { selectPage(selectedPageIndex) }
            else { updateDocumentControls() }
        }
        else if let loaded {
            if !canvas.hasMedia {
                canvas.setImage(loaded.image, pixelSize: loaded.pixelSize, quarterTurns: currentURL.flatMap { rotationByURL[$0] } ?? 0)
            }
            scheduleAnimation()
        }
        else if !items.isEmpty && !scanInProgress { select(selectedIndex) }
    }

    /// Only opacity changes on each tick; image transforms are GPU-composited in PhotoCanvas.
    private func fadeWindow(to target: CGFloat, duration: TimeInterval, completion: (() -> Void)? = nil) {
        windowFadeTimer?.invalidate(); windowFadeTimer = nil
        guard let window else { completion?(); return }
        guard allowsTransitions, abs(window.alphaValue - target) > 0.001 else {
            window.alphaValue = target; completion?(); return
        }
        let from = window.alphaValue, start = ProcessInfo.processInfo.systemUptime, token = visibilityGeneration
        let timer = Timer(timeInterval: 1.0 / 60, repeats: true) { [weak self, weak window] timer in
            guard let self, let window, token == self.visibilityGeneration else { timer.invalidate(); return }
            let t = min(1, (ProcessInfo.processInfo.systemUptime - start) / duration)
            let eased = 1 - pow(1 - t, 3)
            window.alphaValue = from + (target - from) * CGFloat(eased)
            if t >= 1 { timer.invalidate(); self.windowFadeTimer = nil; completion?() }
        }
        timer.tolerance = 0.002; windowFadeTimer = timer; RunLoop.main.add(timer, forMode: .common)
    }
    private func fadeAndClose() {
        let token = visibilityGeneration
        fadeWindow(to: 0, duration: 0.16) { [weak self] in
            guard let self, self.isClosing, token == self.visibilityGeneration else { return }
            self.window?.close()
        }
    }

    private func setVisible(_ view: NSView, _ visible: Bool, animated: Bool = true) {
        let id = ObjectIdentifier(view)
        if chromeTargets[id] == visible && animated { return }
        chromeTargets[id] = visible
        let token = (chromeGenerations[id] ?? 0) + 1; chromeGenerations[id] = token
        let useAnimation = animated && allowsTransitions && window?.isVisible == true
        guard useAnimation else {
            view.layer?.removeAnimation(forKey: "opacity")
            view.alphaValue = visible ? 1 : 0; view.isHidden = !visible
            return
        }
        if visible && view.isHidden { view.alphaValue = 0; view.isHidden = false }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = visible ? 0.14 : 0.20
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            view.animator().alphaValue = visible ? 1 : 0
        }, completionHandler: { [weak self, weak view] in
            guard let self, let view, self.chromeGenerations[id] == token else { return }
            view.isHidden = !visible
        })
    }

    func open(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        openGeneration += 1
        let request = openGeneration, chosenSort = sort
        generation += 1; loader.cancelPending(); animationTimer?.invalidate()
        stopVideo()
        stopSlideshow(); scanInProgress = true
        if items.isEmpty, let screen = window?.screen ?? NSScreen.main, window?.styleMask.contains(.fullScreen) == false {
            window?.setFrame(screen.visibleFrame, display: true, animate: window?.isVisible == true && allowsTransitions)
        }
        show()
        deferLoadingToast("正在读取文件列表…")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = Result { try ImageLibrary.collect(from: urls, sort: chosenSort) }
            DispatchQueue.main.async {
                guard let self, request == self.openGeneration else { return }
                self.scanInProgress = false; self.hideLoadingToast()
                switch result {
                case .success(let collection):
                    guard !collection.items.isEmpty else { self.showToast("这里没有可查看的图片、音频或视频", duration: 5); return }
                    self.items = collection.items; self.strip.items = collection.items
                    self.select(collection.selectedIndex)
                case .failure(let error): self.showToast(error.localizedDescription, duration: 6)
                }
            }
        }
    }
    func select(_ index: Int) {
        guard items.indices.contains(index), !isClosing else { return }
        contextActions.invalidate()
        loader.cancelPending()
        stopVideo(); slideTimer?.invalidate(); slideTimer = nil
        selectedIndex = index; strip.selected = index; generation += 1; pageGeneration += 1
        documentLoadRequest?.cancel(); documentLoadRequest = nil
        documentMedia?.cancelPendingPageLoads()
        documentMedia = nil; documentPage = nil; selectedPageIndex = 0
        pageStrip.document = nil; navigationFocus = .files
        let request = generation, item = items[index]
        animationTimer?.invalidate(); animationTimer = nil; animationFrame = 0
        loaded = nil; canvas.placeholderText = item.isTimeBased ? "正在准备音视频…" : "正在打开图片…"; canvas.beginImageLoading()
        layoutChrome(); updateChrome(); deferLoadingToast("正在打开…")
        if item.isTimeBased {
            openVideo(item, request: request)
            revealChrome()
            return
        }
        if MediaFormats.isVector(item.url) || ["tif", "tiff"].contains(item.url.pathExtension.lowercased()) {
            openDocument(item.url, request: request)
            revealChrome(); return
        }
        loader.load(item.url) { [weak self] result in
            guard let self, request == self.generation else { return }
            self.hideLoadingToast()
            switch result {
            case .success(let loaded):
                self.canvas.placeholderText = nil
                self.loaded = loaded
                self.canvas.setImage(loaded.image, pixelSize: loaded.pixelSize, quarterTurns: self.rotationByURL[item.url] ?? 0)
                self.updateChrome(); self.scheduleAnimation(); self.scheduleSlide()
                let adjacent = [index - 1, index + 1].filter { self.items.indices.contains($0) }.map { self.items[$0].url }
                self.loader.prefetch(adjacent)
            case .failure(let error):
                self.canvas.placeholderText = "图片暂时无法显示\n按 ← → 继续浏览，或 ⌘O 打开其他图片"
                self.canvas.setImage(nil, pixelSize: .zero)
                self.showToast(L10n.format("无法打开：%@", error.localizedDescription), duration: 8)
                self.detailLabel.stringValue = L10n.tr("图片无法解码，可继续浏览其他图片")
                self.scheduleSlide()
            }
        }
        revealChrome()
    }
    private var documentLoadRequest: ThumbnailRequest?
    private func openDocument(_ url: URL, request: Int) {
        canvas.placeholderText = L10n.tr("正在读取文档…")
        documentLoadRequest = DocumentMedia.load(url: url) { [weak self] result in
            guard let self, request == self.generation, !self.isClosing else { return }
            switch result {
            case .success(let document):
                self.documentMedia = document; self.pageStrip.document = document
                self.selectedPageIndex = max(0, min(document.pageCount - 1, self.pageByURL[url] ?? 0))
                self.layoutChrome(); self.selectPage(self.selectedPageIndex)
            case .failure(let error):
                self.hideLoadingToast()
                self.canvas.placeholderText = L10n.tr("没有可显示的页面")
                self.canvas.setImage(nil, pixelSize: .zero)
                self.updateChrome(); self.showToast(L10n.format("无法打开文档：%@", error.localizedDescription), duration: 8)
                self.scheduleSlide()
            }
        }
    }
    func selectPage(_ index: Int) {
        guard let document = documentMedia, index >= 0, index < document.pageCount, !isClosing else { return }
        contextActions.invalidate()
        pageGeneration += 1
        let request = pageGeneration, fileRequest = generation
        selectedPageIndex = index; pageStrip.selected = index
        updateDocumentControls(); canvas.beginImageLoading()
        deferLoadingToast(L10n.format("正在读取第 %d 页…", index + 1))
        let backing = window?.backingScaleFactor ?? 2
        let previewDimension = Int(ceil(max(canvas.bounds.width, canvas.bounds.height) * backing))
        document.loadPage(at: index, previewMaxPixelDimension: previewDimension) { [weak self, weak document] result in
            guard let self, let document, self.documentMedia === document, request == self.pageGeneration,
                  fileRequest == self.generation, !self.isClosing else { return }
            self.hideLoadingToast()
            switch result {
            case .success(let page):
                self.documentPage = page; self.pageByURL[document.url] = index
                self.canvas.setDocumentPage(page)
                self.canvas.quarterTurns = self.rotationByURL[document.url] ?? 0
                self.contextActions.preparePDF(page: page)
                self.updateChrome(); self.scheduleSlide()
            case .failure(let error):
                if let page = self.documentPage {
                    self.selectedPageIndex = page.index; self.contextActions.preparePDF(page: page)
                }
                self.updateDocumentControls()
                self.showToast(L10n.format("无法显示这一页：%@", error.localizedDescription), duration: 6)
            }
        }
        revealChrome()
    }
    @objc func seekDocumentPage(_ sender: NSSlider) {
        focusPages()
        let index = Int(sender.doubleValue.rounded()) - 1
        if index != selectedPageIndex { selectPage(index) }
    }
    @objc func focusPages() {
        guard showsDocumentNavigation else { return }
        navigationFocus = .pages; updateDocumentControls(); revealChrome(); window?.makeFirstResponder(canvas)
    }
    @objc func focusFiles() {
        navigationFocus = .files; updateDocumentControls(); revealChrome(); window?.makeFirstResponder(canvas)
    }
    func navigateFocused(_ delta: Int) {
        if navigationFocus == .pages, let document = documentMedia, showsDocumentNavigation {
            let target = max(0, min(document.pageCount - 1, selectedPageIndex + delta))
            if target != selectedPageIndex { selectPage(target) } else { revealChrome() }
        } else { navigate(delta) }
    }
    private func updateDocumentControls() {
        let count = documentMedia?.pageCount ?? 0
        pageSeekSlider.maxValue = Double(max(1, count)); pageSeekSlider.isEnabled = count > 1
        if !pageSeekSlider.isTracking { pageSeekSlider.doubleValue = Double(selectedPageIndex + 1) }
        pageCountLabel.stringValue = count > 0 ? "\(selectedPageIndex + 1) / \(count)" : ""
        pageCountLabel.setAccessibilityLabel(L10n.format("第 %d / %d 页", selectedPageIndex + 1, count))
        pageSeekSlider.setAccessibilityLabel(L10n.tr("页码"))
        pageStrip.selected = selectedPageIndex; pageStrip.keyboardFocused = navigationFocus == .pages
        pageStrip.setAccessibilityLabel(L10n.tr("内页缩略图"))
        pageStrip.toolTip = L10n.tr("内页焦点：← → 切换页面")
        strip.toolTip = L10n.tr("文件焦点：← → 切换文件")
        strip.keyboardFocused = navigationFocus == .files
        pageStrip.setAccessibilityValue(navigationFocus == .pages ? L10n.tr("当前焦点") : "")
        strip.setAccessibilityValue(navigationFocus == .files ? L10n.tr("当前焦点") : "")
    }
    private func openVideo(_ item: ImageItem, request: Int) {
        let session = VideoSession(url: item.url)
        video = session
        session.onPreparationProgress = { [weak self, weak session] message in
            guard let self, let session, self.video === session, self.generation == request else { return }
            self.canvas.placeholderText = message
            self.detailLabel.stringValue = message
            self.showToast(message, duration: 30)
        }
        session.prepare { [weak self, weak session] result in
            guard let self, let session, request == self.generation, self.video === session, !self.isClosing else { return }
            switch result {
            case .success: self.attachPreparedMedia(session, request: request)
            case .failure(let error): self.failVideo(error.localizedDescription)
            }
        }
    }
    private func attachPreparedMedia(_ session: VideoSession, request: Int) {
        session.player.volume = videoVolume; session.player.isMuted = videoMuted
        session.onUpdate = { [weak self, weak session] in
            guard let self, let session, self.video === session else { return }
            self.updateVideoControls()
        }
        session.onEnded = { [weak self, weak session] in
            guard let self, let session, self.video === session else { return }
            if self.isPlaying {
                if self.selectedIndex == self.items.count - 1 && !self.looping { self.stopSlideshow() }
                else { self.navigate(1) }
            }
            self.updateVideoControls(); self.revealChrome()
        }
        session.onFailure = { [weak self, weak session] message in
            guard let self, let session, self.video === session else { return }
            self.failVideo(message)
        }
        let ready: () -> Void = { [weak self, weak session] in
            guard let self, let session, self.video === session, request == self.generation, !self.isClosing else { return }
            self.videoLoadTimeout?.cancel(); self.videoLoadTimeout = nil
            self.videoPrepared = true; self.canvas.placeholderText = nil
            self.hideLoadingToast(); session.play(); self.updateChrome()
        }
        if session.isAudioOnly {
            canvas.onVideoReady = nil
            session.onAudioVisualChanged = { [weak self, weak session] in
                guard let self, let session, self.video === session, request == self.generation, !self.isClosing else { return }
                self.refreshAudioVisual(session)
            }
            refreshAudioVisual(session)
            ready()
        } else {
            // Only the first-frame stage has a short timeout. A long local conversion
            // must remain cancellable by navigation rather than expire after 20 seconds.
            let timeout = DispatchWorkItem { [weak self, weak session] in
                guard let self, let session, self.video === session, request == self.generation, !self.videoPrepared else { return }
                self.retryCurrentMediaWithCompatibility()
            }
            videoLoadTimeout?.cancel(); videoLoadTimeout = timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + 15, execute: timeout)
            canvas.onVideoReady = ready
            canvas.setVideo(player: session.player, size: session.pixelSize)
            canvas.quarterTurns = rotationByURL[session.url] ?? 0
        }
        updateChrome()
    }
    private func refreshAudioVisual(_ session: VideoSession) {
        if let cover = session.audioCover {
            canvas.setImage(cover, pixelSize: CGSize(width: cover.width, height: cover.height), reset: !videoPrepared)
        } else {
            canvas.setImage(AudioArtwork.make(for: session.url, waveform: session.audioWaveform), pixelSize: session.pixelSize, reset: !videoPrepared)
        }
        canvas.quarterTurns = rotationByURL[session.url] ?? 0
    }
    /// Rebuild the display attachment when a native item never yields a frame.
    func retryCurrentMediaWithCompatibility() {
        guard let session = video, !isClosing else { return }
        let request = generation
        videoLoadTimeout?.cancel(); videoLoadTimeout = nil
        videoPrepared = false
        canvas.onVideoReady = nil
        // The player survives fallback. A fresh layer prevents an earlier
        // one-shot readiness observation from consuming the replacement frame.
        canvas.clearImage()
        canvas.placeholderText = "正在准备兼容播放…"
        canvas.beginImageLoading(); updateChrome()
        session.retryWithCompatibility { [weak self, weak session] result in
            guard let self, let session, self.video === session, request == self.generation, !self.isClosing else { return }
            switch result {
            case .success: self.attachPreparedMedia(session, request: request)
            case .failure: self.failVideo("未能显示视频画面。此编码可能不受支持，或文件已损坏。")
            }
        }
    }
    private func failVideo(_ message: String) {
        stopVideo(); hideLoadingToast()
        canvas.placeholderText = "音视频暂时无法播放\n按 ← → 继续浏览，或 ⌘O 打开其他文件"
        canvas.setImage(nil, pixelSize: .zero)
        updateChrome()
        detailLabel.stringValue = L10n.tr("音视频无法播放，可能是暂不支持的编码或文件已损坏")
        showToast(message, duration: 8); scheduleSlide()
    }
    private func stopVideo() {
        canvas.onVideoReady = nil
        videoLoadTimeout?.cancel(); videoLoadTimeout = nil
        video?.dispose(); video = nil; videoPrepared = false
        scrubbingSession = nil; resumeAfterScrubbing = false
    }
    private func updateVideoControls() {
        let playing = videoPrepared && video?.isPlaying == true
        let label = L10n.tr(playing ? "暂停音视频" : "播放音视频")
        buttons["mediaPlay"]?.image = NSImage(systemSymbolName: playing ? "pause.fill" : "play.fill", accessibilityDescription: label)
        buttons["mediaPlay"]?.toolTip = label + " P"
        buttons["mediaPlay"]?.setAccessibilityLabel(label)
        buttons["mediaPlay"]?.contentTintColor = playing ? .systemOrange : .white
        buttons["mediaPlay"]?.isEnabled = videoPrepared
        buttons["mediaStop"]?.isEnabled = videoPrepared
        let slideshowLabel = L10n.tr(isPlaying ? "停止幻灯片 / 连续播放" : "开始幻灯片 / 连续播放")
        buttons["play"]?.image = NSImage(systemSymbolName: isPlaying ? "stop.rectangle" : "play.rectangle.on.rectangle", accessibilityDescription: slideshowLabel)
        buttons["play"]?.toolTip = slideshowLabel + " ⌘4"
        buttons["play"]?.setAccessibilityLabel(slideshowLabel)
        buttons["play"]?.contentTintColor = isPlaying ? .systemOrange : .white
        let duration = video?.duration ?? 0, position = video?.currentTime ?? 0
        videoSeekSlider.maxValue = max(0.01, duration)
        if !videoSeekSlider.isTracking { videoSeekSlider.doubleValue = position }
        videoSeekSlider.isEnabled = videoPrepared && duration > 0
        videoVolumeSlider.isEnabled = videoPrepared; buttons["mute"]?.isEnabled = videoPrepared
        videoVolumeSlider.doubleValue = Double(videoVolume)
        videoTimeLabel.stringValue = "\(Filmstrip.timeText(videoSeekSlider.isTracking ? videoSeekSlider.doubleValue : position)) / \(Filmstrip.timeText(duration))"
        let muted = videoMuted || videoVolume == 0
        buttons["mute"]?.image = NSImage(systemSymbolName: muted ? "speaker.slash.fill" : "speaker.wave.2.fill", accessibilityDescription: L10n.tr(muted ? "恢复声音" : "静音"))
    }
    private func trackVideoSeek(_ tracking: Bool) {
        revealChrome()
        if tracking {
            scrubbingSession = video; resumeAfterScrubbing = video?.isPlaying == true
            video?.pause()
        } else {
            if let session = scrubbingSession, session === video {
                session.seek(to: videoSeekSlider.doubleValue)
                if resumeAfterScrubbing { session.play() }
            }
            scrubbingSession = nil; resumeAfterScrubbing = false
            window?.makeFirstResponder(canvas)
        }
    }
    @objc func seekVideo(_ sender: NSSlider) {
        guard videoPrepared else { return }
        video?.seek(to: sender.doubleValue); revealChrome()
        videoTimeLabel.stringValue = "\(Filmstrip.timeText(sender.doubleValue)) / \(Filmstrip.timeText(video?.duration ?? 0))"
    }
    @objc func changeVideoVolume(_ sender: NSSlider) {
        videoVolume = Float(max(0, min(1, sender.doubleValue))); videoMuted = false
        video?.player.volume = videoVolume; video?.player.isMuted = false
        updateVideoControls(); revealChrome()
    }
    @objc func toggleVideoMute() {
        guard videoPrepared else { return }
        videoMuted.toggle(); video?.player.isMuted = videoMuted
        updateVideoControls(); persistPreferences(); revealChrome(); window?.makeFirstResponder(canvas)
    }
    @objc func togglePlayback() {
        guard let video, videoPrepared else { return }
        video.togglePlayback(); updateVideoControls(); revealChrome(); window?.makeFirstResponder(canvas)
    }
    @objc func stopPlayback() {
        guard let video, videoPrepared else { return }
        resumeAfterScrubbing = false
        video.pause(); video.seek(to: 0)
        updateVideoControls(); revealChrome(); window?.makeFirstResponder(canvas)
    }
    func navigate(_ delta: Int) {
        guard items.count > 1 else { return }
        let candidate = selectedIndex + delta
        let index = looping ? (candidate % items.count + items.count) % items.count : max(0, min(items.count - 1, candidate))
        if index != selectedIndex { select(index) } else { showToast(delta > 0 ? "已是最后一张" : "已是第一张") }
    }
    private func updateChrome() {
        fileLabel.stringValue = currentURL?.lastPathComponent ?? "LumaView"
        window?.title = currentURL.map { "\($0.lastPathComponent) — LumaView" } ?? "LumaView"
        if let document = documentMedia, let page = documentPage {
            detailLabel.stringValue = L10n.tr(document.format) + "  ·  " + L10n.format("第 %d / %d 页", page.index + 1, document.pageCount)
        } else if let loaded, let url = currentURL {
            detailLabel.stringValue = "\(Int(loaded.pixelSize.width)) × \(Int(loaded.pixelSize.height))  ·  \(url.deletingLastPathComponent().lastPathComponent)\(loaded.frameCount > 1 ? "  ·  " + L10n.tr("动图") : "")\(loaded.isDownsampledPreview ? "  ·  " + L10n.tr("大图预览") : "")"
        } else if let video, videoPrepared {
            detailLabel.stringValue = (video.isAudioOnly ? L10n.tr("音频") : "\(Int(video.pixelSize.width)) × \(Int(video.pixelSize.height))  ·  " + L10n.tr("视频")) + "  ·  " + Filmstrip.timeText(video.duration) + (video.usedCompatibilityDecoder ? "  ·  " + L10n.tr("兼容播放") : "")
        } else { detailLabel.stringValue = L10n.tr(items.isEmpty ? "图片、音频与视频 · 熟悉的操作" : "正在读取文件") }
        countLabel.stringValue = items.isEmpty ? "" : "\(selectedIndex + 1) / \(items.count)"
        // The welcome action must leave the view hierarchy with the welcome screen.
        // Fading a native button can leave its bezel visible above a small image.
        if items.isEmpty {
            if openButton.superview == nil { root.addSubview(openButton) }
            setVisible(openButton, true, animated: false)
        } else {
            setVisible(openButton, false, animated: false)
            openButton.removeFromSuperview()
        }
        if items.isEmpty { setVisible(dock, false, animated: false) }
        for id in ["zoomOut", "zoomIn", "fit", "rotate", "info"] { buttons[id]?.isEnabled = mediaReady }
        buttons["play"]?.isEnabled = mediaReady && items.count > 1
        buttons["previous"]?.isEnabled = items.count > 1; buttons["next"]?.isEnabled = items.count > 1
        updateVideoControls(); updateDocumentControls()
        updateZoom(canvas.zoom); refreshInfo()
    }
    private func updateZoom(_ zoom: Double) { zoomLabel.stringValue = "\(Int((zoom * 100).rounded()))%" }
    private func refreshInfo() {
        guard mediaReady, currentURL != nil else { infoText.stringValue = L10n.tr("文件信息") + "\n\n" + L10n.tr("暂时没有可显示的信息"); return }
        var entries = videoPrepared ? (video?.metadata ?? []) : (loaded?.metadata ?? [])
        if let document = documentMedia, let page = documentPage {
            entries = [("文件名", document.url.lastPathComponent), ("格式", L10n.tr(document.format)),
                       ("页面", L10n.format("第 %d / %d 页", page.index + 1, document.pageCount)),
                       ("尺寸", "\(Int(page.size.width)) × \(Int(page.size.height))"),
                       ("位置", document.url.deletingLastPathComponent().path)]
        }
        let text = NSMutableAttributedString(string: L10n.tr(videoPrepared ? (video?.isAudioOnly == true ? "音频信息" : "视频信息") : (documentPage != nil ? "文档信息" : "图片信息")) + "\n\n", attributes: [.font: NSFont.systemFont(ofSize: 15, weight: .semibold), .foregroundColor: NSColor.white])
        for (key, value) in entries.prefix(10) {
            text.append(NSAttributedString(string: L10n.tr(key) + "  ", attributes: [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor(white: 0.55, alpha: 1)]))
            text.append(NSAttributedString(string: localizedMetadataValue(value, key: key) + "\n\n", attributes: [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor(white: 0.9, alpha: 1)]))
        }
        infoText.attributedStringValue = text
    }
    func revealChrome() {
        guard !isClosing else { return }
        setVisible(top, true); setVisible(dock, !items.isEmpty)
        hideTimer?.invalidate()
        guard !items.isEmpty else { return }
        hideTimer = Timer.scheduledTimer(withTimeInterval: 2.8, repeats: false) { [weak self] _ in
            guard let self, !self.isClosing, !self.infoVisible, let window = self.window, window.isKeyWindow else { return }
            let p = self.root.convert(window.mouseLocationOutsideOfEventStream, from: nil)
            guard !self.videoSeekSlider.isTracking, !self.videoVolumeSlider.isTracking, !self.pageSeekSlider.isTracking,
                  p.y > self.dock.frame.maxY + 10, p.y < self.root.bounds.height - 76 else { return }
            self.setVisible(self.top, false); self.setVisible(self.dock, false)
        }
    }
    func showToast(_ message: String, duration: TimeInterval = 2) {
        guard !isClosing else { return }
        toastTimer?.invalidate(); toast.stringValue = L10n.tr(message); setVisible(toast, true)
        toastTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            guard let self else { return }; self.setVisible(self.toast, false)
        }
    }
    private func deferLoadingToast(_ message: String) {
        hideLoadingToast()
        let token = loadingToastGeneration
        let task = DispatchWorkItem { [weak self] in
            guard let self, token == self.loadingToastGeneration else { return }
            self.showToast(message, duration: 30)
        }
        loadingToast = task; DispatchQueue.main.asyncAfter(deadline: .now() + 0.20, execute: task)
    }
    private func hideLoadingToast() {
        loadingToastGeneration += 1
        loadingToast?.cancel(); loadingToast = nil; toastTimer?.invalidate()
        setVisible(toast, false)
    }
    private func scheduleAnimation() {
        animationTimer?.invalidate()
        guard let loaded, loaded.frameCount > 1, window?.isVisible == true else { return }
        let request = generation
        animationTimer = Timer.scheduledTimer(withTimeInterval: max(0.02, loaded.frameDuration(at: animationFrame)), repeats: false) { [weak self] _ in
            guard let self, request == self.generation else { return }
            let next = (self.animationFrame + 1) % loaded.frameCount
            self.animationQueue.async { [weak self] in
                let frame = loaded.frame(at: next)
                DispatchQueue.main.async {
                    guard let self, request == self.generation else { return }
                    self.animationFrame = next
                    if let frame { self.canvas.setImage(frame, pixelSize: loaded.pixelSize, reset: false, animated: false) }
                    self.scheduleAnimation()
                }
            }
        }
    }
    private func scheduleSlide() {
        slideTimer?.invalidate(); slideTimer = nil
        guard isPlaying, items.count > 1, video == nil else { return }
        slideTimer = Timer.scheduledTimer(withTimeInterval: slideInterval, repeats: false) { [weak self] _ in
            guard let self else { return }
            if self.selectedIndex == self.items.count - 1 && !self.looping { self.stopSlideshow(); return }
            self.navigate(1)
        }
    }
    func stopSlideshow() { isPlaying = false; slideTimer?.invalidate(); slideTimer = nil; updateChrome() }
    private func stopTimers() {
        stopSlideshow(); animationTimer?.invalidate(); animationTimer = nil; hideTimer?.invalidate(); toastTimer?.invalidate()
        loadingToast?.cancel(); loadingToast = nil
        loadingToastGeneration += 1
    }

    @objc func openDialog() {
        if isClosing || window?.isVisible == false { show() }
        guard window?.attachedSheet == nil else { return }
        stopSlideshow()
        let panel = NSOpenPanel(); panel.title = L10n.tr("打开图片、音视频或文件夹")
        panel.canChooseFiles = true; panel.canChooseDirectories = true; panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.image, .movie, .audio, .pdf, .folder] + MediaFormats.associationFormats.flatMap(\.associationTypes); panel.prompt = L10n.tr("开始浏览")
        panel.beginSheetModal(for: window!) { [weak self] response in if response == .OK { self?.open(panel.urls) } }
    }
    @objc func previous() { navigate(-1) }
    @objc func nextImage() { navigate(1) }
    @objc func firstImage() { select(0) }
    @objc func lastImage() { select(items.count - 1) }
    @objc func zoomIn() { canvas.zoomBy(1.25); revealChrome() }
    @objc func zoomOut() { canvas.zoomBy(0.8); revealChrome() }
    @objc func fit() { canvas.fit(); revealChrome() }
    @objc func actualSize() { canvas.toggleActualSize(); revealChrome() }
    @objc func rotateRight() { rotate(1) }
    @objc func rotateLeft() { rotate(-1) }
    private func rotate(_ delta: Int) {
        guard let url = currentURL, mediaReady else { return }
        canvas.rotate(delta); rotationByURL[url] = canvas.quarterTurns
        showToast("已旋转视图，原文件保持不变"); revealChrome()
    }
    @objc func toggleBackground() {
        canvas.backgroundMode = CanvasBackground(rawValue: (canvas.backgroundMode.rawValue + 1) % CanvasBackground.allCases.count) ?? .translucent
        persistPreferences(); revealChrome()
    }
    @objc func toggleInfo() { infoVisible.toggle(); setVisible(infoPanel, infoVisible); revealChrome(); window?.makeFirstResponder(canvas) }
    @objc func toggleFullscreen() {
        guard !fullScreenTransitioning, !isClosing else { return }
        fullScreenTransitioning = true; window?.toggleFullScreen(nil); revealChrome()
    }
    @objc func minimize() { window?.miniaturize(nil) }
    @objc func closeViewer() {
        guard !isClosing, window?.isVisible == true else { return }
        contextActions.invalidate()
        isClosing = true; visibilityGeneration += 1
        generation += 1; openGeneration += 1; pageGeneration += 1; loader.cancelPending(); stopTimers()
        documentLoadRequest?.cancel(); documentLoadRequest = nil
        documentMedia?.cancelPendingPageLoads()
        stopVideo()
        scanInProgress = false; hideLoadingToast()
        window?.ignoresMouseEvents = true
        if fullScreenTransitioning { closeAfterFullscreen = true; return }
        fadeAndClose()
    }
    @objc func toggleSlideshow() {
        if isPlaying { stopSlideshow(); revealChrome(); return }
        guard mediaReady, items.count > 1 else { showToast("打开包含多个媒体文件的文件夹即可连续播放"); return }
        isPlaying = true
        if videoPrepared { video?.play() }
        scheduleSlide(); updateChrome(); revealChrome()
    }
    @objc func revealInFinder() { if let url = currentURL { NSWorkspace.shared.activateFileViewerSelecting([url]) } }
    @objc func showLanguagePreferences() {
        if isClosing || window?.isVisible == false { show() }
        if languagePreferences == nil {
            let preferences = LanguagePreferencesController()
            preferences.onClose = { [weak self] in self?.window?.makeFirstResponder(self?.canvas) }
            languagePreferences = preferences
        }
        languagePreferences?.present(relativeTo: window)
    }
    private func refreshLanguage() {
        openButton.title = L10n.tr("打开图片、音视频或文件夹")
        for (id, key) in buttonTooltipKeys {
            buttons[id]?.toolTip = L10n.tr(key); buttons[id]?.setAccessibilityLabel(L10n.tr(key))
        }
        videoSeekSlider.setAccessibilityLabel(L10n.tr("音视频进度"))
        videoSeekSlider.toolTip = L10n.tr("拖动跳转 · ⌥← / ⌥→ 后退 / 前进 5 秒")
        videoVolumeSlider.setAccessibilityLabel(L10n.tr("音视频音量"))
        videoVolumeSlider.toolTip = L10n.tr("音量")
        infoText.alignment = L10n.isRightToLeft ? .right : .left
        canvas.refreshLocalization()
        updateChrome(); layoutChrome()
    }
    private func localizedMetadataValue(_ value: String, key: String) -> String {
        LocalizationMetadata.value(value, for: key)
    }
    @objc func showDefaultViewerPreferences() {
        if isClosing || window?.isVisible == false { show() }
        if defaultViewerPreferences == nil {
            let preferences = DefaultViewerPreferencesController()
            preferences.onClose = { [weak self] in self?.window?.makeFirstResponder(self?.canvas) }
            defaultViewerPreferences = preferences
        }
        defaultViewerPreferences?.present(relativeTo: window)
    }
    @objc func toggleStrip() { showFilmstrip.toggle(); layoutChrome(); persistPreferences(); revealChrome() }
    @objc func toggleLoop() { looping.toggle(); persistPreferences() }
    @objc func toggleWheel() { canvas.wheelNavigates.toggle(); persistPreferences() }
    @objc func toggleBackgroundClose() { closeOnBackground.toggle(); persistPreferences() }
    @objc func chooseInterval(_ sender: NSMenuItem) { slideInterval = Double(sender.tag); scheduleSlide(); persistPreferences() }
    @objc func chooseSort(_ sender: NSMenuItem) {
        guard let url = currentURL else { return }
        sort = sender.tag == 0 ? .name : .modified
        let oldItems = items
        if sort == .name { items.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending } }
        else {
            let dates = Dictionary(uniqueKeysWithValues: oldItems.map { ($0.url, (try? $0.url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast) })
            items.sort { dates[$0.url]! == dates[$1.url]! ? $0.name.localizedStandardCompare($1.name) == .orderedAscending : dates[$0.url]! > dates[$1.url]! }
        }
        strip.items = items; selectedIndex = items.firstIndex { $0.url == url } ?? 0; strip.selected = selectedIndex; persistPreferences(); updateChrome()
    }
    @objc func showOptions() {
        let menu = NSMenu()
        func add(_ title: String, _ selector: Selector, checked: Bool? = nil, tag: Int = 0) {
            let item = NSMenuItem(title: L10n.tr(title), action: selector, keyEquivalent: ""); item.target = self; item.tag = tag
            if let checked { item.state = checked ? .on : .off }; menu.addItem(item)
        }
        add("打开图片、音视频或文件夹…", #selector(openDialog))
        add("在 Finder 中显示", #selector(revealInFinder))
        add("默认打开方式…", #selector(showDefaultViewerPreferences))
        add("语言…", #selector(showLanguagePreferences))
        add("播放 / 暂停音视频 P", #selector(togglePlayback))
        add("停止音视频并返回开头 S", #selector(stopPlayback))
        add("开始 / 停止连续播放 ⌘4", #selector(toggleSlideshow), checked: isPlaying)
        menu.addItem(.separator())
        add("显示缩略图胶片带", #selector(toggleStrip), checked: showFilmstrip)
        add("循环浏览与播放", #selector(toggleLoop), checked: looping)
        add("滚轮切换文件（按 Ctrl 时缩放）", #selector(toggleWheel), checked: canvas.wheelNavigates)
        add("点击画面外的背景关闭", #selector(toggleBackgroundClose), checked: closeOnBackground)
        menu.addItem(.separator())
        for seconds in [2, 3, 5, 8, 10] { add(L10n.format("幻灯片间隔：%d 秒", seconds), #selector(chooseInterval(_:)), checked: slideInterval == Double(seconds), tag: seconds) }
        menu.addItem(.separator())
        add("按文件名排序", #selector(chooseSort(_:)), checked: sort == .name, tag: 0)
        add("按修改时间排序（最新优先）", #selector(chooseSort(_:)), checked: sort == .modified, tag: 1)
        menu.addItem(.separator())
        add("键盘与鼠标操作…", #selector(showHelp))
        if let b = buttons["more"] { menu.popUp(positioning: nil, at: NSPoint(x: b.frame.minX, y: b.frame.maxY + 4), in: dock) }
        window?.makeFirstResponder(canvas)
    }
    @objc func showHelp() {
        if isClosing || window?.isVisible == false { show() }
        guard window?.attachedSheet == nil else { return }
        let alert = NSAlert(); alert.messageText = L10n.tr("LumaView · 图片与音视频操作")
        alert.informativeText = [
            "← / J  上一个     → / K  下一个",
            "↑ 内页焦点 · ↓ 文件焦点（多页文档）",
            "← / →  切换当前焦点的内页或文件",
            "滚轮 / + − / Page Up Down  缩放",
            "按住 Ctrl 滚轮  切换文件",
            "单击画面 / 1  切换原始大小与适合窗口",
            "拖动画面  平移     双指捏合  缩放",
            "0  适合窗口     空格  切换背景",
            "⌘R / Ctrl+R  顺时针旋转（加 Shift 反向）",
            "F / F11 / ⌃⌘F  全屏",
            "P  播放 / 暂停音视频     S  停止并返回开头",
            "⌥← / ⌥→  音视频后退 / 前进 5 秒     M  静音",
            "⌘4  开始 / 停止连续播放（音视频播放完再切换）",
            "I / ⌘I  文件信息     T  缩略图",
            "Home / End  第一个 / 最后一个",
            "C  更多选项     ⌘O  打开",
            "⌘Return  在 Finder 中显示",
            "Esc  暂停播放 → 关闭信息 → 退出全屏 → 关闭窗口",
            "",
            "缩放、旋转只改变当前视图，不修改原文件。",
        ].map { L10n.tr($0) }.joined(separator: "\n")
        alert.addButton(withTitle: L10n.tr("知道了")); alert.beginSheetModal(for: window!) { [weak self] _ in self?.window?.makeFirstResponder(self?.canvas) }
    }
    func handleKey(_ event: NSEvent) -> Bool {
        if isClosing { return true }
        let key = event.charactersIgnoringModifiers?.lowercased() ?? ""
        let command = event.modifierFlags.contains(.command), control = event.modifierFlags.contains(.control)
        let shift = event.modifierFlags.contains(.shift)
        if event.modifierFlags.contains(.option), !command, !control, videoPrepared, [123, 124].contains(event.keyCode) {
            video?.seek(by: event.keyCode == 123 ? -5 : 5); revealChrome(); return true
        }
        if command || control {
            if command, key == "c" { contextActions.copyCurrent(); return true }
            if key == "r" { shift ? rotateLeft() : rotateRight(); return true }
            if key == "4" { toggleSlideshow(); return true }
            if key == "\r" { revealInFinder(); return true }
            return false
        }
        switch event.keyCode {
        case 123: navigateFocused(-1); return true
        case 124: navigateFocused(1); return true
        case 126: if showsDocumentNavigation { focusPages(); return true } else { return false }
        case 125: if showsDocumentNavigation { focusFiles(); return true } else { return false }
        case 115: if navigationFocus == .pages, showsDocumentNavigation { selectPage(0) } else { firstImage() }; return true
        case 119: if navigationFocus == .pages, let document = documentMedia, showsDocumentNavigation { selectPage(document.pageCount - 1) } else { lastImage() }; return true
        case 116: zoomIn(); return true
        case 121: zoomOut(); return true
        case 103: toggleFullscreen(); return true
        case 53:
            if video?.isPlaying == true { video?.pause(); stopSlideshow(); updateVideoControls(); showToast("音视频已暂停") }
            else if isPlaying { stopSlideshow(); showToast("连续播放已暂停") }
            else if infoVisible { toggleInfo() }
            else if window?.styleMask.contains(.fullScreen) == true { toggleFullscreen() }
            else { closeViewer() }; return true
        default: break
        }
        switch key {
        case "j": navigateFocused(-1)
        case "k": navigateFocused(1)
        case "=", "+": zoomIn()
        case "-", "_": zoomOut()
        case "0": fit()
        case "1": actualSize()
        case " ": toggleBackground()
        case "f": toggleFullscreen()
        case "p": togglePlayback()
        case "s": stopPlayback()
        case "m": if videoPrepared { toggleVideoMute() } else { return false }
        case "i": toggleInfo()
        case "t": toggleStrip()
        case "c": showOptions()
        case "?": showHelp()
        default: return false
        }
        return true
    }
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        let needsImage: [Selector] = [#selector(revealInFinder), #selector(rotateRight), #selector(rotateLeft), #selector(actualSize), #selector(fit), #selector(zoomIn), #selector(zoomOut), #selector(toggleInfo)]
        if needsImage.contains(menuItem.action ?? #selector(openDialog)) { return mediaReady }
        if menuItem.action == #selector(togglePlayback) || menuItem.action == #selector(stopPlayback) { return videoPrepared }
        if menuItem.action == #selector(toggleSlideshow) { return mediaReady && items.count > 1 }
        return true
    }
    private func restorePreferences() {
        let d = UserDefaults.standard
        d.register(defaults: ["background": CanvasBackground.translucent.rawValue, "loop": true, "strip": true, "interval": 3.0, "backgroundClose": true, "wheelNavigate": false, "sort": "name", "videoVolume": 0.75, "videoMuted": false])
        canvas.backgroundMode = CanvasBackground(rawValue: d.integer(forKey: "background")) ?? .translucent
        if d.integer(forKey: "glassBackgroundVersion") < 1 {
            // Restore the requested translucent appearance after the 1.1.1 override.
            canvas.backgroundMode = .translucent
            if !CommandLine.arguments.contains(where: { $0.hasSuffix("self-test") }) {
                d.set(canvas.backgroundMode.rawValue, forKey: "background")
                d.set(1, forKey: "glassBackgroundVersion")
            }
        }
        looping = d.bool(forKey: "loop"); showFilmstrip = d.bool(forKey: "strip"); closeOnBackground = d.bool(forKey: "backgroundClose")
        slideInterval = max(1, d.double(forKey: "interval")); canvas.wheelNavigates = d.bool(forKey: "wheelNavigate")
        sort = ImageSort(rawValue: d.string(forKey: "sort") ?? "name") ?? .name
        videoVolume = Float(max(0, min(1, d.double(forKey: "videoVolume")))); videoMuted = d.bool(forKey: "videoMuted")
    }
    private func persistPreferences() {
        guard !CommandLine.arguments.contains(where: { $0.hasSuffix("self-test") }) else { return }
        let d = UserDefaults.standard
        d.set(canvas.backgroundMode.rawValue, forKey: "background"); d.set(looping, forKey: "loop"); d.set(showFilmstrip, forKey: "strip")
        d.set(slideInterval, forKey: "interval"); d.set(closeOnBackground, forKey: "backgroundClose"); d.set(canvas.wheelNavigates, forKey: "wheelNavigate")
        d.set(sort.rawValue, forKey: "sort")
        d.set(Double(videoVolume), forKey: "videoVolume"); d.set(videoMuted, forKey: "videoMuted")
    }
}
