import Foundation
import AVFoundation
import Speech
import ScreenCaptureKit

struct CaptionError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

// The converter and continuation are only used on this serial queue.
final class AudioInput: NSObject, SCStreamOutput, SCStreamDelegate, @unchecked Sendable {
    let queue = DispatchQueue(label: "local.livecaptions.audio")
    private let language: InterfaceLanguage
    private func tr(_ source: String) -> String { Copy.text(source, language) }
    private let converter: AnalyzerInputConverter
    private let continuation: AsyncStream<AnalyzerInput>.Continuation
    private let onFailure: @Sendable (String) -> Void
    private let onAudio: @Sendable () -> Void
    private var closed = false
    private var lastReport = Date.distantPast

    init(format: AVAudioFormat, language: InterfaceLanguage, continuation: AsyncStream<AnalyzerInput>.Continuation,
         onAudio: @escaping @Sendable () -> Void, onFailure: @escaping @Sendable (String) -> Void) {
        self.language = language
        converter = AnalyzerInputConverter(analyzerFormat: format)
        self.continuation = continuation
        self.onAudio = onAudio
        self.onFailure = onFailure
    }

    private func push(_ buffer: AVAudioPCMBuffer) throws {
        guard !closed else { return }
        for input in try converter.convert(buffer, at: nil) {
            if case .dropped = continuation.yield(input) {
                throw CaptionError(message: tr("音频处理跟不上播放速度，请停止后重试。"))
            }
        }
        if Date().timeIntervalSince(lastReport) > 1 {
            lastReport = Date()
            onAudio()
        }
    }

    func feedFileBuffer(_ buffer: AVAudioPCMBuffer) throws {
        try queue.sync { try push(buffer) }
    }

    func finish() {
        queue.sync {
            guard !closed else { return }
            do {
                for input in try converter.flush() { continuation.yield(input) }
            } catch { onFailure(error.localizedDescription) }
            closed = true
            continuation.finish()
        }
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio, !closed, sampleBuffer.isValid,
              let description = sampleBuffer.formatDescription,
              let streamDescription = CMAudioFormatDescriptionGetStreamBasicDescription(description),
              let format = AVAudioFormat(streamDescription: streamDescription) else { return }
        let count = sampleBuffer.numSamples
        guard count > 0, let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(count)) else { return }
        buffer.frameLength = AVAudioFrameCount(count)
        let status = CMSampleBufferCopyPCMDataIntoAudioBufferList(sampleBuffer, at: 0, frameCount: Int32(count), into: buffer.mutableAudioBufferList)
        guard status == noErr else {
            onFailure(tr("音频缓冲转换失败") + " (\(status))")
            return
        }
        do { try push(buffer) }
        catch {
            closed = true
            continuation.finish()
            onFailure(error.localizedDescription)
        }
    }

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        onFailure(tr("系统音频已中断") + ": " + error.localizedDescription)
    }
}

@MainActor
final class AudioPipeline {
    private let language: InterfaceLanguage
    init(language: InterfaceLanguage) { self.language = language }
    private func tr(_ source: String) -> String { Copy.text(source, language) }
    let transcriber = SpeechTranscriber(locale: Locale(identifier: "en-US"), preset: .timeIndexedProgressiveTranscription)
    private var analyzer: SpeechAnalyzer?
    private var input: AudioInput?
    private var stream: SCStream?
    private var resultsTask: Task<Void, Never>?
    private var intentionalStop = false
    private var stopped = false

    func prepare(onResult: @escaping @MainActor (SpeechTranscriber.Result) -> Void,
                 onAudio: @escaping @MainActor () -> Void,
                 onFailure: @escaping @MainActor (String) -> Void) async throws {
        guard SpeechTranscriber.isAvailable else { throw CaptionError(message: tr("本机不支持 Apple 本地语音识别。")) }
        if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            try await request.downloadAndInstall()
        }
        guard let format = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber]) else {
            throw CaptionError(message: tr("英语识别模型未就绪。"))
        }
        let sequence = AsyncStream<AnalyzerInput>.makeStream(bufferingPolicy: .bufferingOldest(256))
        let input = AudioInput(format: format, language: language, continuation: sequence.continuation,
            onAudio: { Task { @MainActor in onAudio() } },
            onFailure: { [weak self] message in Task { @MainActor in
                guard let self, !self.intentionalStop else { return }
                onFailure(message)
            } })
        self.input = input
        let analyzer = SpeechAnalyzer(modules: [transcriber])
        self.analyzer = analyzer
        resultsTask = Task {
            do {
                for try await result in transcriber.results { onResult(result) }
            } catch {
                if !intentionalStop { onFailure(tr("识别失败") + ": " + error.localizedDescription) }
            }
        }
        try await analyzer.prepareToAnalyze(in: format)
        try await analyzer.start(inputSequence: sequence.stream)
    }

    func startSystemAudio() async throws {
        guard let input else { throw CaptionError(message: tr("音频处理尚未准备完成。")) }
        let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: false)
        guard let display = content.displays.first else { throw CaptionError(message: tr("没有可采集的显示器。")) }
        let filter = SCContentFilter(display: display, excludingApplications: content.applications.filter {
            $0.processID == ProcessInfo.processInfo.processIdentifier
        }, exceptingWindows: [])
        let configuration = SCStreamConfiguration()
        configuration.capturesAudio = true
        configuration.excludesCurrentProcessAudio = true
        configuration.sampleRate = 48000
        configuration.channelCount = 2
        // No video output is registered; only audio buffers are consumed.
        configuration.width = 2
        configuration.height = 2
        configuration.minimumFrameInterval = CMTime(seconds: 1, preferredTimescale: 1)
        let stream = SCStream(filter: filter, configuration: configuration, delegate: input)
        self.stream = stream
        try stream.addStreamOutput(input, type: .audio, sampleHandlerQueue: input.queue)
        try await stream.startCapture()
    }

    func playSample(_ url: URL) async throws {
        guard let input else { throw CaptionError(message: tr("音频处理尚未准备完成。")) }
        let file = try AVAudioFile(forReading: url)
        while file.framePosition < file.length {
            try Task.checkCancellation()
            guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: 4096) else {
                throw CaptionError(message: tr("无法分配音频缓冲。"))
            }
            try file.read(into: buffer)
            try input.feedFileBuffer(buffer)
            // Match the real-time input cadence and avoid filling the bounded queue.
            try await Task.sleep(for: .seconds(Double(buffer.frameLength) / file.processingFormat.sampleRate))
        }
    }

    func stop(finalize: Bool) async {
        guard !stopped else { return }
        stopped = true
        intentionalStop = true
        if let stream { try? await stream.stopCapture() }
        stream = nil
        input?.finish()
        if let analyzer {
            if finalize { try? await analyzer.finalizeAndFinishThroughEndOfInput() }
            else { await analyzer.cancelAndFinishNow() }
        }
        await resultsTask?.value
        resultsTask = nil
        input = nil
        analyzer = nil
    }
}
