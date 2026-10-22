import AVFoundation
import Foundation

/// A fixed-size overview of actual decoded sample amplitudes. Silence is zero;
/// each bin is the largest absolute sample across every channel in that interval.
struct AudioWaveform {
    let peaks: [Float]
    let duration: Double
}

enum AudioWaveformError: Error {
    case noAudio, invalidDuration, unsupportedSamples, readerFailed
}

enum AudioWaveformGenerator {
    private final class ReaderCancellation: @unchecked Sendable {
        private let lock = NSLock()
        private var reader: AVAssetReader?
        private var cancelled = false
        func install(_ value: AVAssetReader) throws {
            lock.lock(); defer { lock.unlock() }
            if cancelled { value.cancelReading(); throw CancellationError() }
            reader = value
        }
        func cancel() {
            lock.lock(); defer { lock.unlock() }
            cancelled = true
            reader?.cancelReading()
        }
        func perform<Value>(_ operation: () -> Value) throws -> Value {
            // Core Media can crash if cancellation races startReading while
            // constructing its extraction graph. Serialize each reader call.
            lock.lock(); defer { lock.unlock() }
            guard !cancelled else { throw CancellationError() }
            return operation()
        }
    }

    /// Decode in bounded sample buffers on a background task. Neither the file's
    /// duration nor its channel count grows the retained overview beyond 4096 bins.
    static func generate(url: URL, binCount: Int = 1200) async throws -> AudioWaveform {
        let cancellation = ReaderCancellation()
        return try await withTaskCancellationHandler(operation: {
            let asset = AVURLAsset(url: url)
            defer { asset.cancelLoading() }
            try Task.checkCancellation()
            guard let track = try await asset.loadTracks(withMediaType: .audio).first else { throw AudioWaveformError.noAudio }
            let duration = try await asset.load(.duration).seconds
            guard duration.isFinite, duration > 0 else { throw AudioWaveformError.invalidDuration }
            let reader = try AVAssetReader(asset: asset)
            try cancellation.install(reader)
            defer { cancellation.cancel() }
            let output = AVAssetReaderTrackOutput(track: track, outputSettings: [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVLinearPCMBitDepthKey: 32,
                AVLinearPCMIsFloatKey: true,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsNonInterleaved: false
            ])
            output.alwaysCopiesSampleData = false
            guard reader.canAdd(output) else { throw AudioWaveformError.unsupportedSamples }
            reader.add(output)
            guard try cancellation.perform({ reader.startReading() }) else { throw reader.error ?? AudioWaveformError.readerFailed }
            var accumulator = Accumulator(binCount: binCount, duration: duration)
            // Copy no more than 256 KiB even if a decoder emits an unusually
            // large sample buffer. No full PCM asset is ever held in memory.
            var chunk = [Float](repeating: 0, count: 65_536)
            while let buffer = try cancellation.perform({ output.copyNextSampleBuffer() }) {
                try Task.checkCancellation()
                guard let description = CMSampleBufferGetFormatDescription(buffer),
                      let format = CMAudioFormatDescriptionGetStreamBasicDescription(description)?.pointee,
                      format.mFormatID == kAudioFormatLinearPCM,
                      format.mBitsPerChannel == 32,
                      format.mFormatFlags & kAudioFormatFlagIsFloat != 0,
                      format.mFormatFlags & kAudioFormatFlagIsNonInterleaved == 0,
                      format.mSampleRate.isFinite, format.mSampleRate > 0,
                      format.mChannelsPerFrame > 0,
                      let block = CMSampleBufferGetDataBuffer(buffer) else { throw AudioWaveformError.unsupportedSamples }
                let channels = Int(format.mChannelsPerFrame)
                let bytes = CMBlockBufferGetDataLength(block)
                let sampleCount = bytes / MemoryLayout<Float>.stride
                let timestamp = CMSampleBufferGetPresentationTimeStamp(buffer).seconds
                guard timestamp.isFinite else { throw AudioWaveformError.unsupportedSamples }
                var offset = 0
                while offset < sampleCount {
                    try Task.checkCancellation()
                    let count = min(chunk.count, sampleCount - offset)
                    let status = chunk.withUnsafeMutableBytes { memory in
                        CMBlockBufferCopyDataBytes(block, atOffset: offset * 4, dataLength: count * 4, destination: memory.baseAddress!)
                    }
                    guard status == kCMBlockBufferNoErr else { throw AudioWaveformError.unsupportedSamples }
                    chunk.withUnsafeBufferPointer { samples in
                        accumulator.consume(samples: UnsafeBufferPointer(start: samples.baseAddress, count: count),
                                            interleavedOffset: offset, channels: channels,
                                            sampleRate: format.mSampleRate, startTime: timestamp)
                    }
                    offset += count
                }
            }
            try Task.checkCancellation()
            guard reader.status == .completed else { throw reader.error ?? AudioWaveformError.readerFailed }
            return accumulator.waveform
        }, onCancel: { cancellation.cancel() })
    }

    /// Shared by the streaming decoder and deterministic envelope tests.
    struct Accumulator {
        private(set) var peaks: [Float]
        let duration: Double
        init(binCount: Int, duration: Double) {
            peaks = [Float](repeating: 0, count: max(1, min(4096, binCount)))
            self.duration = duration
        }
        mutating func consume(samples: UnsafeBufferPointer<Float>, interleavedOffset: Int = 0,
                              channels: Int, sampleRate: Double, startTime: Double) {
            guard channels > 0, sampleRate.isFinite, sampleRate > 0,
                  duration.isFinite, duration > 0, startTime.isFinite else { return }
            let binsPerSecond = Double(peaks.count) / duration
            for (index, sample) in samples.enumerated() where sample.isFinite {
                let frame = (index + interleavedOffset) / channels
                let time = startTime + Double(frame) / sampleRate
                guard time >= 0, time <= duration else { continue }
                let bin = min(peaks.count - 1, Int(time * binsPerSecond))
                peaks[bin] = max(peaks[bin], min(1, abs(sample)))
            }
        }
        var waveform: AudioWaveform { AudioWaveform(peaks: peaks, duration: duration) }
    }
}
