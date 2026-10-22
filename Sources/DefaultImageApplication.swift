import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Injectable boundary: tests supply a fake implementation and never write
/// Launch Services defaults. Constructing this service has no side effects.
protocol DefaultImageApplicationBackend: AnyObject {
    func setDefaultApplication(at applicationURL: URL, for type: UTType, completion: @escaping (Error?) -> Void)
    func defaultApplication(for type: UTType) -> URL?
}

final class WorkspaceDefaultImageApplicationBackend: DefaultImageApplicationBackend {
    func setDefaultApplication(at applicationURL: URL, for type: UTType, completion: @escaping (Error?) -> Void) {
        NSWorkspace.shared.setDefaultApplication(at: applicationURL, toOpen: type, completion: completion)
    }

    func defaultApplication(for type: UTType) -> URL? {
        NSWorkspace.shared.urlForApplication(toOpen: type)
    }
}

/// Uses the macOS 12+ NSWorkspace content-type API, whose completion includes
/// any consent requested by macOS. Never writes a default for abstract media types.
final class DefaultImageApplication {
    /// A default belongs to this installation only when its canonical URL matches.
    /// Bundle identity additionally distinguishes another LumaView copy, without
    /// pretending that an obsolete checkout is the requested installation.
    enum AssociationState: Equatable {
        case currentApplication
        case otherCopy(URL)
        case otherApplication
        case unavailable
    }

    enum MediaKind {
        case images
        case videos

        var displayName: String { L10n.tr(self == .images ? "图片" : "视频") }
    }

    struct Progress {
        let completed: Int
        let total: Int
        let typeName: String
    }

    struct Failure {
        let typeIdentifier: String
        let typeName: String
        let reason: String
    }

    struct Outcome {
        let totalCount: Int
        let succeededCount: Int
        let failures: [Failure]
        let cancelledCount: Int
        let cancelled: Bool
        let errorMessage: String?
        var failedCount: Int { failures.count }
    }

    private final class Batch {
        let applicationURL: URL
        let types: [UTType]
        let progress: ((Progress) -> Void)?
        let completion: (Outcome) -> Void
        var index = 0
        var succeeded = 0
        var failures: [Failure] = []
        var cancelled = false
        var inFlight = false

        init(applicationURL: URL, types: [UTType], progress: ((Progress) -> Void)?, completion: @escaping (Outcome) -> Void) {
            self.applicationURL = applicationURL
            self.types = types
            self.progress = progress
            self.completion = completion
        }
    }

    private let backend: DefaultImageApplicationBackend
    private var batch: Batch?
    private(set) var isRunning = false

    init(backend: DefaultImageApplicationBackend = WorkspaceDefaultImageApplicationBackend()) {
        self.backend = backend
    }

    /// Read-only snapshot of macOS's persistent associations. No local preference
    /// is used as a substitute for system state, including after a failed batch.
    /// Like the picker and the workspace backend, this is called on the main thread.
    func currentSelectionStates(appURL: URL = Bundle.main.bundleURL,
                                types: [UTType]? = nil) -> [String: AssociationState] {
        precondition(Thread.isMainThread)
        let requestedURL = Self.canonicalURL(appURL)
        let requestedIdentifier = Bundle(url: requestedURL)?.bundleIdentifier
        let supported = Set(Self.supportedSelectionTypes().map(\.identifier))
        var result: [String: AssociationState] = [:]
        var applications: [URL: AssociationState] = [:]
        for type in types ?? Self.supportedSelectionTypes() {
            guard supported.contains(type.identifier), result[type.identifier] == nil else { continue }
            guard let url = backend.defaultApplication(for: type).map(Self.canonicalURL) else {
                result[type.identifier] = .unavailable
                continue
            }
            if let cached = applications[url] {
                result[type.identifier] = cached
                continue
            }
            let state: AssociationState
            if url == requestedURL { state = .currentApplication }
            else if let requestedIdentifier, !requestedIdentifier.isEmpty,
                    Bundle(url: url)?.bundleIdentifier == requestedIdentifier {
                state = .otherCopy(url)
            } else { state = .otherApplication }
            applications[url] = state
            result[type.identifier] = state
        }
        return result
    }

