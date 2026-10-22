import AppKit
import AVFoundation
import CryptoKit
import Darwin

enum CompatibilityMediaError: LocalizedError {
    case toolsUnavailable, unreadable, noMedia, invalidOutput, timedOut, insufficientSpace
    case conversionFailed(String)

    var errorDescription: String? {
        switch self {
        case .toolsUnavailable: return L10n.tr("应用内的兼容播放组件缺失，请重新安装完整版本。")
        case .unreadable: return L10n.tr("无法读取这个媒体文件。")
        case .noMedia: return L10n.tr("文件中没有可播放的音频或视频。")
        case .invalidOutput: return L10n.tr("无法生成有效的兼容播放文件。文件可能已损坏，或使用了尚不支持的编码。")
        case .timedOut: return L10n.tr("读取媒体信息超时。")
        case .insufficientSpace: return L10n.tr("兼容播放需要更多磁盘空间，或转换文件超过了 8 GB。请清理空间后重试。")
        case .conversionFailed(let detail):
            return L10n.tr("无法准备兼容播放。文件可能已损坏、受到保护，或使用了尚不支持的编码。") + (detail.isEmpty ? "" : "\n" + detail)
        }
    }
}

/// A cancellable local conversion. No shell, network URL, or external decoder
/// installation is used. Each request owns its processes and temporary files.
final class CompatibilityMedia: @unchecked Sendable {
    struct Information {
        let duration: Double
        let videoIndex: Int?
        let audioIndex: Int?
        let videoCodec: String?
        let audioCodec: String?
        let format: String?
        let pixelSize: CGSize
        var isAudioOnly: Bool { videoIndex == nil }
    }

    struct Prepared {
        let playbackURL: URL
        let information: Information
    }

