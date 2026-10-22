import AppKit
import AVFoundation
import UniformTypeIdentifiers

/// Every menu action owns the file/page/time that was visible when it opened.
/// Async copy jobs can never publish pixels from a file that has since changed.
final class CanvasContextActions: NSObject {
    weak var viewer: ViewerController?
    var onMessage: ((String) -> Void)?
    var pasteboard = NSPasteboard.general
    var applications: (URL) -> [URL] = { NSWorkspace.shared.urlsForApplications(toOpen: $0) }
    var reveal: (URL) -> Void = { NSWorkspace.shared.activateFileViewerSelecting([$0]) }
    var openWith: (URL, URL, @escaping (Error?) -> Void) -> Void = { file, app, completion in
        NSWorkspace.shared.open([file], withApplicationAt: app, configuration: NSWorkspace.OpenConfiguration()) { _, error in
            DispatchQueue.main.async { completion(error) }
        }
    }
    private static func workQueue(_ name: String) -> OperationQueue {
        let queue = OperationQueue(); queue.name = name
        queue.maxConcurrentOperationCount = 1; queue.qualityOfService = .userInitiated
        return queue
    }
    private let queue = workQueue("LumaView.ContextCopy")
    private let indexQueue = workQueue("LumaView.PDFImageIndex")
    private func enqueue(on queue: OperationQueue, _ work: @escaping (BlockOperation) -> Void) {
        let operation = BlockOperation()
        operation.addExecutionBlock { [weak operation] in
            guard let operation, !operation.isCancelled else { return }
            work(operation)
        }
        queue.addOperation(operation)
    }
    private var revision = UUID()
    private var copyRequest = UUID()
    private var pdfIndex: PDFImageCopy?
    private weak var indexedPage: DocumentPage?
    private var indexingPage: DocumentPage?

    init(viewer: ViewerController) { self.viewer = viewer }

    func invalidate() {
        revision = UUID(); copyRequest = UUID()
        queue.cancelAllOperations(); indexQueue.cancelAllOperations()
        pdfIndex = nil; indexedPage = nil; indexingPage = nil
        viewer?.video?.cancelFrameCapture()
    }

    func preparePDF(page: DocumentPage) {
        guard ["pdf", "ai"].contains(page.document.url.pathExtension.lowercased()), page.isVector else { return }
        let token = revision
        indexingPage = page
        indexQueue.cancelAllOperations()
        enqueue(on: indexQueue) { [weak self] operation in
            let index = try? PDFImageCopy(url: page.document.url, pageIndex: page.index)
            guard !operation.isCancelled else { return }
            DispatchQueue.main.async {
                guard let self, self.revision == token, self.viewer?.documentPage === page else { return }
                self.pdfIndex = index; self.indexedPage = page; self.indexingPage = nil
            }
        }
    }

    private enum Content {
        case image(CGImage)
        case page(DocumentPage)
        case video(VideoSession, CMTime)
        case embedded(DocumentPage, CGPoint, PDFImageCopy.Selection?)
    }
    private final class CopyContext: NSObject {
        let url: URL, revision: UUID, content: Content, turns: Int
        init(url: URL, revision: UUID, content: Content, turns: Int) {
            self.url = url; self.revision = revision; self.content = content; self.turns = turns
        }
    }
    private final class FileContext: NSObject {
        let file: URL
        let app: URL?
        init(_ file: URL, app: URL? = nil) { self.file = file; self.app = app }
    }

