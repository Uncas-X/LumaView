import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

private struct TestFailure: Error, CustomStringConvertible {
    let description: String
}

/// No test creates the real workspace backend. All writes and readbacks below
/// stay in this in-memory mock; only the supported-type catalog reads macOS.
private final class MockDefaultApplicationBackend: DefaultImageApplicationBackend {
    enum Behavior {
        case accept
        case reject
        case leaveUnchanged
        case reportURL(URL)
    }

    struct Request {
        let applicationURL: URL
        let type: UTType
        let completion: (Error?) -> Void
    }

    var behaviors: [String: Behavior] = [:]
    var applications: [String: URL] = [:]
    var manuallyComplete = false
    private(set) var requests: [Request] = []
    private(set) var pending: [Request] = []
    private(set) var readbacks: [String] = []
    private(set) var accessedOnMain = true

    func setDefaultApplication(at applicationURL: URL, for type: UTType, completion: @escaping (Error?) -> Void) {
        accessedOnMain = accessedOnMain && Thread.isMainThread
        let request = Request(applicationURL: applicationURL, type: type, completion: completion)
        requests.append(request)
        if manuallyComplete { pending.append(request) }
        else { resolve(request) }
    }

    func defaultApplication(for type: UTType) -> URL? {
        accessedOnMain = accessedOnMain && Thread.isMainThread
        readbacks.append(type.identifier)
        return applications[type.identifier]
    }

    func resolveNext() {
        precondition(!pending.isEmpty, "A test must wait for the request before resolving it")
        resolve(pending.removeFirst())
    }

    private func resolve(_ request: Request) {
        switch behaviors[request.type.identifier] ?? .accept {
        case .accept:
            applications[request.type.identifier] = request.applicationURL
            request.completion(nil)
        case .reject:
            request.completion(NSError(domain: "LumaViewMock", code: 17,
                                       userInfo: [NSLocalizedDescriptionKey: "Mock system rejection"]))
        case .leaveUnchanged:
            request.completion(nil)
        case .reportURL(let url):
            applications[request.type.identifier] = url
            request.completion(nil)
        }
    }
}

@main
struct DefaultApplicationTests {
    private static var checks = 0
    private static let applicationURL = URL(fileURLWithPath: "/Applications/LumaView.app", isDirectory: true)

    private struct Observation {
        let outcome: DefaultImageApplication.Outcome
        let progress: [DefaultImageApplication.Progress]
        let callbackCount: Int
        let callbacksOnMain: Bool
    }

    static func main() {
        do {
            try run()
            print("PASS: \(checks) default application checks (mock writes only)")
        } catch {
            FileHandle.standardError.write(Data("FAIL: \(error)\n".utf8))
            exit(1)
        }
    }

    private static func run() throws {
        // LaunchServices type metadata is unavailable in restricted command-line
        // sandboxes. Run this read-only/mock suite in a normal desktop session.
        try check(UTType.jpeg.conforms(to: .image), "macOS image type metadata is available")
        try catalog()
        try allSucceed()
        try deduplicatesAndFilters()
        try partialFailure()
        try verifiesReadback()
        try comparesApplicationPaths()
        try canonicalApplicationPath()
        try cancellation()
        try cancellationFromProgress()
        try emptyRequest()
        try videoCatalogAndIsolation()
        try videoFailureReadback()
        try videoCancellation()
        try selectionCatalog()
        try mixedSelection()
        try selectionPartialFailure()
        try selectionCancellation()
        try selectionInvalidRequests()
        try selectionRejectsConcurrentWrites()
        try readsPersistentSystemSelection()
    }