    private let sourceURL: URL
    private let cacheDirectory: URL
    private let toolsDirectory: URL?
    private let allowRemux: Bool
    private let lock = NSLock()
    private var cancelled = false
    private var process: Process?
    private weak var thumbnailOperation: Operation?
    private var temporaryFiles: Set<URL> = []
    private var rejectedOutputs: Set<URL> = []
    private static let cacheLock = NSLock()
    private static let thumbnailQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 2; queue.qualityOfService = .utility
        return queue
    }()
    private static let cacheBudget: Int64 = 2 * 1_024 * 1_024 * 1_024
    private static let maximumOutput: Int64 = 8 * 1_024 * 1_024 * 1_024

    init(sourceURL: URL, cacheDirectory: URL? = nil, toolsDirectory: URL? = nil, allowRemux: Bool = true) {
        self.sourceURL = sourceURL
        self.cacheDirectory = cacheDirectory ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("com.lumaview.viewer/MediaCompatibility", isDirectory: true)
        self.toolsDirectory = toolsDirectory
        self.allowRemux = allowRemux
    }

    func prepare(progress: @escaping (String) -> Void) async throws -> Prepared {
        try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async { [self] in
                    do { continuation.resume(returning: try convert(progress: progress)) }
                    catch { continuation.resume(throwing: error) }
                }
            }
        }, onCancel: { [weak self] in self?.cancel() })
    }

    func cancel() {
        lock.lock()
        cancelled = true
        let active = process
        let queued = thumbnailOperation
        let files = temporaryFiles
        lock.unlock()
        queued?.cancel()
        Self.stop(active)
        files.forEach { try? FileManager.default.removeItem(at: $0) }
    }

    /// Called only for a generated item that AVFoundation could not open.
    func invalidate(_ playbackURL: URL) {
        guard playbackURL.deletingLastPathComponent().standardizedFileURL == cacheDirectory.standardizedFileURL,
              playbackURL.lastPathComponent.hasPrefix("lv3-") else { return }
        lock.lock(); rejectedOutputs.insert(playbackURL); lock.unlock()
        Self.cacheLock.lock(); defer { Self.cacheLock.unlock() }
        try? FileManager.default.removeItem(at: playbackURL)
    }

    /// Use after the native thumbnail fails. The independent queue limits cover
    /// extraction to two low-priority processes; it never converts a whole movie.
    @discardableResult
    static func thumbnail(url: URL, completion: @escaping (NSImage?, Double?) -> Void) -> CompatibilityMedia {
        let job = CompatibilityMedia(sourceURL: url)
        let operation = BlockOperation()
        job.lock.lock(); job.thumbnailOperation = operation; job.lock.unlock()
        operation.addExecutionBlock { [weak operation] in
            guard operation?.isCancelled == false, (try? job.checkCancelled()) != nil else { return }
            var thumbnail: NSImage?
            var duration: Double?
            do {
                let info = try job.probe()
                duration = info.duration > 0 ? info.duration : nil
                if let video = info.videoIndex {
                    let output = FileManager.default.temporaryDirectory.appendingPathComponent("lumaview-cover-\(UUID().uuidString).png")
                    job.track(output)
                    defer { job.untrackAndRemove(output) }
                    var args = ["-hide_banner", "-loglevel", "error", "-nostdin", "-protocol_whitelist", "file,pipe", "-threads", "2"]
                    if info.duration > 0 { args += ["-ss", String(min(1, info.duration * 0.1))] }
                    args += ["-i", url.path, "-map", "0:\(video)", "-frames:v", "1", "-vf", "scale=256:256:force_original_aspect_ratio=decrease", "-an", "-sn", "-dn", "-threads", "1", "-y", output.path]
                    _ = try job.run(tool: "ffmpeg", arguments: args, timeout: 20)
                    if let data = try? Data(contentsOf: output) { thumbnail = NSImage(data: data) }
                }
            } catch { /* The caller displays its existing placeholder. */ }
            let result = thumbnail, seconds = duration
            DispatchQueue.main.async {
                guard (try? job.checkCancelled()) != nil else { return }
                completion(result, seconds)
            }
        }
        thumbnailQueue.addOperation(operation)
        return job
    }

    /// Read an attached album cover from the original source even when playback
    /// uses a metadata-free compatibility cache. The returned job is cancellable.
    @discardableResult
    static func audioCover(url: URL, completion: @escaping (CGImage?) -> Void) -> CompatibilityMedia {
        let job = CompatibilityMedia(sourceURL: url)
        thumbnailQueue.addOperation {
            var image: CGImage?
            do {
                let result = try job.run(tool: "ffprobe", arguments: ["-v", "error", "-protocol_whitelist", "file,pipe",
                    "-show_streams", "-of", "json", url.path], timeout: 15)
                if let root = try JSONSerialization.jsonObject(with: result.stdout) as? [String: Any],
                   let streams = root["streams"] as? [[String: Any]],
                   let cover = streams.first(where: { stream in
                       let disposition = stream["disposition"] as? [String: Any]
                       return stream["codec_type"] as? String == "video" && (disposition?["attached_pic"] as? Int ?? 0) == 1
                   }), let index = cover["index"] as? Int,
                   let width = Self.number(cover["width"]), let height = Self.number(cover["height"]),
                   width.isFinite, height.isFinite, width > 0, height > 0, width * height <= 100_000_000 {
                    let output = FileManager.default.temporaryDirectory.appendingPathComponent("lumaview-audio-cover-\(UUID().uuidString).png")
                    job.track(output)
                    defer { job.untrackAndRemove(output) }
                    _ = try job.run(tool: "ffmpeg", arguments: ["-hide_banner", "-loglevel", "error", "-nostdin",
                        "-protocol_whitelist", "file,pipe", "-threads", "2", "-i", url.path, "-map", "0:\(index)",
                        "-frames:v", "1", "-vf", "scale=2048:2048:force_original_aspect_ratio=decrease",
                        "-an", "-sn", "-dn", "-threads", "1", "-y", output.path], timeout: 20)
                    if let bytes = try? output.resourceValues(forKeys: [.fileSizeKey]).fileSize, bytes <= 32 * 1_024 * 1_024,
                       let data = try? Data(contentsOf: output) { image = AudioArtwork.decodeCover(data) }
                }
                try job.checkCancelled()
            } catch { /* A missing or invalid cover leaves the waveform visible. */ }
            let finished = image
            DispatchQueue.main.async {
                // A cancelled job must never deliver a stale cover to a reused canvas.
                guard (try? job.checkCancelled()) != nil else { return }
                completion(finished)
            }
        }
        return job
    }

    private func convert(progress: @escaping (String) -> Void) throws -> Prepared {
        try checkCancelled()
        progress(L10n.tr("正在准备兼容播放…"))
        let information = try probe()
        try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        let key = try cacheKey()
        var variants: [(String, String)] = information.isAudioOnly
            ? [("audio", "m4a")]
            : [("h264", "mp4"), ("mpeg4", "mp4"), ("prores", "mov")]
        if allowRemux, ["h264", "hevc"].contains(information.videoCodec ?? "") { variants.insert(("remux", "mp4"), at: 0) }
        lock.lock(); let rejected = rejectedOutputs; lock.unlock()
        variants.removeAll { rejected.contains(cacheDirectory.appendingPathComponent("\(key)-\($0.0).\($0.1)")) }
        for (codec, ext) in variants {
            let candidate = cacheDirectory.appendingPathComponent("\(key)-\(codec).\(ext)")
            if let size = try? candidate.resourceValues(forKeys: [.fileSizeKey]).fileSize, size > 0 {
                try checkCancelled()
                try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: candidate.path)
                progress(L10n.tr("正在打开兼容播放缓存…"))
                return Prepared(playbackURL: candidate, information: information)
            }
        }
        try cleanCache(keeping: nil)
        var lastError: Error = CompatibilityMediaError.invalidOutput
        for (codec, ext) in variants {
            try checkCancelled()
            let temporary = cacheDirectory.appendingPathComponent(".partial-\(UUID().uuidString).\(ext)")
            track(temporary)
            defer { untrackAndRemove(temporary) }
            let final = cacheDirectory.appendingPathComponent("\(key)-\(codec).\(ext)")
            var arguments = ["-hide_banner", "-loglevel", "error", "-nostdin", "-protocol_whitelist", "file,pipe", "-threads", "2", "-i", sourceURL.path]
            if let video = information.videoIndex { arguments += ["-map", "0:\(video)"] }
            if let audio = information.audioIndex { arguments += ["-map", "0:\(audio)"] }
            arguments += ["-sn", "-dn", "-map_metadata", "-1", "-map_chapters", "-1"]
            switch codec {
            case "remux":
                arguments += ["-c:v", "copy"]
                if information.videoCodec == "hevc" { arguments += ["-tag:v", "hvc1"] }
            case "h264":
                arguments += ["-c:v", "h264_videotoolbox", "-allow_sw", "1", "-pix_fmt", "yuv420p", "-b:v", "6000k", "-vf", "pad=ceil(iw/2)*2:ceil(ih/2)*2"]
            case "mpeg4":
                arguments += ["-c:v", "mpeg4", "-q:v", "3", "-pix_fmt", "yuv420p", "-vf", "pad=ceil(iw/2)*2:ceil(ih/2)*2"]
            case "prores": arguments += ["-c:v", "prores_ks", "-profile:v", "1", "-pix_fmt", "yuv422p10le"]
            default: arguments += ["-vn"]
            }
            if codec == "remux", information.audioCodec == "aac" { arguments += ["-c:a", "copy"] }
            else if information.audioIndex != nil { arguments += ["-c:a", "aac", "-b:a", "256k", "-ac", "2", "-ar", "48000"] }
            else { arguments += ["-an"] }
            arguments += ["-max_muxing_queue_size", "4096", "-threads", "2", "-movflags", "+faststart", "-progress", "pipe:1", "-nostats", "-y", temporary.path]
            var lastPercentage = -1
            var diskCheckDate = Date.distantPast
            do {
                try checkDiskSpace(output: temporary)
                _ = try run(tool: "ffmpeg", arguments: arguments, timeout: 0) { [self] line in
                    if line.hasPrefix("out_time_us="), let microseconds = Double(line.dropFirst(12)), microseconds.isFinite, information.duration > 0 {
                        let fraction = microseconds / 1_000_000 / information.duration
                        let percentage = Int(max(0, min(99, fraction * 100)))
                        if percentage != lastPercentage {
                            lastPercentage = percentage
                            progress(L10n.format(codec == "remux" ? "正在准备兼容容器… %d%%" : "正在准备兼容播放… %d%%", percentage))
                        }
                    }
                    if Date().timeIntervalSince(diskCheckDate) > 1 {
                        diskCheckDate = Date()
                        try checkDiskSpace(output: temporary)
                    }
                }
                try checkCancelled()
                guard let size = try? temporary.resourceValues(forKeys: [.fileSizeKey]).fileSize, size > 0 else { throw CompatibilityMediaError.invalidOutput }
                // Probe the completed output before publishing it; a partial or
                // silently truncated movie must never become a reusable cache.
                let result = try probe(url: temporary)
                guard result.videoIndex != nil || result.audioIndex != nil,
                      result.isAudioOnly == information.isAudioOnly,
                      information.duration <= 0 || result.duration >= information.duration - max(1, information.duration * 0.01) else {
                    throw CompatibilityMediaError.invalidOutput
                }
                try checkCancelled()
                // Fast remuxing can cross the size limit between progress ticks.
                // Check the final file again before it becomes a reusable cache.
                try checkDiskSpace(output: temporary)
                Self.cacheLock.lock()
                do {
                    if FileManager.default.fileExists(atPath: final.path) { try FileManager.default.removeItem(at: temporary) }
                    else { try FileManager.default.moveItem(at: temporary, to: final) }
                    Self.cacheLock.unlock()
                } catch { Self.cacheLock.unlock(); throw error }
                try checkCancelled()
                try cleanCache(keeping: final)
                progress(L10n.tr("兼容播放已准备好"))
                return Prepared(playbackURL: final, information: information)
            } catch {
                if error is CancellationError { throw error }
                if case CompatibilityMediaError.insufficientSpace = error { throw error }
                lastError = error
                if codec != variants.last?.0 { progress(L10n.tr("正在尝试另一种兼容编码…")) }
            }
        }
        throw lastError
    }

    private func probe(url: URL? = nil) throws -> Information {
        let input = url ?? sourceURL
        guard input.isFileURL, FileManager.default.isReadableFile(atPath: input.path) else { throw CompatibilityMediaError.unreadable }
        let result = try run(tool: "ffprobe", arguments: ["-v", "error", "-protocol_whitelist", "file,pipe", "-show_streams", "-show_format", "-of", "json", input.path], timeout: 20)
        guard let root = try JSONSerialization.jsonObject(with: result.stdout) as? [String: Any],
              let streams = root["streams"] as? [[String: Any]] else { throw CompatibilityMediaError.noMedia }
        let video = streams.first { stream in
            let disposition = stream["disposition"] as? [String: Any]
            return stream["codec_type"] as? String == "video" && (disposition?["attached_pic"] as? Int ?? 0) == 0
        }
        let audio = streams.first { $0["codec_type"] as? String == "audio" }
        guard video != nil || audio != nil else { throw CompatibilityMediaError.noMedia }
        let format = root["format"] as? [String: Any]
        let seconds = Self.number(format?["duration"]) ?? Self.number(video?["duration"]) ?? Self.number(audio?["duration"]) ?? 0
        let width = Self.number(video?["width"]) ?? 0, height = Self.number(video?["height"]) ?? 0
        guard width.isFinite, height.isFinite, width >= 0, height >= 0,
              width <= 65_536, height <= 65_536, width * height <= 150_000_000,
              seconds.isFinite, seconds >= 0 else { throw CompatibilityMediaError.invalidOutput }
        return Information(duration: seconds, videoIndex: video?["index"] as? Int, audioIndex: audio?["index"] as? Int,
                           videoCodec: video?["codec_name"] as? String, audioCodec: audio?["codec_name"] as? String,
                           format: format?["format_long_name"] as? String, pixelSize: CGSize(width: width, height: height))
    }

    private static func number(_ value: Any?) -> Double? {
        if let value = value as? NSNumber { return value.doubleValue }
        if let value = value as? String { return Double(value) }
        return nil
    }

    private func cacheKey() throws -> String {
        let canonical = sourceURL.standardizedFileURL.resolvingSymlinksInPath()
        let values = try canonical.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
        let signature = canonical.path + "\n" + String(values.fileSize ?? 0) + "\n" + String(values.contentModificationDate?.timeIntervalSince1970 ?? 0)
        return "lv3-" + SHA256.hash(data: Data(signature.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private func cleanCache(keeping: URL?) throws {
        Self.cacheLock.lock(); defer { Self.cacheLock.unlock() }
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey]
        let files = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: Array(keys))
        // A force-quit cannot run cancellation cleanup. Only remove abandoned
        // partial files after a day, so another live conversion stays untouched.
        for file in files where file.lastPathComponent.hasPrefix(".partial-") {
            if let values = try? file.resourceValues(forKeys: keys), values.isRegularFile == true,
               Date().timeIntervalSince(values.contentModificationDate ?? Date()) > 24 * 3_600 {
                try? FileManager.default.removeItem(at: file)
            }
        }
        let entries = files.compactMap { file -> (URL, Int64, Date)? in
            guard file.lastPathComponent.hasPrefix("lv3-"), let values = try? file.resourceValues(forKeys: keys), values.isRegularFile == true else { return nil }
            return (file, Int64(values.fileSize ?? 0), values.contentModificationDate ?? .distantPast)
        }.sorted { $0.2 < $1.2 }
        var size = entries.reduce(Int64(0)) { $0 + $1.1 }
        for (file, bytes, date) in entries where file != keeping {
            if size > Self.cacheBudget || Date().timeIntervalSince(date) > 30 * 24 * 3_600 {
                if (try? FileManager.default.removeItem(at: file)) != nil { size -= bytes }
            }
        }
    }

    private func checkDiskSpace(output: URL) throws {
        let size = (try? output.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        let values = try? cacheDirectory.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        let available = values?.volumeAvailableCapacityForImportantUsage ?? Int64.max
        guard size < Self.maximumOutput, available > 512 * 1_024 * 1_024 else { throw CompatibilityMediaError.insufficientSpace }
    }

    private func toolURL(_ name: String) throws -> URL {
        let development = ProcessInfo.processInfo.environment["LUMAVIEW_MEDIA_TOOLS"].map { URL(fileURLWithPath: $0, isDirectory: true) }
        guard let directory = toolsDirectory ?? development ?? Bundle.main.resourceURL?.appendingPathComponent("MediaTools", isDirectory: true) else { throw CompatibilityMediaError.toolsUnavailable }
        let result = directory.appendingPathComponent(name)
        guard result.isFileURL, FileManager.default.isExecutableFile(atPath: result.path) else { throw CompatibilityMediaError.toolsUnavailable }
        return result
    }

    private struct ProcessResult { let stdout: Data }

    /// Pipe readers are drained concurrently, with bounded retained output. The
    /// process runs on a worker; neither waitUntilExit nor pipe reads block main.
    private func run(tool: String, arguments: [String], timeout: TimeInterval, progress: ((String) throws -> Void)? = nil) throws -> ProcessResult {
        try checkCancelled()
        let task = Process()
        task.executableURL = try toolURL(tool); task.arguments = arguments
        task.standardInput = FileHandle.nullDevice
        let output = Pipe(), errors = Pipe()
        task.standardOutput = output; task.standardError = errors
        lock.lock()
        if cancelled { lock.unlock(); throw CancellationError() }
        process = task
        do { try task.run(); lock.unlock() }
        catch { process = nil; lock.unlock(); throw error }
        try? output.fileHandleForWriting.close(); try? errors.fileHandleForWriting.close()
        let state = ProcessOutput()
        let readers = DispatchGroup()
        for (handle, isOutput) in [(output.fileHandleForReading, true), (errors.fileHandleForReading, false)] {
            readers.enter()
            DispatchQueue.global(qos: .utility).async {
                defer { try? handle.close(); readers.leave() }
                var lineBuffer = Data()
                while let data = try? handle.read(upToCount: 16_384), !data.isEmpty {
                    state.append(data, stdout: isOutput)
                    if isOutput, let progress {
                        lineBuffer.append(data)
                        while let newline = lineBuffer.firstIndex(of: 10) {
                            let line = String(decoding: lineBuffer[..<newline], as: UTF8.self)
                            lineBuffer.removeSubrange(...newline)
                            do { try progress(line) }
                            catch { state.record(error); Self.stop(task) }
                        }
                        if lineBuffer.count > 65_536 { lineBuffer.removeAll() }
                    }
                }
            }
        }
        let timeoutItem = DispatchWorkItem {
            if task.isRunning { state.record(CompatibilityMediaError.timedOut); Self.stop(task) }
        }
        if timeout > 0 { DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + timeout, execute: timeoutItem) }
        task.waitUntilExit()
        timeoutItem.cancel(); readers.wait()
        lock.lock(); if process === task { process = nil }; lock.unlock()
        try checkCancelled()
        if let error = state.error { throw error }
        guard task.terminationStatus == 0 else {
            let tail = String(decoding: state.stderr.suffix(1_024), as: UTF8.self)
                .split(separator: "\n").suffix(3).joined(separator: "\n")
            throw CompatibilityMediaError.conversionFailed(tail)
        }
        return ProcessResult(stdout: state.stdout)
    }

    private final class ProcessOutput {
        let lock = NSLock()
        private(set) var stdout = Data(), stderr = Data()
        private(set) var error: Error?
        func append(_ data: Data, stdout isOutput: Bool) {
            lock.lock(); defer { lock.unlock() }
            if isOutput { stdout.append(data); if stdout.count > 2_097_152 { stdout.removeFirst(stdout.count - 2_097_152) } }
            else { stderr.append(data); if stderr.count > 65_536 { stderr.removeFirst(stderr.count - 65_536) } }
        }
        func record(_ value: Error) { lock.lock(); if error == nil { error = value }; lock.unlock() }
    }

    private static func stop(_ task: Process?) {
        guard let task, task.isRunning else { return }
        let pid = task.processIdentifier
        if pid > 0 { kill(pid, SIGTERM) }
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 1) {
            if task.isRunning, task.processIdentifier == pid, pid > 0 { kill(pid, SIGKILL) }
        }
    }

    private func checkCancelled() throws {
        lock.lock(); let value = cancelled; lock.unlock()
        if value { throw CancellationError() }
    }
    private func track(_ url: URL) { lock.lock(); temporaryFiles.insert(url); lock.unlock() }
    private func untrackAndRemove(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
        lock.lock(); temporaryFiles.remove(url); lock.unlock()
    }
    deinit { cancel() }
}
