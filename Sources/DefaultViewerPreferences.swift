import AppKit
import UniformTypeIdentifiers

private final class FormatListStack: NSStackView {
    override var isFlipped: Bool { true }
}

/// A reusable picker backed by macOS's persistent default associations. Changes
/// are local drafts until Apply; opening, refreshing and clearing never write.
final class DefaultViewerPreferencesController: NSWindowController, NSWindowDelegate, NSSearchFieldDelegate {
    var onClose: (() -> Void)?
    private let service: DefaultImageApplication
    private let applicationURL: URL
    private let formats: [MediaFormat]
    private let eligibleIdentifiers: Set<String>
    private let categories: [MediaCategory] = [.image, .vector, .video, .audio]
    private var selected = Set<String>()
    private var partiallySelected = Set<String>()
    private var editedSelection = Set<String>()
    private var systemStates: [String: DefaultImageApplication.AssociationState] = [:]
    private var checkboxes: [String: NSButton] = [:]
    private var selectionButtons: [NSButton] = []
    private var isApplying = false
    private var lastOutcome: DefaultImageApplication.Outcome?
    private var lastProgress: DefaultImageApplication.Progress?
    private var closeWhenFinished = false
    private var languageObserver: NSObjectProtocol?
    private var activationObserver: NSObjectProtocol?
    private let heading = NSTextField(labelWithString: "")
    private let explanation = NSTextField(wrappingLabelWithString: "")
    private let search = NSSearchField()
    private let countLabel = NSTextField(labelWithString: "")
    private let statusLabel = NSTextField(wrappingLabelWithString: L10n.tr("勾选需要更改的格式，然后点击设置。"))
    private let list = FormatListStack()
    private let listScroll = NSScrollView()
    private let progress = NSProgressIndicator()
    private let resultScroll = NSScrollView()
    private let resultText = NSTextView()
    private let applyButton = NSButton(title: L10n.tr("设为所选格式的默认应用"), target: nil, action: nil)
    private let closeButton = NSButton(title: L10n.tr("关闭"), target: nil, action: nil)
    private let clearButton = NSButton(title: L10n.tr("清空全部选择"), target: nil, action: nil)
    private let selectAllButton = NSButton(title: L10n.tr("全选所有格式"), target: nil, action: nil)

