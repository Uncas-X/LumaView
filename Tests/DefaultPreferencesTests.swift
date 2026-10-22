import AppKit
import UniformTypeIdentifiers
import QuartzCore

private final class FakeBackend: DefaultImageApplicationBackend {
    var writes: [String] = []
    var defaults: [String: URL] = [:]
    func setDefaultApplication(at applicationURL: URL, for type: UTType, completion: @escaping (Error?) -> Void) {
        writes.append(type.identifier)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            if type.identifier == "public.svg-image" { completion(NSError(domain: "Mock", code: 1, userInfo: [NSLocalizedDescriptionKey: "模拟系统拒绝"])) }
            else { self.defaults[type.identifier] = applicationURL; completion(nil) }
        }
    }
    func defaultApplication(for type: UTType) -> URL? { defaults[type.identifier] }
}
private func all(_ view: NSView) -> [NSView] { [view] + view.subviews.flatMap(all) }
@discardableResult private func spin(_ predicate: () -> Bool, timeout: Double = 4) -> Bool {
    let until = Date().addingTimeInterval(timeout)
    repeat { CATransaction.flush(); if predicate() { return true }; RunLoop.main.run(until: Date().addingTimeInterval(0.01)) } while Date() < until
    return predicate()
}
private final class DefaultPreferencesTestDelegate: NSObject, NSApplicationDelegate {
    var preferences: DefaultViewerPreferencesController!
    var checks = 0, failures = 0
    var report: [String] = []
    func check(_ condition: Bool, _ label: String) { checks += 1; let line = "\(condition ? "PASS" : "FAIL") \(label)"; report.append(line); print(line); if !condition { failures += 1 }; fflush(stdout) }
    func snapshot(_ name: String) {
        let view = preferences.window!.contentView!
        view.layoutSubtreeIfNeeded(); preferences.window!.display(); CATransaction.flush()
        guard let image = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
        view.cacheDisplay(in: view.bounds, to: image)
        let source = image.cgImage!
        let context = CGContext(data: nil, width: source.width, height: source.height, bitsPerComponent: 8,
            bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let rect = CGRect(x: 0, y: 0, width: source.width, height: source.height)
        context.setFillColor((preferences.window!.backgroundColor.usingColorSpace(.sRGB) ?? .white).cgColor)
        context.fill(rect); context.draw(source, in: rect)
        let result = NSBitmapImageRep(cgImage: context.makeImage()!)
        try? result.representation(using: .png, properties: [:])?.write(to: testOutputDirectory.appendingPathComponent(name))
    }
    func applicationDidFinishLaunching(_ notification: Notification) {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { [self] _ in
            let backend = FakeBackend()
            let testedService = DefaultImageApplication(backend: backend)
            preferences = DefaultViewerPreferencesController(service: testedService, appURL: URL(fileURLWithPath: "/Applications/LumaView.app"))
            preferences.present()
            spin({ false }, timeout: 0.2)
            let content = preferences.window!.contentView!
            func buttons() -> [NSButton] { all(content).compactMap { $0 as? NSButton } }
            func rows() -> [NSButton] { buttons().filter { $0.identifier != nil } }
            let apply = buttons().first { $0.title == "设为所选格式的默认应用" }!
            let clear = buttons().first { $0.title == "清空全部选择" }!
            let search = all(content).compactMap { $0 as? NSSearchField }.first!
            check(backend.writes.isEmpty && !apply.isEnabled && rows().allSatisfy { $0.state == .off }, "Opening preferences is unchecked and performs no writes")
            check(rows().count == MediaFormats.associationFormats.count, "All catalog format families have selectable rows")
            check(rows().first { $0.identifier?.rawValue == "jpeg" }?.visibleRect.isEmpty == false,
                  "Initial list scroll position shows the first image family")
            snapshot("default-preferences-initial.png")
            search.stringValue = ".jpg"
            preferences.controlTextDidChange(Notification(name: NSText.didChangeNotification, object: search))
            check(rows().count == 1 && rows().first?.identifier?.rawValue == "jpeg", "Extension search accepts a leading dot")
            search.stringValue = "mkv"
            preferences.controlTextDidChange(Notification(name: NSText.didChangeNotification, object: search))
            check(rows().count == 1 && rows().first?.identifier?.rawValue == "matroska", "Extension search filters the relevant format family")
            rows().first?.performClick(nil)
            check(apply.isEnabled && backend.writes.isEmpty, "Checking a format enables Apply without writing defaults")
            search.stringValue = ""
            preferences.controlTextDidChange(Notification(name: NSText.didChangeNotification, object: search))
            check(rows().first { $0.identifier?.rawValue == "matroska" }?.state == .on, "Search changes retain selection")
            clear.performClick(nil)
            check(rows().allSatisfy { $0.state == .off } && !apply.isEnabled, "Clear selection disables Apply")
            buttons().first { $0.title == "全选" && $0.tag == 2 }?.performClick(nil)
            let videoIDs = Set(MediaFormats.associationFormats.filter { $0.category == .video }.map(\.id))
            check(Set(rows().filter { $0.state == .on }.compactMap { $0.identifier?.rawValue }) == videoIDs, "Category Select All selects only video rows")
            buttons().first { $0.title == "清空" && $0.tag == 2 }?.performClick(nil)
            check(rows().allSatisfy { $0.state == .off }, "Category Clear clears only its selected rows")
            for id in ["jpeg", "svg", "ape"] { rows().first { $0.identifier?.rawValue == id }?.performClick(nil) }
            check(backend.writes.isEmpty, "Multiple selections still perform no association writes")
            apply.performClick(nil)
            check(!apply.isEnabled && !search.isEnabled && rows().allSatisfy { !$0.isEnabled }, "Apply disables duplicate submission and selection edits")
            check(spin { !testedService.isRunning }, "Mixed selected batch completes through the fake backend")
            let expected = Set(MediaFormats.associationFormats.filter { ["jpeg", "svg", "ape"].contains($0.id) }.flatMap(\.associationTypes).map(\.identifier))
            check(Set(backend.writes) == expected && backend.writes.count == expected.count, "Apply writes exactly the selected concrete format aliases once")
            check(all(content).compactMap { $0 as? NSTextField }.contains { $0.stringValue.contains("失败 1 项") }, "Partial results remain visible in the preferences window")
            check(all(content).compactMap { $0 as? NSTextView }.contains { $0.string.contains("模拟系统拒绝") }, "Per-format failure details are selectable and visible")
            check(rows().first { $0.identifier?.rawValue == "jpeg" }?.state == .on
                  && rows().first { $0.identifier?.rawValue == "ape" }?.state == .on
                  && rows().first { $0.identifier?.rawValue == "svg" }?.state == .off,
                  "Finished batch rereads successful and failed defaults instead of keeping an unverified draft")
            snapshot("default-preferences-result.png")
            let writeCount = backend.writes.count
            buttons().first { $0.title == "关闭" }?.performClick(nil)
            check(preferences.window?.isVisible == false && backend.writes.count == writeCount, "Closing preferences adds no association writes")

            // Recreate both controller and service: persistence comes from the
            // mock operating system, never from the previous window's selection.
            let reopenedService = DefaultImageApplication(backend: backend)
            preferences = DefaultViewerPreferencesController(service: reopenedService, appURL: URL(fileURLWithPath: "/Applications/LumaView.app"))
            preferences.present()
            let reopenedContent = preferences.window!.contentView!
            func reopenedButtons() -> [NSButton] { all(reopenedContent).compactMap { $0 as? NSButton } }
            func reopenedRows() -> [NSButton] { reopenedButtons().filter { $0.identifier != nil } }
            let reopenedSearch = all(reopenedContent).compactMap { $0 as? NSSearchField }.first!
            let reopenedClear = reopenedButtons().first { $0.title == "清空全部选择" }!
            let selectAll = reopenedButtons().first { $0.title == "全选所有格式" }!
            let reopenedApply = reopenedButtons().first { $0.title == "设为所选格式的默认应用" }!
            check(reopenedRows().first { $0.identifier?.rawValue == "jpeg" }?.state == .on
                  && reopenedRows().first { $0.identifier?.rawValue == "ape" }?.state == .on
                  && reopenedRows().first { $0.identifier?.rawValue == "svg" }?.state == .off,
                  "New controller restores verified system defaults after reopening")
            check(backend.writes.count == writeCount, "Reopening and detecting persisted defaults add no association writes")

            let multi = MediaFormats.associationFormats.first { $0.id == "png" }!
            check(multi.associationTypes.count > 1, "Partial-state fixture contains multiple distinct type aliases")
            backend.defaults[multi.associationTypes[0].identifier] = URL(fileURLWithPath: "/Applications/LumaView.app")
            NotificationCenter.default.post(name: NSApplication.didBecomeActiveNotification, object: NSApp)
            check(reopenedRows().first { $0.identifier?.rawValue == "png" }?.state == .mixed,
                  "Returning to the application detects partial default associations as mixed")
            check(reopenedRows().first { $0.identifier?.rawValue == "png" }?.toolTip?.contains("1 / \(multi.associationTypes.count)") == true,
                  "Partial row tooltip explains the exact number of associated aliases")
            reopenedRows().first { $0.identifier?.rawValue == "png" }?.performClick(nil)
            check(reopenedRows().first { $0.identifier?.rawValue == "png" }?.state == .on,
                  "Clicking a mixed row selects all its aliases in one action")
            backend.defaults[UTType.gif.identifier] = URL(fileURLWithPath: "/Applications/LumaView.app")
            NotificationCenter.default.post(name: NSApplication.didBecomeActiveNotification, object: NSApp)
            check(reopenedRows().first { $0.identifier?.rawValue == "gif" }?.state == .on
                  && reopenedRows().first { $0.identifier?.rawValue == "png" }?.state == .on,
                  "Activation refresh updates untouched defaults while preserving an unapplied user draft")
            check(reopenedRows().first { $0.identifier?.rawValue == "png" }?.toolTip?.contains("此选择尚未应用") == true,
                  "Unapplied choices are identified as drafts in row details")

            reopenedClear.performClick(nil)
            check(reopenedRows().allSatisfy { $0.state == .off } && backend.writes.count == writeCount,
                  "Clearing checked system defaults only clears the draft and never removes an association")
            preferences.window?.close()
            preferences.present()
            check(reopenedRows().first { $0.identifier?.rawValue == "jpeg" }?.state == .on
                  && reopenedRows().first { $0.identifier?.rawValue == "png" }?.state == .mixed,
                  "Reopening discards unapplied clearing and restores actual complete and partial defaults")
            snapshot("default-preferences-persisted.png")

            reopenedSearch.stringValue = "mkv"
            preferences.controlTextDidChange(Notification(name: NSText.didChangeNotification, object: reopenedSearch))
            selectAll.performClick(nil)
            check(reopenedRows().count == 1 && reopenedRows().allSatisfy { $0.state == .on }
                  && backend.writes.count == writeCount,
                  "Global Select All is available while searching and makes no system changes")
            reopenedSearch.stringValue = ""
            preferences.controlTextDidChange(Notification(name: NSText.didChangeNotification, object: reopenedSearch))
            check(reopenedRows().count == MediaFormats.associationFormats.count
                  && reopenedRows().allSatisfy { $0.state == .on },
                  "Global Select All includes every image, vector, video and audio format outside the search results")
            reopenedApply.performClick(nil)
            check(!selectAll.isEnabled && !reopenedClear.isEnabled, "Batch application disables all selection controls")
            check(spin({ !reopenedService.isRunning }, timeout: 12), "All-format fake association batch completes")
            let allExpected = Set(DefaultImageApplication.supportedSelectionTypes().map(\.identifier))
            let allWrites = Array(backend.writes.dropFirst(writeCount))
            check(Set(allWrites) == allExpected && allWrites.count == allExpected.count,
                  "Global selection applies every concrete catalog type exactly once and no abstract categories")
            check(reopenedRows().first { $0.identifier?.rawValue == "svg" }?.state == .off
                  && reopenedRows().filter { $0.identifier?.rawValue != "svg" }.allSatisfy { $0.state == .on },
                  "Global batch readback keeps successful formats checked and leaves rejected SVG unchecked")
            preferences.window?.close()
            let summary = "\(checks - failures) passed, \(failures) failed"
            report.append(summary); print(summary)
            try? (report.joined(separator: "\n") + "\n").write(to: testOutputDirectory.appendingPathComponent("default-preferences-test-results.txt"), atomically: true, encoding: .utf8)
            fflush(stdout); exit(failures == 0 ? 0 : 1)
        }
    }
}
private let testOutputDirectory = CommandLine.arguments.dropFirst().first.map { URL(fileURLWithPath: $0, isDirectory: true) }
    ?? FileManager.default.temporaryDirectory.appendingPathComponent("LumaViewDefaultPreferencesTests", isDirectory: true)

@main
struct DefaultPreferencesTests {
    static func main() {
        // Keep title-based fixture queries deterministic without writing user preferences.
        L10n.useLanguageForTesting("zh-Hans")
        do { try FileManager.default.createDirectory(at: testOutputDirectory, withIntermediateDirectories: true) }
        catch { print("Cannot create test output: \(error)"); exit(1) }
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let delegate = DefaultPreferencesTestDelegate()
        app.delegate = delegate
        app.run()
    }
}