    private static func catalog() throws {
        let types = DefaultImageApplication.supportedImageTypes()
        let identifiers = types.map(\.identifier)
        let identifierSet = Set(identifiers)
        let imageIO = Set(CGImageSourceCopyTypeIdentifiers() as! [String])
        try check(!types.isEmpty, "supported image catalog is nonempty")
        try check(identifierSet.count == identifiers.count, "catalog deduplicates UTI identifiers")
        try check(identifiers == DefaultImageApplication.supportedImageTypes().map(\.identifier), "catalog order is stable")
        try check(!identifierSet.contains(UTType.image.identifier) && !identifierSet.contains(UTType.rawImage.identifier),
                  "catalog contains concrete image types rather than abstract categories")
        try check(types.allSatisfy { !$0.conforms(to: .pdf) && !$0.conforms(to: .movie) && !$0.conforms(to: .video) },
                  "catalog excludes PDF and video")
        if !imageIO.contains("public.svg-image") {
            try check(!identifierSet.contains("public.svg-image"), "image conformance alone does not include unsupported SVG")
        }
        for identifier in ["public.jpeg", "public.png", "public.heic", "public.heif", "public.heics", "com.compuserve.gif",
                           "public.tiff", "com.microsoft.bmp", "org.webmproject.webp", "com.apple.icns", "com.microsoft.ico",
                           "com.adobe.raw-image", "com.canon.cr2-raw-image", "com.canon.cr3-raw-image", "com.nikon.raw-image",
                           "com.sony.arw-raw-image", "com.fuji.raw-image", "com.olympus.raw-image", "com.panasonic.rw2-raw-image"] {
            if imageIO.contains(identifier), UTType(identifier) != nil {
                try check(identifierSet.contains(identifier), "catalog includes decoded format \(identifier)")
            }
        }
        if imageIO.contains("public.png"), let alias = UTType(filenameExtension: "apng") {
            try check(identifierSet.contains(alias.identifier), "APNG extension's distinct system type is included")
        }
        if imageIO.contains("com.microsoft.cur"), let alias = UTType(filenameExtension: "cur") {
            try check(identifierSet.contains(alias.identifier), "CUR extension's distinct system type is included")
        }
    }

    private static func allSucceed() throws {
        let backend = MockDefaultApplicationBackend()
        let types: [UTType] = [.jpeg, .png, .gif]
        let result = try perform(DefaultImageApplication(backend: backend), types: types)
        try check(result.outcome.totalCount == 3 && result.outcome.succeededCount == 3 && result.outcome.failedCount == 0,
                  "all accepted associations are verified and counted")
        try check(!result.outcome.cancelled && result.outcome.cancelledCount == 0 && result.outcome.failures.isEmpty,
                  "successful outcome has no cancellation or failures")
        try check(backend.requests.count == 3 && Set(backend.requests.map { $0.type.identifier }) == Set(types.map(\.identifier)),
                  "every requested image type reaches the injected backend once")
        try check(Set(backend.readbacks) == Set(types.map(\.identifier)), "every successful setter is checked by reading back")
        try check(result.progress.map(\.completed) == [1, 2, 3] && result.progress.allSatisfy { $0.total == 3 },
                  "progress counts completed types monotonically")
        try check(result.progress.allSatisfy { !$0.typeName.isEmpty }, "progress provides a visible format name")
        try check(result.callbackCount == 1 && result.callbacksOnMain && backend.accessedOnMain,
                  "synchronous backend callbacks produce one main-thread completion")
    }

    private static func deduplicatesAndFilters() throws {
        let backend = MockDefaultApplicationBackend()
        var types: [UTType] = [.jpeg, .png, .jpeg, .pdf, .movie, .video, .image, .rawImage]
        if let svg = UTType("public.svg-image") { types.append(svg) }
        let result = try perform(DefaultImageApplication(backend: backend), types: types)
        try check(result.outcome.totalCount == 2 && result.outcome.succeededCount == 2,
                  "explicit requests deduplicate images and filter nondecodable or abstract types")
        try check(backend.requests.count == 2 && Set(backend.requests.map { $0.type.identifier }) == Set([UTType.jpeg.identifier, UTType.png.identifier]),
                  "filtered requests cannot write PDF, video, broad image categories or unsupported SVG")
    }