    init(service: DefaultImageApplication = DefaultImageApplication(), appURL: URL = Bundle.main.bundleURL) {
        self.service = service
        applicationURL = appURL
        let eligible = Set(DefaultImageApplication.supportedSelectionTypes().map(\.identifier))
        eligibleIdentifiers = eligible
        formats = MediaFormats.associationFormats.filter { format in
            format.associationTypes.contains { eligible.contains($0.identifier) }
        }
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 720, height: 690),
                              styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        super.init(window: window)
        window.title = L10n.tr("默认打开方式")
        window.minSize = NSSize(width: 620, height: 560)
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.fullScreenAuxiliary, .moveToActiveSpace]
        window.delegate = self
        buildInterface()
        refreshSystemSelection(discardDraft: true)
        rebuildList()
        languageObserver = NotificationCenter.default.addObserver(forName: L10n.languageDidChange, object: nil, queue: .main) { [weak self] _ in
            self?.refreshLanguage()
        }
        activationObserver = NotificationCenter.default.addObserver(forName: NSApplication.didBecomeActiveNotification,
                                                                    object: nil, queue: .main) { [weak self] _ in
            guard let self, self.window?.isVisible == true, !self.isApplying else { return }
            self.refreshSystemSelection(discardDraft: false)
        }
    }

    required init?(coder: NSCoder) { fatalError("Use init(service:appURL:)") }

    func present(relativeTo parent: NSWindow? = nil) {
        guard let window else { return }
        if !isApplying {
            if !window.isVisible {
                lastOutcome = nil; lastProgress = nil
                resultScroll.isHidden = true; resultText.string = ""
                statusLabel.stringValue = L10n.tr("勾选需要更改的格式，然后点击设置。")
            }
            refreshSystemSelection(discardDraft: !window.isVisible)
        }
        if !window.isVisible {
            if let parent {
                window.setFrameOrigin(NSPoint(x: parent.frame.midX - window.frame.width / 2,
                                              y: parent.frame.midY - window.frame.height / 2))
            } else { window.center() }
        }
        showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        if !isApplying { window.makeFirstResponder(search) }
    }

    private func buildInterface() {
        guard let content = window?.contentView else { return }
        let main = NSStackView()
        main.orientation = .vertical; main.alignment = .leading; main.spacing = 10
        main.detachesHiddenViews = true
        main.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(main)
        NSLayoutConstraint.activate([
            main.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 22),
            main.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -22),
            main.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            main.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20)
        ])
        heading.stringValue = L10n.tr("用 LumaView 打开这些文件")
        heading.font = .systemFont(ofSize: 20, weight: .semibold)
        explanation.stringValue = explanationText
        explanation.font = .systemFont(ofSize: 12)
        explanation.textColor = .secondaryLabelColor
        main.addArrangedSubview(heading); main.addArrangedSubview(explanation)
        explanation.widthAnchor.constraint(equalTo: main.widthAnchor).isActive = true

        search.placeholderString = L10n.tr("搜索格式或扩展名，例如 JPG、SVG、MP4、FLAC")
        search.delegate = self
        search.setAccessibilityLabel(L10n.tr("搜索文件格式"))
        main.addArrangedSubview(search)
        search.widthAnchor.constraint(equalTo: main.widthAnchor).isActive = true

        countLabel.font = .systemFont(ofSize: 12, weight: .medium)
        countLabel.lineBreakMode = .byTruncatingTail
        countLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        clearButton.bezelStyle = .rounded
        clearButton.target = self; clearButton.action = #selector(clearSelection)
        selectAllButton.bezelStyle = .rounded
        selectAllButton.target = self; selectAllButton.action = #selector(selectAllFormats)
        let selectionRow = horizontal([countLabel, spacer(), selectAllButton, clearButton])
        main.addArrangedSubview(selectionRow)
        selectionRow.widthAnchor.constraint(equalTo: main.widthAnchor).isActive = true

        list.orientation = .vertical; list.alignment = .leading; list.spacing = 6
        list.edgeInsets = NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        list.translatesAutoresizingMaskIntoConstraints = false
        listScroll.hasVerticalScroller = true; listScroll.hasHorizontalScroller = false
        listScroll.borderType = .bezelBorder; listScroll.autohidesScrollers = true
        listScroll.documentView = list
        list.widthAnchor.constraint(equalTo: listScroll.contentView.widthAnchor).isActive = true
        main.addArrangedSubview(listScroll)
        listScroll.widthAnchor.constraint(equalTo: main.widthAnchor).isActive = true
        listScroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive = true
        listScroll.setContentHuggingPriority(.defaultLow, for: .vertical)

        progress.style = .bar; progress.isIndeterminate = false; progress.minValue = 0; progress.maxValue = 1
        progress.isHidden = true
        main.addArrangedSubview(progress)
        progress.widthAnchor.constraint(equalTo: main.widthAnchor).isActive = true
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.setAccessibilityLabel(L10n.tr("设置状态"))
        main.addArrangedSubview(statusLabel)
        statusLabel.widthAnchor.constraint(equalTo: main.widthAnchor).isActive = true

        resultText.isEditable = false; resultText.isSelectable = true
        resultText.drawsBackground = false; resultText.font = .systemFont(ofSize: 12)
        resultText.textColor = .labelColor
        resultText.textContainerInset = NSSize(width: 8, height: 8)
        resultText.isHorizontallyResizable = false; resultText.isVerticallyResizable = true
        resultText.autoresizingMask = [.width]
        resultText.textContainer?.widthTracksTextView = true
        resultScroll.hasVerticalScroller = true; resultScroll.borderType = .bezelBorder
        resultScroll.documentView = resultText; resultScroll.isHidden = true
        main.addArrangedSubview(resultScroll)
        resultScroll.widthAnchor.constraint(equalTo: main.widthAnchor).isActive = true
        let resultHeight = resultScroll.heightAnchor.constraint(equalToConstant: 90)
        resultHeight.priority = .defaultHigh; resultHeight.isActive = true
        resultScroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true

        closeButton.bezelStyle = .rounded; closeButton.target = self; closeButton.action = #selector(closeOrStop)
        closeButton.keyEquivalent = "\u{1b}"
        applyButton.bezelStyle = .rounded; applyButton.target = self; applyButton.action = #selector(applySelection)
        applyButton.keyEquivalent = "\r"
        let footer = horizontal([closeButton, spacer(), applyButton])
        main.addArrangedSubview(footer)
        footer.widthAnchor.constraint(equalTo: main.widthAnchor).isActive = true
    }

    private func horizontal(_ views: [NSView]) -> NSStackView {
        let row = NSStackView(views: views)
        row.orientation = .horizontal; row.alignment = .centerY; row.spacing = 8
        return row
    }

    private func spacer() -> NSView {
        let view = NSView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return view
    }

    private var filteredFormats: [MediaFormat] {
        let query = search.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return formats }
        return formats.filter { format in
            let text = ([format.title, format.category.title] + format.extensions.flatMap { [$0, ".\($0)"] }
                        + format.associationTypes.map(\.identifier)).joined(separator: " ")
            return text.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    private func rebuildList() {
        list.arrangedSubviews.forEach { list.removeArrangedSubview($0); $0.removeFromSuperview() }
        checkboxes.removeAll(); selectionButtons.removeAll()
        let visible = filteredFormats
        for (index, category) in categories.enumerated() {
            let children = visible.filter { $0.category == category }
            guard !children.isEmpty else { continue }
            let heading = NSTextField(labelWithString: L10n.format("%@ · %d 种", category.title, children.count))
            heading.font = .systemFont(ofSize: 13, weight: .semibold)
            let select = NSButton(title: search.stringValue.isEmpty ? L10n.tr("全选") : L10n.tr("全选结果"), target: self, action: #selector(selectCategory(_:)))
            let clear = NSButton(title: L10n.tr("清空"), target: self, action: #selector(clearCategory(_:)))
            for button in [select, clear] {
                button.bezelStyle = .rounded; button.controlSize = .small; button.tag = index
                selectionButtons.append(button)
            }
            let header = horizontal([heading, spacer(), select, clear])
            list.addArrangedSubview(header)
            header.widthAnchor.constraint(equalTo: list.widthAnchor, constant: -24).isActive = true
            for format in children {
                let extensions = format.extensions.map { ".\($0)" }.joined(separator: "  ")
                let title = extensions.isEmpty ? format.title : "\(format.title)    \(extensions)"
                let checkbox = NSButton(checkboxWithTitle: title, target: self, action: #selector(toggleFormat(_:)))
                checkbox.identifier = NSUserInterfaceItemIdentifier(format.id)
                checkbox.font = .systemFont(ofSize: 12)
                checkbox.cell?.lineBreakMode = .byTruncatingTail
                checkbox.toolTip = formatTooltip(format, title: title)
                checkbox.setAccessibilityLabel(title)
                checkbox.allowsMixedState = true
                checkbox.state = checkboxState(for: format.id)
                list.addArrangedSubview(checkbox)
                checkbox.widthAnchor.constraint(equalTo: list.widthAnchor, constant: -24).isActive = true
                checkbox.heightAnchor.constraint(equalToConstant: 23).isActive = true
                checkboxes[format.id] = checkbox
            }
        }
        if visible.isEmpty {
            let empty = NSTextField(wrappingLabelWithString: L10n.tr("没有匹配的格式。试试格式名称或扩展名。"))
            empty.textColor = .secondaryLabelColor
            list.addArrangedSubview(empty)
            empty.widthAnchor.constraint(equalTo: list.widthAnchor, constant: -24).isActive = true
        }
        updateControls()
    }

    private var selectedTypes: [UTType] {
        var seen = Set<String>()
        return formats.filter { selected.contains($0.id) }.flatMap(\.associationTypes).filter {
            eligibleIdentifiers.contains($0.identifier) && seen.insert($0.identifier).inserted
        }
    }

    private var explanationText: String {
        L10n.tr("可按格式分别选择图片、矢量图、视频和音频。未勾选的格式保持原来的默认应用。实际可打开范围取决于文件编码与预览数据。")
        + "\n" + L10n.tr("勾选状态来自系统设置；横线表示部分类型已设置，或指向另一个 LumaView 副本。")
    }

    private func checkboxState(for identifier: String) -> NSControl.StateValue {
        if selected.contains(identifier) { return .on }
        return partiallySelected.contains(identifier) ? .mixed : .off
    }

    private func eligibleTypes(for format: MediaFormat) -> [UTType] {
        format.associationTypes.filter { eligibleIdentifiers.contains($0.identifier) }
    }

    private func refreshSystemSelection(discardDraft: Bool) {
        guard !isApplying else { return }
        systemStates = service.currentSelectionStates(appURL: applicationURL)
        if discardDraft { editedSelection.removeAll() }
        for format in formats where !editedSelection.contains(format.id) {
            let states = eligibleTypes(for: format).map { systemStates[$0.identifier] ?? .unavailable }
            selected.remove(format.id); partiallySelected.remove(format.id)
            if !states.isEmpty && states.allSatisfy({ $0 == .currentApplication }) {
                selected.insert(format.id)
            } else if states.contains(where: {
                if case .otherCopy = $0 { return true }
                return $0 == .currentApplication
            }) {
                partiallySelected.insert(format.id)
            }
        }
        updateControls()
    }

    private func formatTooltip(_ format: MediaFormat, title: String) -> String {
        let states = eligibleTypes(for: format).map { systemStates[$0.identifier] ?? .unavailable }
        let current = states.filter { $0 == .currentApplication }.count
        var lines = [title, L10n.format("系统已关联 %d / %d 个类型。", current, states.count)]
        if states.contains(where: { if case .otherCopy = $0 { return true }; return false }) {
            lines.append(L10n.tr("部分类型指向另一个 LumaView 副本；重新设置可切换到当前应用。"))
        }
        if editedSelection.contains(format.id) { lines.append(L10n.tr("此选择尚未应用。")) }
        return lines.joined(separator: "\n")
    }

    private func updateControls() {
        let selectedCount = formats.filter { selected.contains($0.id) }.count
        let visibleCount = filteredFormats.count
        countLabel.stringValue = L10n.format("已选 %d / %d 种格式", selectedCount, formats.count)
            + (search.stringValue.isEmpty ? "" : L10n.format(" · 显示 %d 种", visibleCount))
        search.isEnabled = !isApplying
        for (identifier, checkbox) in checkboxes {
            checkbox.state = checkboxState(for: identifier)
            if let format = formats.first(where: { $0.id == identifier }) {
                checkbox.toolTip = formatTooltip(format, title: checkbox.title)
            }
            checkbox.isEnabled = !isApplying
        }
        selectionButtons.forEach { $0.isEnabled = !isApplying }
        selectAllButton.isEnabled = !isApplying && selected.count != formats.count
        clearButton.isEnabled = !isApplying && (!selected.isEmpty || !partiallySelected.isEmpty)
        applyButton.isEnabled = !isApplying && !service.isRunning && !selectedTypes.isEmpty
        closeButton.title = isApplying ? L10n.tr("停止设置") : L10n.tr("关闭")
        closeButton.isEnabled = !closeWhenFinished
    }

    func controlTextDidChange(_ obj: Notification) {
        guard obj.object as? NSSearchField === search, !isApplying else { return }
        rebuildList()
        listScroll.contentView.scroll(to: .zero)
    }

    @objc private func toggleFormat(_ sender: NSButton) {
        guard !isApplying, let identifier = sender.identifier?.rawValue else { return }
        // Mixed system state becomes a full selection on the first click. Do not
        // expose AppKit's third-state cycle as an unapplied user selection.
        if selected.contains(identifier) { selected.remove(identifier) } else { selected.insert(identifier) }
        partiallySelected.remove(identifier); editedSelection.insert(identifier)
        updateControls()
    }

    @objc private func selectCategory(_ sender: NSButton) {
        guard !isApplying, categories.indices.contains(sender.tag) else { return }
        let identifiers = Set(filteredFormats.filter { $0.category == categories[sender.tag] }.map(\.id))
        selected.formUnion(identifiers); partiallySelected.subtract(identifiers); editedSelection.formUnion(identifiers)
        updateControls()
    }

    @objc private func clearCategory(_ sender: NSButton) {
        guard !isApplying, categories.indices.contains(sender.tag) else { return }
        let identifiers = Set(filteredFormats.filter { $0.category == categories[sender.tag] }.map(\.id))
        selected.subtract(identifiers); partiallySelected.subtract(identifiers); editedSelection.formUnion(identifiers)
        updateControls()
    }

    @objc private func clearSelection() {
        guard !isApplying else { return }
        selected.removeAll(); partiallySelected.removeAll(); editedSelection = Set(formats.map(\.id))
        updateControls()
    }

    @objc private func selectAllFormats() {
        guard !isApplying else { return }
        selected = Set(formats.map(\.id)); partiallySelected.removeAll(); editedSelection = selected
        updateControls()
    }

    @objc private func applySelection() {
        let types = selectedTypes
        guard !isApplying, !service.isRunning, !types.isEmpty else { return }
        isApplying = true; closeWhenFinished = false; lastOutcome = nil; lastProgress = nil
        resultScroll.isHidden = true; resultText.string = ""
        progress.isHidden = false; progress.maxValue = Double(types.count); progress.doubleValue = 0
        statusLabel.stringValue = L10n.tr("正在设置所选格式…系统如需确认，会显示提示。")
        updateControls()
        service.startSelection(appURL: applicationURL, types: types, progress: { [weak self] state in
            guard let self else { return }
            self.lastProgress = state
            self.progress.maxValue = Double(state.total); self.progress.doubleValue = Double(state.completed)
            self.statusLabel.stringValue = L10n.format("已处理 %d / %d：%@", state.completed, state.total, state.typeName)
        }) { [weak self] outcome in
            guard let self else { return }
            self.isApplying = false
            self.progress.isHidden = true
            self.refreshSystemSelection(discardDraft: true)
            self.showOutcome(outcome)
            let shouldClose = self.closeWhenFinished
            self.closeWhenFinished = false
            self.updateControls()
            if shouldClose { self.window?.close() }
        }
    }

    private func showOutcome(_ outcome: DefaultImageApplication.Outcome) {
        lastOutcome = outcome
        if let error = outcome.errorMessage {
            statusLabel.stringValue = error
            return
        }
        let counts = L10n.format("成功 %d 项，失败 %d 项", outcome.succeededCount, outcome.failedCount)
        statusLabel.stringValue = outcome.cancelled
            ? L10n.format("已停止设置：%@，%d 项未处理。", counts, outcome.cancelledCount)
            : L10n.format("设置完成：%@。", counts)
        var details: [String] = []
        if outcome.succeededCount > 0 { details.append(L10n.tr("已成功设置的格式，现在会使用 LumaView 打开。")) }
        if outcome.cancelledCount > 0 { details.append(L10n.tr("未处理的格式保留原来的默认应用。已经完成的设置会保留。")) }
        details += outcome.failures.map { "• \($0.typeName)：\($0.reason)" }
        resultText.string = details.joined(separator: "\n\n")
        resultScroll.isHidden = details.isEmpty
    }

    @objc private func closeOrStop() {
        if isApplying {
            closeButton.isEnabled = false
            statusLabel.stringValue = L10n.tr("正在停止…等待当前格式的系统确认完成。")
            service.cancel()
        } else { window?.performClose(nil) }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard isApplying else { return true }
        closeWhenFinished = true; closeButton.isEnabled = false
        statusLabel.stringValue = L10n.tr("正在停止…完成当前格式后关闭。")
        service.cancel()
        return false
    }

    func windowWillClose(_ notification: Notification) { onClose?() }

    private func refreshLanguage() {
        window?.title = L10n.tr("默认打开方式")
        heading.stringValue = L10n.tr("用 LumaView 打开这些文件")
        explanation.stringValue = explanationText
        search.placeholderString = L10n.tr("搜索格式或扩展名，例如 JPG、SVG、MP4、FLAC")
        search.setAccessibilityLabel(L10n.tr("搜索文件格式"))
        statusLabel.setAccessibilityLabel(L10n.tr("设置状态"))
        applyButton.title = L10n.tr("设为所选格式的默认应用")
        clearButton.title = L10n.tr("清空全部选择")
        selectAllButton.title = L10n.tr("全选所有格式")
        if isApplying, let state = lastProgress {
            statusLabel.stringValue = L10n.format("已处理 %d / %d：%@", state.completed, state.total, state.typeName)
        } else if let lastOutcome { showOutcome(lastOutcome) }
        else { statusLabel.stringValue = L10n.tr("勾选需要更改的格式，然后点击设置。") }
        rebuildList()
    }
    deinit {
        service.cancel()
        if let languageObserver { NotificationCenter.default.removeObserver(languageObserver) }
        if let activationObserver { NotificationCenter.default.removeObserver(activationObserver) }
    }
}
