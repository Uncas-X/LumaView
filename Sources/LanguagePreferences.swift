import AppKit

/// Language changes affect this app only and apply immediately without a restart.
final class LanguagePreferencesController: NSWindowController, NSWindowDelegate {
    var onClose: (() -> Void)?
    private let heading = NSTextField(labelWithString: "")
    private let explanation = NSTextField(wrappingLabelWithString: "")
    private let popup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let current = NSTextField(wrappingLabelWithString: "")
    private let closeButton = NSButton(title: "", target: nil, action: nil)
    private var languageObserver: NSObjectProtocol?

    init() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 500, height: 254),
                              styleMask: [.titled, .closable], backing: .buffered, defer: false)
        super.init(window: window)
        window.isReleasedWhenClosed = false; window.delegate = self
        window.collectionBehavior = [.fullScreenAuxiliary, .moveToActiveSpace]
        buildInterface()
        refresh()
        languageObserver = NotificationCenter.default.addObserver(forName: L10n.languageDidChange, object: nil, queue: .main) { [weak self] _ in self?.refresh() }
    }
    required init?(coder: NSCoder) { fatalError("Use init()") }
    func present(relativeTo parent: NSWindow? = nil) {
        guard let window else { return }
        if !window.isVisible {
            if let parent { window.setFrameOrigin(NSPoint(x: parent.frame.midX - window.frame.width / 2, y: parent.frame.midY - window.frame.height / 2)) }
            else { window.center() }
        }
        refresh(); showWindow(nil); window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
    }
    private func buildInterface() {
        guard let content = window?.contentView else { return }
        heading.font = .systemFont(ofSize: 20, weight: .semibold)
        explanation.font = .systemFont(ofSize: 13); explanation.textColor = .secondaryLabelColor
        current.font = .systemFont(ofSize: 12); current.textColor = .secondaryLabelColor
        popup.target = self; popup.action = #selector(changeLanguage)
        popup.identifier = NSUserInterfaceItemIdentifier("languageChoice")
        closeButton.bezelStyle = .rounded; closeButton.target = self; closeButton.action = #selector(closePanel)
        closeButton.keyEquivalent = "\u{1b}"
        let stack = NSStackView(views: [heading, explanation, popup, current, closeButton])
        stack.orientation = .vertical; stack.alignment = .leading; stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false; content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 24),
            explanation.widthAnchor.constraint(equalTo: stack.widthAnchor),
            popup.widthAnchor.constraint(equalTo: stack.widthAnchor),
            current.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
    }
    private func refresh() {
        window?.title = L10n.tr("语言设置")
        heading.stringValue = L10n.tr("界面语言")
        explanation.stringValue = L10n.tr("选择 LumaView 的显示语言。更改立即生效。")
        popup.removeAllItems()
        popup.addItem(withTitle: L10n.tr("跟随系统")); popup.lastItem?.representedObject = "system"
        for language in L10n.languages { popup.addItem(withTitle: language.nativeName); popup.lastItem?.representedObject = language.code }
        popup.select(popup.itemArray.first { ($0.representedObject as? String) == L10n.selectedLanguageCode })
        popup.setAccessibilityLabel(L10n.tr("界面语言"))
        let languageName = L10n.languages.first { $0.code == L10n.effectiveLanguageCode }?.nativeName ?? "English"
        current.stringValue = L10n.format("当前显示语言：%@", languageName)
        closeButton.title = L10n.tr("关闭")
        let alignment: NSTextAlignment = L10n.isRightToLeft ? .right : .natural
        for label in [heading, explanation, current] { label.alignment = alignment }
    }
    @objc private func changeLanguage() {
        guard let code = popup.selectedItem?.representedObject as? String else { return }
        L10n.setLanguage(code)
    }
    @objc private func closePanel() { window?.performClose(nil) }
    func windowWillClose(_ notification: Notification) { onClose?() }
    deinit { if let languageObserver { NotificationCenter.default.removeObserver(languageObserver) } }
}
