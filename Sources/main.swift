import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    var viewer: ViewerController!
    private var pendingURLs: [URL] = []
    private var languageObserver: NSObjectProtocol?
    func applicationDidFinishLaunching(_ notification: Notification) {
        if isSelfTestMode { L10n.useLanguageForTesting("zh-Hans") }
        viewer = ViewerController()
        buildMenu()
        languageObserver = NotificationCenter.default.addObserver(forName: L10n.languageDidChange, object: nil, queue: .main) { [weak self] _ in self?.buildMenu() }
        if let i = CommandLine.arguments.firstIndex(of: "--context-menu-self-test"), CommandLine.arguments.count > i + 1 {
            let output = URL(fileURLWithPath: CommandLine.arguments[i + 1], isDirectory: true)
            Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { [self] _ in runContextMenuSelfTests(viewer, output: output) }
            return
        }
        if let i = CommandLine.arguments.firstIndex(of: "--audio-visual-self-test"), CommandLine.arguments.count > i + 1 {
            let output = URL(fileURLWithPath: CommandLine.arguments[i + 1], isDirectory: true)
            Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { [self] _ in runAudioVisualSelfTests(viewer, output: output) }
            return
        }
        if let i = CommandLine.arguments.firstIndex(of: "--document-self-test"), CommandLine.arguments.count > i + 1 {
            let output = URL(fileURLWithPath: CommandLine.arguments[i + 1], isDirectory: true)
            Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { [self] _ in runDocumentSelfTests(viewer, output: output) }
            return
        }
        if let i = CommandLine.arguments.firstIndex(of: "--extended-media-self-test"), CommandLine.arguments.count > i + 1 {
            let output = URL(fileURLWithPath: CommandLine.arguments[i + 1], isDirectory: true)
            Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { [self] _ in runExtendedMediaSelfTests(viewer, output: output) }
            return
        }
        if let i = CommandLine.arguments.firstIndex(of: "--video-self-test"), CommandLine.arguments.count > i + 1 {
            let output = URL(fileURLWithPath: CommandLine.arguments[i + 1], isDirectory: true)
            Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { [self] _ in runVideoSelfTests(viewer, output: output) }
            return
        }
        if let i = CommandLine.arguments.firstIndex(of: "--self-test"), CommandLine.arguments.count > i + 1 {
            let output = URL(fileURLWithPath: CommandLine.arguments[i + 1], isDirectory: true)
            // A run-loop callback allows the harness to pump decoder and animation completions.
            Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { [self] _ in runViewerSelfTests(viewer, output: output) }
            return
        }
        if !pendingURLs.isEmpty { viewer.open(pendingURLs); pendingURLs.removeAll() }
        else {
            let args = CommandLine.arguments.dropFirst().filter { !$0.hasPrefix("-") }.map { URL(fileURLWithPath: $0) }
            if !args.isEmpty { viewer.open(args) } else { viewer.show() }
        }
    }
    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        let urls = filenames.map { URL(fileURLWithPath: $0) }
        if let viewer { viewer.open(urls) } else { pendingURLs += urls }
        sender.reply(toOpenOrPrint: .success)
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag || viewer.isClosing { viewer.show() }; return true
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { !isSelfTestMode }
    private func buildMenu() {
        let bar = NSMenu(); NSApp.mainMenu = bar
        func menu(_ title: String) -> NSMenu {
            let item = NSMenuItem(title: L10n.tr(title), action: nil, keyEquivalent: ""); bar.addItem(item)
            let menu = NSMenu(title: L10n.tr(title)); item.submenu = menu; return menu
        }
        func add(_ menu: NSMenu, _ title: String, _ action: Selector, _ key: String = "", _ mods: NSEvent.ModifierFlags = .command, target: AnyObject? = nil) {
            let item = NSMenuItem(title: L10n.tr(title), action: action, keyEquivalent: key); item.keyEquivalentModifierMask = mods
            item.target = target ?? viewer; menu.addItem(item)
        }
        let app = menu("LumaView")
        add(app, "关于 LumaView", #selector(NSApplication.orderFrontStandardAboutPanel(_:)), target: NSApp)
        add(app, "默认打开方式…", #selector(ViewerController.showDefaultViewerPreferences), ",")
        add(app, "语言…", #selector(ViewerController.showLanguagePreferences))
        app.addItem(.separator())
        add(app, "隐藏 LumaView", #selector(NSApplication.hide(_:)), "h", target: NSApp)
        app.addItem(.separator())
        add(app, "退出 LumaView", #selector(NSApplication.terminate(_:)), "q", target: NSApp)
        let file = menu("文件")
        add(file, "打开图片、音视频或文件夹…", #selector(ViewerController.openDialog), "o")
        add(file, "在 Finder 中显示", #selector(ViewerController.revealInFinder), "\r")
        file.addItem(.separator())
        add(file, "关闭", #selector(ViewerController.closeViewer), "w")
        let view = menu("查看")
        add(view, "适合窗口", #selector(ViewerController.fit), "0")
        add(view, "原始大小 / 适合窗口", #selector(ViewerController.actualSize), "1")
        add(view, "放大", #selector(ViewerController.zoomIn), "=")
        add(view, "缩小", #selector(ViewerController.zoomOut), "-")
        view.addItem(.separator())
        add(view, "顺时针旋转视图", #selector(ViewerController.rotateRight), "r")
        add(view, "逆时针旋转视图", #selector(ViewerController.rotateLeft), "r", [.command, .shift])
        add(view, "文件信息", #selector(ViewerController.toggleInfo), "i")
        add(view, "显示 / 隐藏缩略图", #selector(ViewerController.toggleStrip), "t")
        view.addItem(.separator())
        add(view, "播放 / 暂停音视频", #selector(ViewerController.togglePlayback))
        add(view, "停止音视频并返回开头", #selector(ViewerController.stopPlayback))
        add(view, "开始 / 停止连续播放", #selector(ViewerController.toggleSlideshow), "4")
        add(view, "切换全屏", #selector(ViewerController.toggleFullscreen), "f", [.command, .control])
        let windowMenu = menu("窗口"); NSApp.windowsMenu = windowMenu
        add(windowMenu, "最小化", #selector(ViewerController.minimize), "m")
        let help = menu("帮助")
        add(help, "键盘与鼠标操作", #selector(ViewerController.showHelp), "?")
    }
}

let isSelfTestMode = CommandLine.arguments.contains { $0.hasSuffix("self-test") }
let application = NSApplication.shared
let delegate = AppDelegate()
application.setActivationPolicy(isSelfTestMode ? .accessory : .regular)
application.delegate = delegate
application.run()
