import AppKit
import AVFoundation

enum VideoLoadError: LocalizedError {
    case unreadable
    case unsupported
    case noVideoTrack
    case invalidDimensions
    case invalidDuration
    case preparationInProgress
    case timedOut
    case protectedContent

    var errorDescription: String? {
        switch self {
        case .unreadable: return L10n.tr("无法读取这个音视频文件。")
        case .unsupported: return L10n.tr("无法播放这个音视频文件的格式或编码。")
        case .noVideoTrack: return L10n.tr("这个文件没有可播放的音频或视频。")
        case .invalidDimensions: return L10n.tr("无法读取视频的画面尺寸。")
        case .invalidDuration: return L10n.tr("无法读取视频的有效时长。")
        case .preparationInProgress: return L10n.tr("音视频仍在准备中。")
        case .timedOut: return L10n.tr("准备音视频超时，请重试或打开其他文件。")
        case .protectedContent: return L10n.tr("无法播放受到 DRM 保护的媒体文件。")
        }
    }
}

enum VideoFrameCaptureError: LocalizedError {
    case unavailable
    case audioOnly

    var errorDescription: String? {
        switch self {
        case .unavailable: return L10n.tr("暂时无法复制当前视频画面，请稍后重试。")
        case .audioOnly: return L10n.tr("音频文件没有可复制的视频画面。")
        }
    }
}

/// One local video and its playback lifecycle. Public operations are marshalled
/// to main, and every callback is delivered on main. No controller actor needed.
final class VideoSession {
    let player = AVPlayer()
    let url: URL
    private(set) var pixelSize = CGSize.zero
    private(set) var duration: Double = 0
    private(set) var metadata: [(String, String)] = []
    private(set) var isAudioOnly = false
    private(set) var usedCompatibilityDecoder = false
    private(set) var audioWaveform: AudioWaveform?
    private(set) var audioCover: CGImage?
    /// Called on main when either the original embedded cover or sample-derived
    /// waveform becomes available. A cover always takes precedence in the UI.
    var onAudioVisualChanged: (() -> Void)?
    var onPreparationProgress: ((String) -> Void)?
    var onUpdate: (() -> Void)?
    var onEnded: (() -> Void)?
    var onFailure: ((String) -> Void)?

    var currentTime: Double {
        let seconds = player.currentTime().seconds
        return seconds.isFinite ? max(0, min(duration, seconds)) : 0
    }
    var isPlaying: Bool { !disposed && prepared && desiredPlayback && !hasEnded }

    private var asset: AVURLAsset
    private var playbackURL: URL
    private var compatibility: CompatibilityMedia?
    private var compatibilityInformation: CompatibilityMedia.Information?
    private var preparationTask: Task<Void, Never>?
    private var preparationTimeout: DispatchWorkItem?
    private var preparationCompletion: ((Result<VideoSession, Error>) -> Void)?
    private var observations: [NSKeyValueObservation] = []
    private var notifications: [NSObjectProtocol] = []
    private var timeObserver: Any?
    private var disposed = false
    private var prepared = false
    private var desiredPlayback = false
    private var hasEnded = false
    private var failureReported = false
    private var retriedFirstFrame = false
    private var generation: UInt = 0
    private var seekGeneration: UInt = 0
    private var pendingSeekTarget: Double?
    private var waveformTask: Task<Void, Never>?
    private var coverTask: Task<Void, Never>?
    private var coverJob: CompatibilityMedia?
    private var audioVisualGeneration: UInt?
    private var frameCaptureTask: Task<Void, Never>?
    private var frameCaptureGenerator: AVAssetImageGenerator?
    private var frameCaptureGeneration: UInt = 0

    init(url: URL) {
        self.url = url
        playbackURL = url
        asset = AVURLAsset(url: url)
        player.actionAtItemEnd = .pause
    }

