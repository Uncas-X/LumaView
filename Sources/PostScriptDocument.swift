import Foundation
import CoreGraphics
import CryptoKit
import Darwin

/// Converts PostScript drawing instructions to PDF, retaining paths, text and
/// embedded images. Every interpreter is an isolated, cancellable subprocess.
enum PostScriptDocument {
    enum Failure: LocalizedError {
        case unavailable, invalid, failed, timedOut, oversized
        var errorDescription: String? {
            switch self {
            case .unavailable: return L10n.tr("应用内的矢量兼容组件缺失，请重新安装完整版本。")
            case .invalid, .failed: return L10n.tr("无法解析这个 PostScript 文件，文件可能损坏或缺少必要资源。")
            case .timedOut: return L10n.tr("解析 PostScript 文件超时，请重试或将文件另存为 PDF。")
            case .oversized: return L10n.tr("矢量预览缓存空间不足，请清理磁盘空间后重试。")
            }
        }
    }
    private static let registryLock = NSLock()
    private static var jobs: [String: Job] = [:]
    private static let queue: OperationQueue = {
        let queue = OperationQueue(); queue.name = "LumaView.PostScript"
        queue.maxConcurrentOperationCount = 2; queue.qualityOfService = .userInitiated
        return queue
    }()
    private static let cacheRoot = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("com.lumaview.viewer/PostScript", isDirectory: true)

    static func convert(url: URL, request: ThumbnailRequest? = nil, toolsDirectory: URL? = nil,
                        cacheDirectory: URL? = nil, timeout: TimeInterval = 90) throws -> URL {
        guard url.isFileURL else { throw Failure.invalid }
        if request?.isCancelled == true { throw CancellationError() }
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let root = cacheDirectory ?? cacheRoot
        let tool = toolsDirectory?.appendingPathComponent("gs") ?? bundledTool()
        guard let tool, FileManager.default.isExecutableFile(atPath: tool.path) else { throw Failure.unavailable }
        let identity = ["gs-10.08.0-pdf-v1", url.standardizedFileURL.path,
                        String(describing: attributes[.size]), String((attributes[.modificationDate] as? Date)?.timeIntervalSince1970.bitPattern ?? 0),
                        String(describing: attributes[.systemFileNumber]), String(describing: attributes[.creationDate])].joined(separator: "\n")
        let hash = SHA256.hash(data: Data(identity.utf8)).map { String(format: "%02x", $0) }.joined()
        let output = root.appendingPathComponent("ps-\(hash).pdf")
        let key = output.path + "\n" + tool.path
        registryLock.lock()
        let job: Job
        if let existing = jobs[key] { job = existing }
        else {
            job = Job(source: url, output: output, tool: tool, timeout: timeout)
            jobs[key] = job
            queue.addOperation { job.run() }
        }
        job.consumers += 1
        registryLock.unlock()
        defer {
            registryLock.lock()
            job.consumers -= 1
            if job.consumers == 0 { jobs.removeValue(forKey: key); job.cancel() }
            registryLock.unlock()
        }
        return try job.wait(request: request)
    }

    private static func bundledTool() -> URL? {
        let bundled = Bundle.main.resourceURL?.appendingPathComponent("DocumentTools/gs")
        if let bundled, FileManager.default.isExecutableFile(atPath: bundled.path) { return bundled }
        // Standalone source test executables have no .app resource bundle.
        guard Bundle.main.bundleURL.pathExtension != "app" else { return nil }
        return URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Resources/DocumentTools/gs")
    }