    /// Only ImageIO's concrete source types and verified decoder-compatible
    /// extension aliases are eligible. An installed SVG/PDF viewer must not be
    /// displaced merely because public.image or public.data is a supertype.
    static func supportedImageTypes() -> [UTType] {
        let decoderIDs = Set(CGImageSourceCopyTypeIdentifiers() as! [String])
        let decoders = decoderIDs.compactMap { UTType($0) }.filter { !isForbidden($0) }
        var result = Dictionary(uniqueKeysWithValues: decoders.map { ($0.identifier, $0) })
        var extensions = Set([
            "jpg", "jpeg", "jpe", "jfif", "png", "apng", "gif", "tif", "tiff", "bmp", "dib",
            "heic", "heif", "hif", "heics", "webp", "avif", "jxl", "jp2", "jpf", "jpx", "j2k", "j2c",
            "ico", "cur", "icns", "psd", "tga", "exr", "hdr", "pbm", "pgm", "ppm", "pfm",
            "dng", "cr2", "cr3", "crw", "nef", "nrw", "arw", "sr2", "orf", "raf", "rw2", "pef", "srw"
        ])
        for type in decoders {
            extensions.formUnion(type.tags[.filenameExtension] ?? [])
        }
        for fileExtension in extensions {
            for candidate in UTType.types(tag: fileExtension, tagClass: .filenameExtension, conformingTo: nil) {
                guard !candidate.isDynamic, !isForbidden(candidate) else { continue }
                if decoderIDs.contains(candidate.identifier) || decoders.contains(where: { candidate.conforms(to: $0) }) {
                    result[candidate.identifier] = candidate
                }
            }
        }
        // macOS declares these aliases separately, without an inheritance edge
        // to the corresponding ImageIO decoder. Both have real decode fixtures.
        let compatibleAliases: [(identifier: String, decoders: [String])] = [
            ("public.apng", ["public.png"]),
            ("public.ico", ["com.microsoft.ico", "com.microsoft.cur"])
        ]
        for alias in compatibleAliases where alias.decoders.contains(where: decoderIDs.contains) {
            if let type = UTType(alias.identifier), !type.isDynamic, !isForbidden(type) {
                result[type.identifier] = type
            }
        }
        return result.values.sorted { $0.identifier < $1.identifier }
    }

    /// Categories share the same explicit catalog as the format picker. Concrete
    /// imported UTIs are eligible; category supertypes and dynamic guesses are not.
    static func supportedVideoTypes() -> [UTType] {
        catalogTypes(for: .video)
    }

    static func supportedAudioTypes() -> [UTType] { catalogTypes(for: .audio) }
    static func supportedVectorTypes() -> [UTType] { catalogTypes(for: .vector) }

    static func supportedSelectionTypes() -> [UTType] {
        concreteTypes(MediaFormats.associationFormats.flatMap(\.associationTypes))
    }

    private static func catalogTypes(for category: MediaCategory) -> [UTType] {
        concreteTypes(MediaFormats.associationFormats.filter { $0.category == category }.flatMap(\.associationTypes))
    }

    private static func concreteTypes(_ types: [UTType]) -> [UTType] {
        var seen = Set<String>()
        return types.filter { !isAbstractOrUnsafe($0) && seen.insert($0.identifier).inserted }
            .sorted { $0.identifier < $1.identifier }
    }

    /// Call only in response to the user's explicit menu action. The optional
    /// types argument limits a run to a supported subset for fake-backend tests.
    /// All progress and completion callbacks run on the main thread.
    func start(appURL: URL = Bundle.main.bundleURL, types: [UTType]? = nil, mediaKind: MediaKind = .images,
               progress: ((Progress) -> Void)? = nil, completion: @escaping (Outcome) -> Void) {
        let supported = mediaKind == .images ? Self.supportedImageTypes() : Self.supportedVideoTypes()
        begin(appURL: appURL, requested: types ?? supported, supported: supported,
              description: L10n.format("默认%@查看器", mediaKind.displayName), progress: progress, completion: completion)
    }

    /// The format picker calls this only from its explicit Apply button. Opening
    /// the picker, selecting rows and dismissing it never invoke the backend.
    func startSelection(appURL: URL = Bundle.main.bundleURL, types: [UTType],
                        progress: ((Progress) -> Void)? = nil, completion: @escaping (Outcome) -> Void) {
        begin(appURL: appURL, requested: types, supported: Self.supportedSelectionTypes(),
              description: L10n.tr("所选格式的默认应用"), progress: progress, completion: completion)
    }