    func prepare(completion: @escaping (Result<VideoSession, Error>) -> Void) {
        onMain { [self] in
            guard !disposed else { return }
            if prepared { completion(.success(self)); return }
            guard !failureReported else { completion(.failure(VideoLoadError.unsupported)); return }
            guard preparationCompletion == nil else { completion(.failure(VideoLoadError.preparationInProgress)); return }
            guard url.isFileURL, FileManager.default.isReadableFile(atPath: url.path) else {
                completion(.failure(VideoLoadError.unreadable)); return
            }
            preparationCompletion = completion
            beginAssetPreparation(at: url)
        }
    }

    private func beginAssetPreparation(at playbackURL: URL) {
        cancelFrameCapture()
        cancelAudioVisuals()
        generation &+= 1
        let request = generation
        self.playbackURL = playbackURL
        asset.cancelLoading()
        asset = AVURLAsset(url: playbackURL)
        let source = asset, sourceURL = url, compatibilityInfo = compatibilityInformation
        let timeout = DispatchWorkItem { [weak self] in
            guard let self, !self.disposed, self.generation == request, !self.prepared else { return }
            self.handlePreparationFailure(VideoLoadError.timedOut, request: request)
        }
        preparationTimeout?.cancel(); preparationTimeout = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 20, execute: timeout)
        preparationTask = Task.detached(priority: .userInitiated) { [weak self] in
            do {
                if try await source.load(.hasProtectedContent) { throw VideoLoadError.protectedContent }
                guard try await source.load(.isPlayable) else { throw VideoLoadError.unsupported }
                let tracks = try await source.loadTracks(withMediaType: .video)
                let audioTracks = try await source.loadTracks(withMediaType: .audio)
                guard !tracks.isEmpty || !audioTracks.isEmpty else { throw VideoLoadError.noVideoTrack }
                let audioOnly = tracks.isEmpty
                var displayed = CGSize(width: 960, height: 600)
                var frameRate: Float = 0
                if let track = tracks.first {
                    async let naturalSize = track.load(.naturalSize)
                    async let transform = track.load(.preferredTransform)
                    let (size, orientation) = try await (naturalSize, transform)
                    let transformed = CGRect(origin: .zero, size: size).applying(orientation).standardized.size
                    displayed = CGSize(width: transformed.width.rounded(), height: transformed.height.rounded())
                    guard displayed.width.isFinite, displayed.height.isFinite, displayed.width > 0, displayed.height > 0,
                          displayed.width <= 65_536, displayed.height <= 65_536,
                          displayed.width * displayed.height <= 150_000_000 else { throw VideoLoadError.invalidDimensions }
                    frameRate = (try? await track.load(.nominalFrameRate)) ?? 0
                }
                let time = try await source.load(.duration)
                let seconds = time.seconds
                guard seconds.isFinite, seconds > 0, seconds < Double(Int64.max / 600) else { throw VideoLoadError.invalidDuration }
                let values = try? sourceURL.resourceValues(forKeys: [.fileSizeKey])
                var rows: [(String, String)] = [
                    ("文件名", sourceURL.lastPathComponent),
                    ("类型", sourceURL.pathExtension.uppercased() + (audioOnly ? " 音频" : " 视频"))
                ]
                if !audioOnly { rows.append(("尺寸", "\(Int(displayed.width)) × \(Int(displayed.height)) 像素")) }
                rows.append(("时长", String(format: "%.1f 秒", seconds)))
                if frameRate.isFinite && frameRate > 0 { rows.append(("帧率", String(format: "%.2f fps", frameRate))) }
                if let info = compatibilityInfo {
                    if let format = info.format { rows.append(("原始格式", format)) }
                    if let codec = info.videoCodec { rows.append(("原始视频编码", codec.uppercased())) }
                    if let codec = info.audioCodec { rows.append(("原始音频编码", codec.uppercased())) }
                    rows.append(("播放方式", "兼容播放（本地转换缓存）"))
                }
                if let bytes = values?.fileSize { rows.append(("文件大小", ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file))) }
                rows.append(("位置", sourceURL.deletingLastPathComponent().path))
                try Task.checkCancellation()
                let finalMetadata = rows, finalSize = displayed
                await MainActor.run { [weak self] in
                    guard let self, !self.disposed, self.generation == request else { return }
                    self.pixelSize = finalSize; self.duration = seconds; self.metadata = finalMetadata; self.isAudioOnly = audioOnly
                    self.installPlayerItem(request: request)
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run { [weak self] in self?.handlePreparationFailure(error, request: request) }
            }
        }
    }

    private func handlePreparationFailure(_ error: Error, request: UInt) {
        guard !disposed, generation == request else { return }
        if case VideoLoadError.protectedContent = error { fail(error); return }
        if usedCompatibilityDecoder || prepared {
            if !prepared, usedCompatibilityDecoder, let converter = compatibility, playbackURL != url {
                converter.invalidate(playbackURL)
                beginCompatibility(using: converter)
                return
            }
            fail(error); return
        }
        beginCompatibility()
    }

    private func beginCompatibility(using existing: CompatibilityMedia? = nil, allowRemux: Bool = true) {
        cancelFrameCapture()
        generation &+= 1
        let request = generation
        preparationTask?.cancel(); preparationTask = nil
        preparationTimeout?.cancel(); preparationTimeout = nil
        asset.cancelLoading(); player.pause(); removeObservers()
        usedCompatibilityDecoder = true
        let converter = existing ?? CompatibilityMedia(sourceURL: url, allowRemux: allowRemux)
        compatibility = converter
        onPreparationProgress?(L10n.tr("正在准备兼容播放…"))
        preparationTask = Task.detached(priority: .userInitiated) { [weak self] in
            do {
                let result = try await converter.prepare { [weak self] message in
                    self?.onMain { [weak self] in
                        guard let self, !self.disposed, self.generation == request else { return }
                        self.onPreparationProgress?(message)
                    }
                }
                try Task.checkCancellation()
                await MainActor.run { [weak self] in
                    guard let self, !self.disposed, self.generation == request else { return }
                    self.compatibilityInformation = result.information
                    self.beginAssetPreparation(at: result.playbackURL)
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run { [weak self] in
                    guard let self, !self.disposed, self.generation == request else { return }
                    self.fail(error)
                }
            }
        }
    }

    /// Some system codecs report a ready item but never deliver a displayable
    /// frame. The controller may request this once after its first-frame timeout.
    func retryWithCompatibility(completion: @escaping (Result<VideoSession, Error>) -> Void) {
        onMain { [weak self] in
            guard let self, !self.disposed else { return }
            guard !self.retriedFirstFrame, !self.failureReported else { completion(.failure(VideoLoadError.unsupported)); return }
            // A remux retains the original codec/profile. If it still cannot
            // deliver a frame, one actual re-encode remains useful. A failed
            // already-transcoded frame must not trigger an unbounded retry.
            let wasRemuxed = self.usedCompatibilityDecoder && self.playbackURL.lastPathComponent.hasSuffix("-remux.mp4")
            guard !self.usedCompatibilityDecoder || wasRemuxed else { completion(.failure(VideoLoadError.unsupported)); return }
            guard self.preparationCompletion == nil else { completion(.failure(VideoLoadError.preparationInProgress)); return }
            self.retriedFirstFrame = true
            if wasRemuxed { self.compatibility?.invalidate(self.playbackURL) }
            self.prepared = false; self.desiredPlayback = false; self.hasEnded = false
            self.seekGeneration &+= 1; self.pendingSeekTarget = nil
            self.player.pause(); self.player.currentItem?.cancelPendingSeeks()
            self.preparationCompletion = completion
            self.beginCompatibility(allowRemux: false)
        }
    }

    private func installPlayerItem(request: UInt) {
        let item = AVPlayerItem(asset: asset)
        observations.append(item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            self?.onMain { [weak self] in
                guard let self, !self.disposed, self.generation == request else { return }
                if item.status == .readyToPlay {
                    self.prepared = true
                    self.preparationTimeout?.cancel(); self.preparationTimeout = nil
                    self.preparationTask = nil
                    let completion = self.preparationCompletion; self.preparationCompletion = nil
                    completion?(.success(self)); self.onUpdate?()
                    self.beginAudioVisuals(request: request)
                } else if item.status == .failed {
                    self.handlePreparationFailure(item.error ?? VideoLoadError.unsupported, request: request)
                }
            }
        })
        observations.append(player.observe(\.timeControlStatus, options: [.new]) { [weak self] _, _ in
            self?.onMain { [weak self] in guard let self, !self.disposed else { return }; self.onUpdate?() }
        })
        notifications.append(NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { [weak self] _ in
            guard let self, !self.disposed, !self.hasEnded else { return }
            self.hasEnded = true; self.desiredPlayback = false; self.onUpdate?(); self.onEnded?()
        })
        notifications.append(NotificationCenter.default.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime, object: item, queue: .main) { [weak self] note in
            guard let self, !self.disposed else { return }
            self.handlePreparationFailure(note.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error ?? VideoLoadError.unsupported, request: request)
        })
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { [weak self] _ in
            guard let self, !self.disposed, self.prepared else { return }
            self.onUpdate?()
        }
        player.replaceCurrentItem(with: item)
    }

    func play() {
        onMain { [weak self] in
            guard let self, !self.disposed, self.prepared else { return }
            self.desiredPlayback = true
            if self.pendingSeekTarget != nil { self.onUpdate?(); return }
            if self.hasEnded || self.currentTime >= self.duration - 0.02 { self.seek(to: 0) }
            else { self.player.play() }
            self.onUpdate?()
        }
    }

    func pause() {
        onMain { [weak self] in
            guard let self, !self.disposed else { return }
            self.desiredPlayback = false; self.player.pause(); self.onUpdate?()
        }
    }

    func togglePlayback() {
        onMain { [weak self] in
            guard let self, !self.disposed else { return }
            if self.isPlaying { self.pause() } else { self.play() }
        }
    }

    func seek(to seconds: Double) {
        onMain { [weak self] in
            guard let self, !self.disposed, self.prepared, seconds.isFinite else { return }
            let target = max(0, min(self.duration, seconds))
            self.seekGeneration &+= 1
            let request = self.seekGeneration
            self.pendingSeekTarget = target
            self.hasEnded = false
            self.player.currentItem?.cancelPendingSeeks()
            self.player.seek(to: CMTime(seconds: target, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] finished in
                self?.onMain { [weak self] in
                    guard let self, !self.disposed, self.seekGeneration == request else { return }
                    self.pendingSeekTarget = nil
                    if finished && self.desiredPlayback { self.player.play() }
                    else if !self.desiredPlayback { self.player.pause() }
                    self.onUpdate?()
                }
            }
        }
    }

    func seek(by delta: Double) {
        onMain { [weak self] in
            guard let self, delta.isFinite else { return }
            self.seek(to: (self.pendingSeekTarget ?? self.currentTime) + delta)
        }
    }

    /// Decode the frame visible at the instant this method is called. The
    /// player item owns the actual playable asset (possibly a converted file),
    /// so extracting from the original URL could fail or capture another frame.
    /// The generator never seeks or pauses the player and applies track rotation.
    /// A newer request or disposal silently cancels the previous completion.
    func captureCurrentFrame(at time: CMTime? = nil, completion: @escaping (Result<CGImage, Error>) -> Void) {
        onMain { [weak self] in
            guard let self else { return }
            self.cancelFrameCapture()
            guard !self.disposed, self.prepared, let item = self.player.currentItem,
                  item.status == .readyToPlay else {
                completion(.failure(VideoFrameCaptureError.unavailable)); return
            }
            guard !self.isAudioOnly else {
                completion(.failure(VideoFrameCaptureError.audioOnly)); return
            }
            let request = self.frameCaptureGeneration, sessionRequest = self.generation
            // Duration is the exclusive endpoint of the track. At playback end,
            // ask for the instant immediately before it to obtain the last frame.
            let snapshot = time?.seconds ?? self.currentTime
            guard snapshot.isFinite else { completion(.failure(VideoFrameCaptureError.unavailable)); return }
            let seconds = max(0, min(snapshot, max(0, self.duration - 1.0 / 60_000)))
            let requestedTime = CMTime(seconds: seconds, preferredTimescale: 60_000)
            let generator = AVAssetImageGenerator(asset: item.asset)
            generator.appliesPreferredTrackTransform = true
            generator.videoComposition = item.videoComposition
            generator.requestedTimeToleranceBefore = .zero
            generator.requestedTimeToleranceAfter = .zero
            self.frameCaptureGenerator = generator
            self.frameCaptureTask = Task.detached(priority: .userInitiated) { [weak self] in
                let result: Result<CGImage, Error>
                do {
                    var frameTime = requestedTime
                    // An audio track can outlast the video. The visible player
                    // keeps its last video frame while that audio continues;
                    // the asset's overall duration is not a valid video bound.
                    if let track = try? await item.asset.loadTracks(withMediaType: .video).first,
                       let range = try? await track.load(.timeRange) {
                        let start = range.start.seconds, end = CMTimeRangeGetEnd(range).seconds
                        if start.isFinite, end.isFinite, end > start, frameTime.seconds >= end {
                            frameTime = CMTime(seconds: max(start, end - 1.0 / 60_000), preferredTimescale: 60_000)
                        }
                    }
                    try Task.checkCancellation()
                    let frame = try await generator.image(at: frameTime)
                    try Task.checkCancellation()
                    result = .success(frame.image)
                } catch {
                    guard !Task.isCancelled else { return }
                    result = .failure(error)
                }
                await MainActor.run { [weak self] in
                    guard let self, !self.disposed, self.generation == sessionRequest,
                          self.frameCaptureGeneration == request,
                          self.player.currentItem === item else { return }
                    self.frameCaptureTask = nil; self.frameCaptureGenerator = nil
                    completion(result)
                }
            }
        }
    }

    func cancelFrameCapture() {
        onMain { [weak self] in
            guard let self else { return }
            self.frameCaptureGeneration &+= 1
            self.frameCaptureTask?.cancel(); self.frameCaptureTask = nil
            self.frameCaptureGenerator?.cancelAllCGImageGeneration(); self.frameCaptureGenerator = nil
        }
    }

    private func beginAudioVisuals(request: UInt) {
        guard isAudioOnly, !disposed, generation == request, audioVisualGeneration != request else { return }
        audioVisualGeneration = request
        let originalURL = url
        coverTask = Task.detached(priority: .utility) { [weak self] in
            let original = AVURLAsset(url: originalURL)
            defer { original.cancelLoading() }
            var cover: CGImage?
            if let metadata = try? await original.load(.commonMetadata) {
                for item in metadata where item.commonKey == .commonKeyArtwork {
                    guard !Task.isCancelled else { return }
                    if let data = try? await item.load(.dataValue), let decoded = AudioArtwork.decodeCover(data) {
                        cover = decoded; break
                    }
                }
            }
            guard !Task.isCancelled else { return }
            let nativeCover = cover
            await MainActor.run { [weak self] in
                guard let self, !self.disposed, self.generation == request else { return }
                self.coverTask = nil
                if let nativeCover { self.installAudioCover(nativeCover, request: request) }
                else {
                    self.coverJob = CompatibilityMedia.audioCover(url: originalURL) { [weak self] image in
                        guard let self, !self.disposed, self.generation == request else { return }
                        self.coverJob = nil
                        if let image { self.installAudioCover(image, request: request) }
                        else { self.beginAudioWaveform(request: request) }
                    }
                }
            }
        }
    }

    private func beginAudioWaveform(request: UInt) {
        guard !disposed, generation == request, audioCover == nil else { return }
        let decodedURL = playbackURL
        waveformTask = Task.detached(priority: .utility) { [weak self] in
            do {
                let waveform = try await AudioWaveformGenerator.generate(url: decodedURL)
                try Task.checkCancellation()
                await MainActor.run { [weak self] in
                    guard let self, !self.disposed, self.generation == request else { return }
                    self.audioWaveform = waveform
                    if self.audioCover == nil { self.onAudioVisualChanged?() }
                    self.waveformTask = nil
                }
            } catch { /* Audio playback remains available if overview decoding fails. */ }
        }
    }

    private func installAudioCover(_ image: CGImage, request: UInt) {
        guard !disposed, generation == request else { return }
        audioCover = image
        // Once a cover exists there is no need to decode the remaining audio
        // samples merely for an overview that will never be shown.
        waveformTask?.cancel(); waveformTask = nil
        onAudioVisualChanged?()
    }

    private func cancelAudioVisuals() {
        waveformTask?.cancel(); waveformTask = nil
        coverTask?.cancel(); coverTask = nil
        coverJob?.cancel(); coverJob = nil
        audioVisualGeneration = nil
    }

    /// Pauses immediately and prevents any late work from resuming audio. Keep
    /// the item attached so an outgoing AVPlayerLayer can retain its paused frame.
    func dispose() {
        onMain { [weak self] in
            guard let self, !self.disposed else { return }
            self.disposed = true; self.generation &+= 1; self.seekGeneration &+= 1
            self.desiredPlayback = false; self.player.pause(); self.player.currentItem?.cancelPendingSeeks()
            self.preparationTask?.cancel(); self.preparationTask = nil
            self.preparationTimeout?.cancel(); self.preparationTimeout = nil
            self.preparationCompletion = nil
            self.compatibility?.cancel(); self.compatibility = nil
            self.cancelAudioVisuals()
            self.cancelFrameCapture()
            self.asset.cancelLoading()
            self.removeObservers()
            self.onUpdate = nil; self.onEnded = nil; self.onFailure = nil; self.onPreparationProgress = nil
            self.onAudioVisualChanged = nil
        }
    }

    private func fail(_ error: Error) {
        guard !disposed, !failureReported else { return }
        failureReported = true; prepared = false; desiredPlayback = false
        generation &+= 1; seekGeneration &+= 1; pendingSeekTarget = nil
        player.pause(); player.currentItem?.cancelPendingSeeks()
        preparationTask?.cancel(); preparationTask = nil
        preparationTimeout?.cancel(); preparationTimeout = nil
        compatibility?.cancel()
        cancelAudioVisuals()
        cancelFrameCapture()
        asset.cancelLoading(); removeObservers()
        let completion = preparationCompletion; preparationCompletion = nil
        if let completion { completion(.failure(error)) }
        else { onFailure?(error.localizedDescription) }
        onUpdate?()
    }

    private func removeObservers() {
        observations.forEach { $0.invalidate() }; observations.removeAll()
        notifications.forEach(NotificationCenter.default.removeObserver); notifications.removeAll()
        if let token = timeObserver { player.removeTimeObserver(token); timeObserver = nil }
    }

    private func onMain(_ action: @escaping () -> Void) {
        if Thread.isMainThread { action() } else { DispatchQueue.main.async(execute: action) }
    }

    deinit {
        frameCaptureTask?.cancel(); frameCaptureGenerator?.cancelAllCGImageGeneration()
        waveformTask?.cancel(); coverTask?.cancel(); coverJob?.cancel()
        preparationTask?.cancel(); preparationTimeout?.cancel(); asset.cancelLoading(); compatibility?.cancel()
        player.pause(); player.currentItem?.cancelPendingSeeks()
        removeObservers()
    }
}