    private final class Job: @unchecked Sendable {
        let source: URL, output: URL, tool: URL
        let timeout: TimeInterval
        var consumers = 0 // Protected by registryLock.
        private let condition = NSCondition()
        private var result: Result<URL, Error>?
        private var cancelled = false
        private var process: Process?
        init(source: URL, output: URL, tool: URL, timeout: TimeInterval) {
            self.source = source; self.output = output; self.tool = tool; self.timeout = timeout
        }
        func cancel() {
            condition.lock(); cancelled = true
            if let process, process.isRunning { kill(process.processIdentifier, SIGKILL) }
            condition.broadcast(); condition.unlock()
        }
        private func check() throws {
            condition.lock(); let value = cancelled; condition.unlock()
            if value { throw CancellationError() }
        }
        func wait(request: ThumbnailRequest?) throws -> URL {
            condition.lock(); defer { condition.unlock() }
            while result == nil {
                if request?.isCancelled == true || cancelled { throw CancellationError() }
                _ = condition.wait(until: Date(timeIntervalSinceNow: 0.05))
            }
            if request?.isCancelled == true || cancelled { throw CancellationError() }
            return try result!.get()
        }
        func run() {
            let value = Result { try prepare() }
            condition.lock(); result = value; condition.broadcast(); condition.unlock()
        }
        private func prepare() throws -> URL {
            try check()
            if validPDF(output) {
                try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: output.path)
                return output
            }
            let manager = FileManager.default
            let root = output.deletingLastPathComponent()
            try manager.createDirectory(at: root, withIntermediateDirectories: true)
            let directory = root.appendingPathComponent(".job-\(UUID().uuidString)", isDirectory: true)
            try manager.createDirectory(at: directory, withIntermediateDirectories: false,
                                        attributes: [.posixPermissions: 0o700])
            defer { try? manager.removeItem(at: directory) }
            let input = directory.appendingPathComponent("input.ps")
            let stagedOutput = directory.appendingPathComponent("output.pdf")
            let eps = try stageSource(to: input)
            try check()
            let task = Process()
            // A second boundary around SAFER: no network, no user-file reads,
            // writes only inside this request's private scratch directory.
            task.executableURL = URL(fileURLWithPath: "/usr/bin/sandbox-exec")
            let profile = """
            (version 1)
            (deny default)
            (allow process-exec (literal (param "TOOL")))
            (allow process-fork)
            (allow signal (target self))
            (allow sysctl-read mach-lookup)
            (allow file-read-metadata)
            (allow file-read-data (literal "/"))
            (allow file-map-executable (subpath "/System") (subpath "/usr/lib") (literal (param "TOOL")))
            (allow file-read-data (subpath "/System") (subpath "/usr/lib") (literal (param "TOOL")) (subpath (param "JOB")))
            (allow file-write* (subpath (param "JOB")))
            (allow file-read-data file-write-data (literal "/dev/null") (literal "/dev/random") (literal "/dev/urandom"))
            """
            // Foundation can normalize /private/var back to /var after
            // resolving symlinks. Sandbox path rules require the physical path.
            guard let resolvedDirectory = realpath(directory.path, nil),
                  let resolvedTool = realpath(tool.path, nil) else { throw Failure.failed }
            let scratch = String(cString: resolvedDirectory)
            let executablePath = String(cString: resolvedTool)
            free(resolvedDirectory); free(resolvedTool)
            var arguments = ["-D", "TOOL=\(executablePath)", "-D", "JOB=\(scratch)", "-p", profile, tool.path,
                "-P-", "-dSAFER", "-dBATCH", "-dNOPAUSE", "-dQUIET", "-sDEVICE=pdfwrite",
                "-dCompatibilityLevel=1.7", "-dAutoRotatePages=/None", "-dEmbedAllFonts=true", "-dSubsetFonts=true",
                "-dDownsampleColorImages=false", "-dDownsampleGrayImages=false", "-dDownsampleMonoImages=false",
                "--permit-file-read=\(input.path)", "--permit-file-write=\(directory.path)/*",
                "-sOutputFile=\(stagedOutput.path)"]
            if eps { arguments.append("-dEPSCrop") }
            arguments += ["-f", input.path]
            task.arguments = arguments
            task.currentDirectoryURL = directory
            task.environment = ["PATH": "/usr/bin:/bin", "LC_ALL": "C", "TMPDIR": directory.path + "/", "GS_TMPDIR": directory.path]
            task.standardInput = FileHandle.nullDevice
            task.standardOutput = FileHandle.nullDevice
            task.standardError = FileHandle.nullDevice
            condition.lock()
            if cancelled { condition.unlock(); throw CancellationError() }
            do { try task.run(); process = task; condition.unlock() }
            catch { condition.unlock(); throw error }
            defer { condition.lock(); process = nil; condition.unlock() }
            let deadline = Date(timeIntervalSinceNow: timeout)
            do {
                while task.isRunning {
                    try check()
                    if Date() >= deadline { throw Failure.timedOut }
                    let bytes = fileSize(stagedOutput)
                    if bytes > 1_024 * 1_024 * 1_024 { throw Failure.oversized }
                    Thread.sleep(forTimeInterval: 0.05)
                }
                task.waitUntilExit()
                try check()
                guard task.terminationStatus == 0, validPDF(stagedOutput) else { throw Failure.failed }
                if (fileSize(stagedOutput)) > 1_024 * 1_024 * 1_024 { throw Failure.oversized }
            } catch {
                if task.isRunning { kill(task.processIdentifier, SIGKILL); task.waitUntilExit() }
                throw error
            }
            // Atomic cache publication: no other consumer sees a partial PDF.
            try check()
            // POSIX rename atomically replaces a complete cache, including when
            // another app process or a just-cancelled job publishes the same key.
            // Both paths are on the same filesystem; there is never a remove gap.
            if rename(stagedOutput.path, output.path) != 0 {
                if !validPDF(output) { throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno)) }
            }
            trimCache(root: root)
            return output
        }
        private func stageSource(to destination: URL) throws -> Bool {
            let reader = try FileHandle(forReadingFrom: source)
            defer { try? reader.close() }
            let total = try reader.seekToEnd()
            try reader.seek(toOffset: 0)
            let header = try reader.read(upToCount: 4096) ?? Data()
            var offset: UInt64 = 0, length = total
            if header.starts(with: [0xC5, 0xD0, 0xD3, 0xC6]) {
                guard header.count >= 30 else { throw Failure.invalid }
                func uint32(_ start: Int) -> UInt64 { (0..<4).reduce(0) { $0 | UInt64(header[start + $1]) << ($1 * 8) } }
                offset = uint32(4); length = uint32(8)
                guard offset >= 30, offset <= total, length >= 4, length <= total - offset else { throw Failure.invalid }
            }
            try reader.seek(toOffset: offset)
            let signature = try reader.read(upToCount: Int(min(length, 4096))) ?? Data()
            guard signature.starts(with: Data("%!".utf8)) else { throw Failure.invalid }
            let firstLine = String(decoding: signature.prefix(while: { $0 != 10 && $0 != 13 }), as: UTF8.self)
            let eps = firstLine.contains("EPSF-") || ["eps", "epsf"].contains(source.pathExtension.lowercased())
            guard FileManager.default.createFile(atPath: destination.path, contents: nil,
                                                  attributes: [.posixPermissions: 0o600]) else { throw Failure.failed }
            let writer = try FileHandle(forWritingTo: destination)
            defer { try? writer.close() }
            try reader.seek(toOffset: offset)
            while length > 0 {
                try check()
                guard let bytes = try reader.read(upToCount: Int(min(length, 1_048_576))), !bytes.isEmpty else { throw Failure.invalid }
                try writer.write(contentsOf: bytes); length -= UInt64(bytes.count)
            }
            return eps
        }
        private func fileSize(_ url: URL) -> Int64 {
            // URL resourceValues caches the first observed size. The staging
            // PDF grows while GS writes it, so always stat the current file.
            ((try? FileManager.default.attributesOfItem(atPath: url.path)[.size]) as? NSNumber)?.int64Value ?? 0
        }
        private func validPDF(_ url: URL) -> Bool {
            guard fileSize(url) > 0,
                  let document = CGPDFDocument(url as CFURL), document.numberOfPages > 0,
                  let page = document.page(at: 1) else { return false }
            let size = page.getBoxRect(.mediaBox).size
            return size.width.isFinite && size.height.isFinite && size.width > 0 && size.height > 0
        }
        private func trimCache(root: URL) {
            let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey]
            guard let files = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: keys) else { return }
            let cached = files.filter { $0.lastPathComponent.hasPrefix("ps-") && $0.pathExtension == "pdf" }
                .compactMap { url -> (URL, Int, Date)? in
                    guard let values = try? url.resourceValues(forKeys: Set(keys)) else { return nil }
                    return (url, values.fileSize ?? 0, values.contentModificationDate ?? .distantPast)
                }.sorted { $0.2 < $1.2 }
            registryLock.lock()
            let active = Set(jobs.values.map { $0.output })
            registryLock.unlock()
            var size = cached.reduce(Int64(0)) { $0 + Int64($1.1) }
            // Leave a hand-off grace period between returning a URL and the
            // caller opening its CGPDFDocument data provider.
            for (url, bytes, modified) in cached where size > 2_048 * 1_024 * 1_024 && url != output
                && !active.contains(url) && Date().timeIntervalSince(modified) > 60 {
                try? FileManager.default.removeItem(at: url); size -= Int64(bytes)
            }
        }
    }
}