    private static func partialFailure() throws {
        let backend = MockDefaultApplicationBackend()
        backend.behaviors[UTType.png.identifier] = .reject
        let result = try perform(DefaultImageApplication(backend: backend), types: [.jpeg, .png, .gif])
        try check(result.outcome.totalCount == 3 && result.outcome.succeededCount == 2 && result.outcome.failedCount == 1,
                  "one system rejection does not stop other image formats")
        try check(result.outcome.failures.count == 1 && result.outcome.failures.first?.typeIdentifier == UTType.png.identifier,
                  "partial failure identifies the affected format")
        try check(result.outcome.failures.allSatisfy { !$0.typeName.isEmpty && !$0.reason.isEmpty },
                  "partial failure includes a user-visible reason")
        try check(backend.requests.count == 3 && result.progress.map(\.completed) == [1, 2, 3],
                  "failed types still contribute to progress")
    }

    private static func verifiesReadback() throws {
        let backend = MockDefaultApplicationBackend()
        backend.behaviors[UTType.jpeg.identifier] = .leaveUnchanged
        backend.behaviors[UTType.png.identifier] = .leaveUnchanged
        backend.applications[UTType.jpeg.identifier] = URL(fileURLWithPath: "/System/Applications/Preview.app")
        let result = try perform(DefaultImageApplication(backend: backend), types: [.jpeg, .png])
        try check(result.outcome.succeededCount == 0 && result.outcome.failedCount == 2,
                  "successful setter callbacks cannot hide unchanged or missing readbacks")
        try check(Set(result.outcome.failures.map(\.typeIdentifier)) == Set([UTType.jpeg.identifier, UTType.png.identifier]),
                  "both unchanged and missing defaults are reported as unverified")
    }