    private func begin(appURL: URL, requested types: [UTType], supported: [UTType], description: String,
                       progress: ((Progress) -> Void)?, completion: @escaping (Outcome) -> Void) {
        onMain { [self] in
            guard !isRunning else {
                completion(Self.failureOutcome(L10n.format("正在设置%@，请等待当前操作完成。", description)))
                return
            }
            guard appURL.isFileURL, appURL.pathExtension.lowercased() == "app" else {
                completion(Self.failureOutcome(L10n.format("请从完整的 LumaView.app 应用中设置%@。", description)))
                return
            }
            let eligible = Dictionary(uniqueKeysWithValues: supported.map { ($0.identifier, $0) })
            var seen = Set<String>()
            let requested = types.compactMap { eligible[$0.identifier] }
                .filter { seen.insert($0.identifier).inserted }
            guard !requested.isEmpty else {
                completion(Self.failureOutcome(L10n.tr("请至少选择一种支持的具体文件格式。")))
                return
            }
            let active = Batch(applicationURL: Self.canonicalURL(appURL), types: requested, progress: progress, completion: completion)
            batch = active
            isRunning = true
            processNext(active)
        }
    }

    /// Stops queuing further formats. A request already handed to macOS cannot
    /// be revoked: its callback is read back and accounted for before finishing.
    func cancel() {
        onMain { [weak self] in
            guard let self, let active = self.batch else { return }
            active.cancelled = true
            if !active.inFlight { self.finish(active) }
        }
    }

    private func processNext(_ active: Batch) {
        guard batch === active else { return }
        guard !active.cancelled, active.index < active.types.count else { finish(active); return }
        let index = active.index
        let type = active.types[index]
        active.inFlight = true
        backend.setDefaultApplication(at: active.applicationURL, for: type) { [self, active] error in
            // Always hop, even for a synchronous mock: no recursive setter chain,
            // and any cancellation already queued on main gets a turn to run.
            DispatchQueue.main.async { [self, active] in
                guard batch === active, active.inFlight, active.index == index else { return }
                active.inFlight = false
                let actual = backend.defaultApplication(for: type).map(Self.canonicalURL)
                if actual == active.applicationURL {
                    active.succeeded += 1
                } else {
                    let reason = error?.localizedDescription
                        ?? actual.map { L10n.format("系统当前仍使用“%@”，尚未确认切换到当前 LumaView。", $0.lastPathComponent) }
                        ?? L10n.tr("系统未返回此格式的默认应用，无法确认设置结果。")
                    active.failures.append(Failure(typeIdentifier: type.identifier, typeName: Self.typeName(type), reason: reason))
                }
                active.index += 1
                active.progress?(Progress(completed: active.index, total: active.types.count, typeName: Self.typeName(type)))
                processNext(active)
            }
        }
    }

    private func finish(_ active: Batch) {
        guard batch === active else { return }
        let result = Outcome(totalCount: active.types.count, succeededCount: active.succeeded,
                             failures: active.failures, cancelledCount: active.types.count - active.index,
                             cancelled: active.cancelled, errorMessage: nil)
        batch = nil
        isRunning = false
        active.completion(result)
    }

    private static func failureOutcome(_ message: String) -> Outcome {
        Outcome(totalCount: 0, succeededCount: 0, failures: [], cancelledCount: 0, cancelled: false, errorMessage: message)
    }

    private static func typeName(_ type: UTType) -> String {
        let suffix = type.preferredFilenameExtension.map { " (.\($0))" } ?? ""
        return (type.localizedDescription ?? type.identifier) + suffix
    }

    private static func canonicalURL(_ url: URL) -> URL {
        url.standardizedFileURL.resolvingSymlinksInPath()
    }

    private static func isForbidden(_ type: UTType) -> Bool {
        let forbidden: Set<String> = [
            "public.image", "public.item", "public.content", "public.data", "public.composite-content",
            "public.camera-raw-image", "public.audiovisual-content", "public.movie", "public.video", "public.audio",
            "public.directory", "public.folder", "com.apple.bundle", "com.apple.application-bundle",
            "com.adobe.pdf", "public.svg-image"
        ]
        return forbidden.contains(type.identifier) || type.conforms(to: .pdf) || type.conforms(to: .movie)
            || type.conforms(to: .audio) || type.conforms(to: .directory)
    }

    private static func isAbstractOrUnsafe(_ type: UTType) -> Bool {
        let abstract: Set<String> = [
            "public.image", "public.camera-raw-image", "public.movie", "public.video", "public.audio",
            "public.audiovisual-content", "public.item", "public.content", "public.data", "public.composite-content",
            "public.directory", "public.folder", "com.apple.bundle", "com.apple.application-bundle"
        ]
        return type.isDynamic || abstract.contains(type.identifier) || type.conforms(to: .directory)
            || type.conforms(to: .applicationBundle)
    }

    private func onMain(_ action: @escaping () -> Void) {
        if Thread.isMainThread { action() }
        else { DispatchQueue.main.async(execute: action) }
    }
}