    func menu(at point: NSPoint) -> NSMenu? {
        guard let viewer, !viewer.isClosing, let url = viewer.currentURL else { return nil }
        let menu = NSMenu(); menu.autoenablesItems = false
        func add(_ key: String, _ id: String, _ action: Selector, _ object: AnyObject) -> NSMenuItem {
            let item = NSMenuItem(title: L10n.tr(key), action: action, keyEquivalent: "")
            item.identifier = NSUserInterfaceItemIdentifier(id); item.target = self; item.representedObject = object
            menu.addItem(item); return item
        }
        if let content = currentContent() {
            if case .page(let page) = content, ["pdf", "ai"].contains(url.pathExtension.lowercased()),
               let hitPoint = viewer.canvas.documentPoint(at: point) {
                let selection = indexedPage === page ? pdfIndex?.image(at: hitPoint) : nil
                if selection != nil || indexingPage === page {
                    _ = add("复制此图片", "copy-embedded-image", #selector(copyContent(_:)),
                        CopyContext(url: url, revision: revision, content: .embedded(page, hitPoint, selection), turns: viewer.canvas.quarterTurns))
                }
            }
            let label: String, id: String
            switch content {
            case .video: label = "复制当前帧"; id = "copy-video-frame"
            case .page(let page) where ["pdf", "ai", "tif", "tiff"].contains(page.document.url.pathExtension.lowercased()):
                label = "复制当前页"; id = "copy-page"
            default: label = "复制图片"; id = "copy-image"
            }
            _ = add(label, id, #selector(copyContent(_:)), CopyContext(url: url, revision: revision, content: content, turns: viewer.canvas.quarterTurns))
            menu.addItem(.separator())
        }
        let openItem = NSMenuItem(title: L10n.tr("打开方式"), action: nil, keyEquivalent: "")
        openItem.identifier = NSUserInterfaceItemIdentifier("open-with")
        let submenu = NSMenu(); submenu.autoenablesItems = false
        var seen = Set<String>()
        for app in applications(url) {
            let identifier = Bundle(url: app)?.bundleIdentifier
            guard identifier != "io.local.lumaview", identifier != "io.local.lumaview.tests",
                  seen.insert(identifier ?? app.resolvingSymlinksInPath().path).inserted else { continue }
            let item = NSMenuItem(title: FileManager.default.displayName(atPath: app.path), action: #selector(openApplication(_:)), keyEquivalent: "")
            item.target = self; item.representedObject = FileContext(url, app: app)
            let icon = NSWorkspace.shared.icon(forFile: app.path); icon.size = NSSize(width: 16, height: 16); item.image = icon
            submenu.addItem(item)
        }
        if !submenu.items.isEmpty { submenu.addItem(.separator()) }
        let other = NSMenuItem(title: L10n.tr("其他应用…"), action: #selector(chooseApplication(_:)), keyEquivalent: "")
        other.identifier = NSUserInterfaceItemIdentifier("choose-application")
        other.target = self; other.representedObject = FileContext(url); submenu.addItem(other)
        openItem.submenu = submenu; menu.addItem(openItem)
        _ = add("在 Finder 中显示", "reveal-in-finder", #selector(revealFile(_:)), FileContext(url))
        return menu
    }

    private func currentContent() -> Content? {
        guard let viewer, !viewer.isClosing else { return nil }
        if let page = viewer.documentPage, page.index == viewer.selectedPageIndex,
           page.document.url == viewer.currentURL { return .page(page) }
        if let video = viewer.video, !video.isAudioOnly, video.duration > 0,
           video.player.currentItem?.status == .readyToPlay {
            return .video(video, video.player.currentTime())
        }
        if viewer.loaded != nil, let image = viewer.canvas.image { return .image(image) }
        return nil
    }

    func copyCurrent() {
        guard let viewer, let url = viewer.currentURL, let content = currentContent() else { return }
        performCopy(CopyContext(url: url, revision: revision, content: content, turns: viewer.canvas.quarterTurns))
    }

    @objc private func copyContent(_ sender: NSMenuItem) {
        guard let context = sender.representedObject as? CopyContext else { return }
        performCopy(context)
    }
    private func isCurrent(_ context: CopyContext, request: UUID) -> Bool {
        revision == context.revision && copyRequest == request && viewer?.currentURL == context.url && viewer?.isClosing == false
    }
    private func performCopy(_ context: CopyContext) {
        guard revision == context.revision, viewer?.currentURL == context.url, viewer?.isClosing == false else { return }
        let request = UUID(); copyRequest = request
        queue.cancelAllOperations()
        viewer?.video?.cancelFrameCapture()
        onMessage?(L10n.tr("正在复制…"))
        if case .video(let video, let time) = context.content {
            video.captureCurrentFrame(at: time) { [weak self] result in
                guard let self, self.isCurrent(context, request: request) else { return }
                switch result {
                case .success(let image): self.encode(image, context: context, request: request)
                case .failure(let error): self.onMessage?(error.localizedDescription)
                }
            }
            return
        }
        enqueue(on: queue) { [weak self] operation in
            guard let self else { return }
            do {
                let image: CGImage
                switch context.content {
                case .image(let pixels): image = pixels
                case .page(let page): image = try page.rasterImage ?? page.preview(maxPixelDimension: 8192)
                case .embedded(let page, let point, let known):
                    let selection = try known ?? PDFImageCopy(url: context.url, pageIndex: page.index).image(at: point)
                    guard let selection else {
                        self.finishFailure("此处没有可复制的图片。", context: context, request: request); return
                    }
                    image = try selection.render()
                case .video: return
                }
                self.encodeOnQueue(image, context: context, request: request, operation: operation)
            } catch { self.finishFailure("暂时无法复制当前内容。", context: context, request: request) }
        }
    }
    private func encode(_ image: CGImage, context: CopyContext, request: UUID) {
        enqueue(on: queue) { [weak self] operation in self?.encodeOnQueue(image, context: context, request: request, operation: operation) }
    }
    private func encodeOnQueue(_ image: CGImage, context: CopyContext, request: UUID, operation: BlockOperation) {
        guard !operation.isCancelled else { return }
        guard let pixels = MediaCopy.rotated(image, quarterTurns: context.turns),
              !operation.isCancelled, let png = MediaCopy.encodedImage(pixels, type: .png),
              !operation.isCancelled,
              let tiff = MediaCopy.encodedImage(pixels, type: .tiff) else {
            finishFailure("暂时无法复制当前内容。", context: context, request: request); return
        }
        guard !operation.isCancelled else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self, self.isCurrent(context, request: request) else { return }
            let item = NSPasteboardItem(); item.setData(png, forType: .png); item.setData(tiff, forType: .tiff)
            self.pasteboard.clearContents()
            guard self.pasteboard.writeObjects([item]) else { self.onMessage?(L10n.tr("暂时无法复制当前内容。")); return }
            let message: String
            switch context.content {
            case .video: message = "已复制当前帧"
            case .page(let page) where ["pdf", "ai", "tif", "tiff"].contains(page.document.url.pathExtension.lowercased()): message = "已复制当前页"
            default: message = "已复制图片"
            }
            self.onMessage?(L10n.tr(message))
        }
    }
    private func finishFailure(_ key: String, context: CopyContext, request: UUID) {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.isCurrent(context, request: request) else { return }
            self.onMessage?(L10n.tr(key))
        }
    }
    @objc private func revealFile(_ sender: NSMenuItem) {
        if let context = sender.representedObject as? FileContext { reveal(context.file) }
    }
    @objc private func openApplication(_ sender: NSMenuItem) {
        guard let context = sender.representedObject as? FileContext, let app = context.app else { return }
        launch(context.file, app: app)
    }
    private func launch(_ file: URL, app: URL) {
        openWith(file, app) { [weak self] error in
            if let error { self?.onMessage?(L10n.format("无法用所选应用打开：%@", error.localizedDescription)) }
        }
    }
    @objc private func chooseApplication(_ sender: NSMenuItem) {
        guard let context = sender.representedObject as? FileContext, let window = viewer?.window else { return }
        let panel = NSOpenPanel()
        panel.title = L10n.tr("选择应用"); panel.prompt = L10n.tr("用此应用打开")
        panel.allowedContentTypes = [.applicationBundle]; panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false; panel.canChooseFiles = true
        panel.directoryURL = URL(fileURLWithPath: "/Applications", isDirectory: true)
        panel.beginSheetModal(for: window) { [weak self] response in
            guard response == .OK, let app = panel.url else { return }
            self?.launch(context.file, app: app)
        }
    }
}