    private static func comparesApplicationPaths() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let current = directory.appendingPathComponent("current/LumaView.app", isDirectory: true)
        let old = directory.appendingPathComponent("old/LumaView.app", isDirectory: true)
        try makeApplication(at: current, bundleIdentifier: "dev.lumaview.same-bundle-test")
        try makeApplication(at: old, bundleIdentifier: "dev.lumaview.same-bundle-test")
        try check(Bundle(url: current)?.bundleIdentifier == Bundle(url: old)?.bundleIdentifier,
                  "old and current test applications deliberately share a bundle identifier")
        let backend = MockDefaultApplicationBackend()
        backend.behaviors[UTType.jpeg.identifier] = .reportURL(old)
        let result = try perform(DefaultImageApplication(backend: backend), applicationURL: current, types: [.jpeg])
        try check(result.outcome.succeededCount == 0 && result.outcome.failedCount == 1,
                  "an old app copy with the same bundle ID is not accepted as the requested current app")
    }

    private static func canonicalApplicationPath() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let current = directory.appendingPathComponent("LumaView.app", isDirectory: true)
        let alias = directory.appendingPathComponent("LumaView Link.app", isDirectory: true)
        try makeApplication(at: current, bundleIdentifier: "dev.lumaview.symlink-test")
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: current)
        let backend = MockDefaultApplicationBackend()
        backend.behaviors[UTType.jpeg.identifier] = .reportURL(alias)
        let result = try perform(DefaultImageApplication(backend: backend), applicationURL: current, types: [.jpeg])
        try check(result.outcome.succeededCount == 1 && result.outcome.failedCount == 0,
                  "a symlink to the exact requested app resolves as the same application")
    }

    private static func cancellation() throws {
        let backend = MockDefaultApplicationBackend()
        backend.manuallyComplete = true
        let service = DefaultImageApplication(backend: backend)
        var outcome: DefaultImageApplication.Outcome?
        var completionCount = 0
        var progress: [Int] = []
        service.start(appURL: applicationURL, types: [.jpeg, .png, .gif], progress: { progress.append($0.completed) }) {
            completionCount += 1
            outcome = $0
        }
        try wait("first pending association") { backend.pending.count == 1 }
        try check(backend.requests.count == 1, "association requests run sequentially")
        service.cancel()
        drain(for: 0.02)
        try check(outcome == nil, "cancel waits for the in-flight system callback")
        backend.resolveNext()
        try wait("cancelled operation completion") { outcome != nil }
        drain(for: 0.02)
        let result = outcome!
        try check(result.cancelled && result.totalCount == 3 && result.cancelledCount == 2,
                  "cancel reports the two not-started formats")
        try check(result.succeededCount == 1 && result.failedCount == 0 && progress == [1],
                  "the completed in-flight change is still verified after cancellation")
        try check(backend.requests.count == 1 && backend.pending.isEmpty && completionCount == 1,
                  "cancel starts no later setters and completes exactly once")
    }

    private static func cancellationFromProgress() throws {
        let backend = MockDefaultApplicationBackend()
        let service = DefaultImageApplication(backend: backend)
        var outcome: DefaultImageApplication.Outcome?
        service.start(appURL: applicationURL, types: [.jpeg, .png], progress: { progress in
            if progress.completed == 1 { service.cancel() }
        }) { outcome = $0 }
        try wait("progress-driven cancellation") { outcome != nil }
        try check(backend.requests.count == 1 && outcome?.succeededCount == 1 && outcome?.cancelledCount == 1,
                  "cancellation requested inside progress prevents the next association")
    }

    private static func emptyRequest() throws {
        let backend = MockDefaultApplicationBackend()
        let result = try perform(DefaultImageApplication(backend: backend), types: [.pdf, .video, .image])
        try check(result.outcome.totalCount == 0 && result.outcome.succeededCount == 0 && backend.requests.isEmpty,
                  "an entirely filtered request performs no association writes")
        try check(result.callbackCount == 1, "an empty request still completes once")
    }

    private static func videoCatalogAndIsolation() throws {
        let required: Set<String> = ["public.mpeg-4", "com.apple.quicktime-movie", "com.apple.m4v-video"]
        let expected = Set(MediaFormats.associationFormats.filter { $0.category == .video }.flatMap(\.associationTypes).map(\.identifier))
        let videos = DefaultImageApplication.supportedVideoTypes()
        try check(required.isSubset(of: expected) && Set(videos.map(\.identifier)) == expected,
                  "video catalog retains canonical MP4/MOV/M4V and matches the explicit format catalog")
        try check(Set(DefaultImageApplication.supportedImageTypes().map(\.identifier)).isDisjoint(with: expected),
                  "the existing image catalog remains separate from video types")

        let imageBackend = MockDefaultApplicationBackend()
        let imageResult = try perform(DefaultImageApplication(backend: imageBackend))
        try check(imageResult.outcome.succeededCount == DefaultImageApplication.supportedImageTypes().count
                  && Set(imageBackend.requests.map { $0.type.identifier }).isDisjoint(with: expected),
                  "default start still associates images only and never writes video defaults")
        let mixedImageBackend = MockDefaultApplicationBackend()
        let mixedImage = try perform(DefaultImageApplication(backend: mixedImageBackend), types: videos + [.jpeg])
        try check(mixedImage.outcome.totalCount == 1 && mixedImageBackend.requests.map({ $0.type.identifier }) == [UTType.jpeg.identifier],
                  "even explicitly supplied video types cannot enter an image operation")

        let videoBackend = MockDefaultApplicationBackend()
        let videoResult = try perform(DefaultImageApplication(backend: videoBackend), mediaKind: .videos)
        try check(videoResult.outcome.totalCount == videos.count && videoResult.outcome.succeededCount == videos.count
                  && Set(videoBackend.requests.map { $0.type.identifier }) == expected,
                  "video opt-in writes only explicitly supported concrete video formats")
        try check(videoResult.progress.map(\.completed) == Array(1...videos.count) && videoResult.callbackCount == 1,
                  "video operation retains sequential progress and one completion")

        let filteredBackend = MockDefaultApplicationBackend()
        let supplied = videos + videos + [.jpeg, .png, .pdf, .movie, .video, .audio, .mpeg4Audio, .audiovisualContent]
        let filtered = try perform(DefaultImageApplication(backend: filteredBackend), types: supplied, mediaKind: .videos)
        try check(filtered.outcome.totalCount == videos.count && filteredBackend.requests.count == videos.count
                  && Set(filteredBackend.requests.map { $0.type.identifier }) == expected,
                  "video requests deduplicate and exclude images, PDF, audio and abstract video categories")
        let emptyBackend = MockDefaultApplicationBackend()
        let empty = try perform(DefaultImageApplication(backend: emptyBackend), types: [.jpeg, .audio, .movie], mediaKind: .videos)
        try check(emptyBackend.requests.isEmpty && empty.outcome.totalCount == 0 && empty.outcome.errorMessage != nil,
                  "a video request without eligible concrete formats performs no writes")
    }

    private static func videoFailureReadback() throws {
        let backend = MockDefaultApplicationBackend()
        backend.behaviors["com.apple.quicktime-movie"] = .reject
        backend.behaviors["com.apple.m4v-video"] = .leaveUnchanged
        backend.applications["com.apple.m4v-video"] = URL(fileURLWithPath: "/System/Applications/QuickTime Player.app")
        let result = try perform(DefaultImageApplication(backend: backend), mediaKind: .videos)
        let count = DefaultImageApplication.supportedVideoTypes().count
        try check(result.outcome.totalCount == count && result.outcome.succeededCount == count - 2 && result.outcome.failedCount == 2,
                  "video operation distinguishes an accepted default from rejection and unchanged readback")
        try check(Set(result.outcome.failures.map(\.typeIdentifier)) == Set(["com.apple.quicktime-movie", "com.apple.m4v-video"]),
                  "video failures identify both rejected and unverified formats")
        try check(backend.requests.count == count && result.progress.map(\.completed) == Array(1...count)
                  && result.callbacksOnMain && backend.accessedOnMain,
                  "video failures do not interrupt subsequent formats or leave the main-thread callback contract")
    }

    private static func videoCancellation() throws {
        let backend = MockDefaultApplicationBackend()
        backend.manuallyComplete = true
        let service = DefaultImageApplication(backend: backend)
        var outcome: DefaultImageApplication.Outcome?
        var completionCount = 0
        service.start(appURL: applicationURL, mediaKind: .videos) {
            outcome = $0
            completionCount += 1
        }
        try wait("first pending video association") { backend.pending.count == 1 }
        service.cancel()
        drain(for: 0.02)
        try check(outcome == nil && backend.requests.count == 1, "video cancel waits for the in-flight request without queuing another")
        backend.resolveNext()
        try wait("cancelled video operation completion") { outcome != nil }
        drain(for: 0.02)
        let count = DefaultImageApplication.supportedVideoTypes().count
        try check(outcome?.cancelled == true && outcome?.totalCount == count && outcome?.succeededCount == 1
                  && outcome?.cancelledCount == count - 1 && outcome?.failedCount == 0,
                  "video cancellation verifies the in-flight change and counts all remaining formats as cancelled")
        try check(completionCount == 1 && backend.requests.count == 1 && backend.pending.isEmpty,
                  "cancelled video operation completes exactly once and starts no further writes")
    }

    private static func selectionCatalog() throws {
        let selectedTypes = DefaultImageApplication.supportedSelectionTypes()
        let identifiers = Set(selectedTypes.map(\.identifier))
        let declared = Set(MediaFormats.associationFormats.flatMap(\.associationTypes).map(\.identifier))
        try check(!selectedTypes.isEmpty && identifiers.count == selectedTypes.count,
                  "unified association catalog contains unique concrete types")
        try check(identifiers == declared, "unified selection accepts exactly the shared format catalog")
        try check(identifiers.isDisjoint(with: MediaFormats.forbiddenAssociationIdentifiers)
                  && selectedTypes.allSatisfy { !$0.isDynamic && !$0.conforms(to: .directory) },
                  "unified catalog contains neither abstract supertypes nor dynamic guesses")
        let audio = Set(DefaultImageApplication.supportedAudioTypes().map(\.identifier))
        let vectors = Set(DefaultImageApplication.supportedVectorTypes().map(\.identifier))
        try check(!audio.isEmpty && audio.isSubset(of: identifiers), "audio types are available as an explicit selectable category")
        try check(vectors.contains(UTType.pdf.identifier) && vectors.contains("public.svg-image"),
                  "PDF and SVG are available only through the explicit vector category")
        try check(Set(DefaultImageApplication.supportedImageTypes().map(\.identifier)).isDisjoint(with: vectors),
                  "legacy image-only operations do not silently expand to vector/document associations")
        let imported = selectedTypes.filter { $0.identifier.hasPrefix("io.local.lumaview.format.") }
        try check(!imported.isEmpty && imported.allSatisfy { !$0.isDynamic },
                  "explicit imported formats can be associated without using broad category defaults")
    }

    private static func mixedSelection() throws {
        let families = MediaFormats.associationFormats.filter { ["jpeg", "svg", "matroska", "ape"].contains($0.id) }
        try check(families.count == 4, "mixed fixture includes image, vector, video and audio families")
        let chosen = families.flatMap(\.associationTypes)
        let expected = Set(chosen.map(\.identifier))
        let backend = MockDefaultApplicationBackend()
        let service = DefaultImageApplication(backend: backend)
        try check(backend.requests.isEmpty && !service.isRunning, "constructing the service never writes file associations")
        let unlisted = UTType(importedAs: "dev.lumaview.tests.unlisted-image", conformingTo: .image)
        let supplied = chosen + chosen + [.image, .movie, .video, .audio, .data, .directory, .applicationBundle, .plainText, unlisted]
        let result = try performSelection(service, types: supplied)
        try check(result.outcome.succeededCount == expected.count && result.outcome.totalCount == expected.count,
                  "one selected batch applies concrete formats across all four categories")
        try check(Set(backend.requests.map { $0.type.identifier }) == expected && backend.requests.count == expected.count,
                  "selected batches deduplicate aliases and never write unselected or unsupported types")
        try check(result.callbackCount == 1 && result.callbacksOnMain && backend.accessedOnMain,
                  "unified batches preserve the single main-thread completion contract")
        try check(result.progress.map(\.completed) == Array(1...expected.count),
                  "selected mixed-format progress counts each concrete association once")
    }

    private static func selectionPartialFailure() throws {
        let audio = DefaultImageApplication.supportedAudioTypes().first!
        let movie = DefaultImageApplication.supportedVideoTypes().first!
        let backend = MockDefaultApplicationBackend()
        backend.behaviors[UTType.pdf.identifier] = .reject
        backend.behaviors[audio.identifier] = .leaveUnchanged
        backend.applications[audio.identifier] = URL(fileURLWithPath: "/System/Applications/Music.app")
        let result = try performSelection(DefaultImageApplication(backend: backend), types: [.jpeg, .pdf, movie, audio])
        try check(result.outcome.totalCount == 4 && result.outcome.succeededCount == 2 && result.outcome.failedCount == 2,
                  "mixed selection reports partial success without aborting remaining categories")
        try check(Set(result.outcome.failures.map(\.typeIdentifier)) == Set([UTType.pdf.identifier, audio.identifier]),
                  "mixed failures identify rejected and unchanged formats precisely")
        try check(result.outcome.failures.allSatisfy { !$0.reason.isEmpty && !$0.typeName.isEmpty },
                  "partial results supply readable per-format details for the preferences window")
    }

    private static func selectionCancellation() throws {
        let audio = DefaultImageApplication.supportedAudioTypes().first!
        let backend = MockDefaultApplicationBackend()
        backend.manuallyComplete = true
        let service = DefaultImageApplication(backend: backend)
        var outcome: DefaultImageApplication.Outcome?
        service.startSelection(appURL: applicationURL, types: [.jpeg, .pdf, audio]) { outcome = $0 }
        try wait("first selected association") { backend.pending.count == 1 }
        service.cancel()
        try check(outcome == nil && backend.requests.count == 1, "stopping a mixed batch waits for its in-flight system request")
        backend.resolveNext()
        try wait("cancelled selected association") { outcome != nil }
        try check(outcome?.cancelled == true && outcome?.succeededCount == 1 && outcome?.cancelledCount == 2,
                  "stopping keeps verified completed changes and reports unprocessed choices")
        try check(backend.requests.count == 1 && !service.isRunning,
                  "a cancelled preferences batch never writes its remaining selections")
    }

    private static func selectionInvalidRequests() throws {
        let backend = MockDefaultApplicationBackend()
        let service = DefaultImageApplication(backend: backend)
        let empty = try performSelection(service, types: [])
        let broad = try performSelection(service, types: [.image, .movie, .audio, .data, .item, .content, .directory])
        let unrelated = try performSelection(service, types: [.plainText, .applicationBundle, .url,
            UTType(importedAs: "dev.lumaview.tests.outside-catalog", conformingTo: .image)])
        try check([empty, broad, unrelated].allSatisfy { $0.outcome.totalCount == 0 && $0.outcome.errorMessage != nil },
                  "empty, abstract and out-of-catalog selections produce useful errors")
        try check(backend.requests.isEmpty, "invalid selection performs no association writes")
        for url in [URL(fileURLWithPath: "/tmp/LumaView"), URL(string: "https://example.invalid/LumaView.app")!] {
            let result = try performSelection(service, applicationURL: url, types: [.jpeg])
            try check(result.outcome.errorMessage != nil && backend.requests.isEmpty,
                      "selected associations reject invalid application URL \(url.scheme ?? "nil")")
        }
    }

    private static func selectionRejectsConcurrentWrites() throws {
        let backend = MockDefaultApplicationBackend()
        backend.manuallyComplete = true
        let service = DefaultImageApplication(backend: backend)
        var first: DefaultImageApplication.Outcome?, second: DefaultImageApplication.Outcome?
        service.startSelection(appURL: applicationURL, types: [.jpeg, .pdf]) { first = $0 }
        try wait("active selected batch") { backend.pending.count == 1 }
        service.startSelection(appURL: applicationURL, types: [.png]) { second = $0 }
        try check(second?.errorMessage != nil && first == nil && backend.requests.count == 1,
                  "repeated Apply cannot overlap or replace the active association batch")
        service.cancel(); backend.resolveNext()
        try wait("first batch after repeated apply") { first != nil }
        try check(first?.succeededCount == 1 && first?.cancelledCount == 1,
                  "rejecting a duplicate batch leaves original progress and cancellation intact")
    }

    private static func readsPersistentSystemSelection() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let current = directory.appendingPathComponent("current/LumaView.app", isDirectory: true)
        let old = directory.appendingPathComponent("old/LumaView.app", isDirectory: true)
        let unrelated = directory.appendingPathComponent("unrelated/LumaView.app", isDirectory: true)
        let alias = directory.appendingPathComponent("linked/LumaView.app", isDirectory: true)
        try makeApplication(at: current, bundleIdentifier: "io.local.lumaview")
        try makeApplication(at: old, bundleIdentifier: "io.local.lumaview")
        try makeApplication(at: unrelated, bundleIdentifier: "dev.lumaview.unrelated-reader")
        try FileManager.default.createDirectory(at: alias.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: current)
        let backend = MockDefaultApplicationBackend()
        backend.applications = [UTType.jpeg.identifier: current, UTType.png.identifier: old,
                                UTType.gif.identifier: unrelated, UTType.tiff.identifier: alias]
        let service = DefaultImageApplication(backend: backend)
        let types: [UTType] = [.jpeg, .png, .gif, .tiff, .pdf, .jpeg, .image, .applicationBundle]
        let state = service.currentSelectionStates(appURL: current, types: types)
        try check(state[UTType.jpeg.identifier] == .currentApplication && state[UTType.tiff.identifier] == .currentApplication,
                  "system snapshot recognizes the current installation and its symlink")
        try check(state[UTType.png.identifier] == .otherCopy(old.standardizedFileURL.resolvingSymlinksInPath()),
                  "a matching bundle ID at another path is distinguished as another copy")
        try check(state[UTType.gif.identifier] == .otherApplication,
                  "another application named LumaView is not mistaken for this viewer")
        try check(state[UTType.pdf.identifier] == .unavailable,
                  "a missing system association remains unknown rather than a remembered success")
        try check(state.count == 5 && backend.readbacks.count == 5,
                  "read-only snapshots deduplicate concrete types and exclude broad system categories")
        try check(backend.requests.isEmpty && backend.accessedOnMain,
                  "reading persisted associations never writes or accesses the backend off main")
        backend.applications[UTType.jpeg.identifier] = unrelated
        let reopened = DefaultImageApplication(backend: backend).currentSelectionStates(appURL: current, types: [.jpeg, .tiff])
        try check(reopened[UTType.jpeg.identifier] == .otherApplication && reopened[UTType.tiff.identifier] == .currentApplication,
                  "a newly constructed service reads current system defaults instead of stale local choices")
        try check(backend.requests.isEmpty, "refresh after external changes still performs no setter calls")
    }

    private static func performSelection(_ service: DefaultImageApplication, applicationURL: URL = applicationURL,
                                         types: [UTType]) throws -> Observation {
        var outcome: DefaultImageApplication.Outcome?
        var progress: [DefaultImageApplication.Progress] = []
        var completionCount = 0, callbacksOnMain = true
        service.startSelection(appURL: applicationURL, types: types, progress: {
            callbacksOnMain = callbacksOnMain && Thread.isMainThread
            progress.append($0)
        }) {
            callbacksOnMain = callbacksOnMain && Thread.isMainThread
            completionCount += 1; outcome = $0
        }
        try wait("selected mock operation completion") { outcome != nil }
        drain(for: 0.02)
        return Observation(outcome: outcome!, progress: progress, callbackCount: completionCount, callbacksOnMain: callbacksOnMain)
    }

    private static func perform(_ service: DefaultImageApplication, applicationURL: URL = applicationURL,
                                types: [UTType]? = nil, mediaKind: DefaultImageApplication.MediaKind = .images) throws -> Observation {
        var outcome: DefaultImageApplication.Outcome?
        var progress: [DefaultImageApplication.Progress] = []
        var completionCount = 0
        var callbacksOnMain = true
        service.start(appURL: applicationURL, types: types, mediaKind: mediaKind, progress: {
            callbacksOnMain = callbacksOnMain && Thread.isMainThread
            progress.append($0)
        }) {
            callbacksOnMain = callbacksOnMain && Thread.isMainThread
            completionCount += 1
            outcome = $0
        }
        try wait("mock operation completion") { outcome != nil }
        drain(for: 0.02)
        return Observation(outcome: outcome!, progress: progress, callbackCount: completionCount, callbacksOnMain: callbacksOnMain)
    }

    private static func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("LumaViewDefaultTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private static func makeApplication(at url: URL, bundleIdentifier: String) throws {
        let contents = url.appendingPathComponent("Contents", isDirectory: true)
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
        let data = try PropertyListSerialization.data(fromPropertyList: ["CFBundleIdentifier": bundleIdentifier, "CFBundleName": "LumaView Test"], format: .xml, options: 0)
        try data.write(to: contents.appendingPathComponent("Info.plist"))
    }

    private static func wait(_ label: String, until predicate: () -> Bool) throws {
        let deadline = Date().addingTimeInterval(3)
        while !predicate() && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.002))
        }
        if !predicate() { throw TestFailure(description: "Timed out waiting for \(label)") }
    }

    private static func drain(for duration: TimeInterval) {
        RunLoop.current.run(until: Date().addingTimeInterval(duration))
    }

    private static func check(_ condition: @autoclosure () -> Bool, _ description: String) throws {
        guard condition() else { throw TestFailure(description: description) }
        checks += 1
        print("  PASS \(description)")
    }
}
