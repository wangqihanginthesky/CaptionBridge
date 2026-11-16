import AppKit
import SwiftUI
import Speech
import Translation
import ScreenCaptureKit

struct CaptionSegment: Identifiable {
    let id: String
    var english: String
    var chinese = ""
    var isFinal: Bool
    var translatedSource = ""
}

@MainActor
final class CaptionModel: ObservableObject {
    static let shared = CaptionModel()
    @Published var segments: [CaptionSegment] = []
    @Published private var statusSource = "准备就绪"
    var status: String {
        get { tr(statusSource) }
        set { statusSource = newValue }
    }
    @Published var errorMessage: String?
    @Published var running = false
    @Published var busy = false
    @Published var sampleMode = false
    @Published var receivedAudio = false
    @Published var translationSeconds: Double?
    @Published var fontSize = UserDefaults.standard.object(forKey: "captionFontSize") as? Double ?? 26.0 {
        didSet { UserDefaults.standard.set(fontSize, forKey: "captionFontSize") }
    }
    @Published var opacity = UserDefaults.standard.object(forKey: "captionOpacity") as? Double ?? 0.88 {
        didSet { UserDefaults.standard.set(opacity, forKey: "captionOpacity") }
    }
    @Published var highFidelity = UserDefaults.standard.bool(forKey: "captionHighFidelity") {
        didSet { UserDefaults.standard.set(highFidelity, forKey: "captionHighFidelity") }
    }
    @Published var language = InterfaceLanguage(rawValue: UserDefaults.standard.string(forKey: "interfaceLanguage") ?? "") ?? .systemDefault {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "interfaceLanguage"); errorMessage = nil }
    }
    @Published var modelsReady = false
    @Published var setupBusy = false
    var showGuide: (() -> Void)?
    var setupModels: (() -> Void)?
    func tr(_ source: String) -> String { Copy.text(source, language) }

    func refreshModelStatus() async {
        let status = await LanguageAvailability(preferredStrategy: .lowLatency).status(from: Locale.Language(identifier: "en"), to: Locale.Language(identifier: "zh-Hans"))
        let installed = await SpeechTranscriber.installedLocales
        modelsReady = status == .installed && installed.contains(where: { $0.identifier == "en_US" || $0.identifier == "en-US" })
    }

    func prepareModels(using session: TranslationSession) async {
        guard setupBusy else { return }
        do {
            try await session.prepareTranslation()
            let transcriber = SpeechTranscriber(locale: Locale(identifier: "en-US"), preset: .transcription)
            if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
                try await request.downloadAndInstall()
            }
            await refreshModelStatus()
            status = "语言模型已就绪"
        } catch {
            errorMessage = tr("语言模型准备失败：") + error.localizedDescription
        }
        setupBusy = false
    }
    var showOverlay: (() -> Void)?
    var showControls: (() -> Void)?
    private var pipeline: AudioPipeline?
    private var session: TranslationSession?
    private var worker: Task<Void, Never>?
    private var draftTimer: Task<Void, Never>?
    private var pending: [String] = []
    private var generation = UUID()
    private var sampleTask: Task<Void, Never>?
    private var failureInProgress = false

    var visibleSegments: [CaptionSegment] { Array(segments.suffix(2)) }

    func start(sample: Bool = false) async {
        guard !running, !busy, !setupBusy else { return }
        busy = true
        generation = UUID()
        let run = generation
        segments = []
        pending = []
        receivedAudio = false
        translationSeconds = nil
        errorMessage = nil
        sampleMode = sample
        showOverlay?()
        status = "正在准备本地模型…"
        do {
            let strategy: TranslationSession.Strategy = highFidelity ? .highFidelity : .lowLatency
            let availability = LanguageAvailability(preferredStrategy: strategy)
            let languageStatus = await availability.status(from: Locale.Language(identifier: "en"), to: Locale.Language(identifier: "zh-Hans"))
            guard languageStatus == .installed else {
                throw CaptionError(message: "请先点击「准备语言模型」，完成英中翻译模型下载。")
            }
            session = TranslationSession(installedSource: Locale.Language(identifier: "en"), target: Locale.Language(identifier: "zh-Hans"), preferredStrategy: strategy)
            let pipeline = AudioPipeline(language: language)
            self.pipeline = pipeline
            try await pipeline.prepare(onResult: { [weak self] result in
                guard let self, self.generation == run else { return }
                self.accept(result)
            }, onAudio: { [weak self] in
                guard let self, self.generation == run else { return }
                self.receivedAudio = true
            }, onFailure: { [weak self] message in
                guard let self, self.generation == run, !self.failureInProgress else { return }
                self.failureInProgress = true
                Task {
                    await self.stop()
                    self.errorMessage = message
                    self.status = "已停止"
                    self.failureInProgress = false
                }
            })
            if !sample {
                status = "正在请求系统音频访问…"
                try await pipeline.startSystemAudio()
            }
            running = true
            busy = false
            status = sample ? "示例验证中 · 固定语音" : "正在监听电脑音频 · 英语 → 中文"
            draftTimer = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(900))
                    guard !Task.isCancelled else { break }
                    if let last = segments.last, !last.isFinal { enqueue(last.id) }
                }
            }
            if sample {
                guard let url = Bundle.main.url(forResource: "english-sample", withExtension: "aiff") else {
                    throw CaptionError(message: "找不到示例音频，请重新安装 App。")
                }
                sampleTask = Task {
                    do {
                        try await pipeline.playSample(url)
                        await stop()
                        if errorMessage == nil {
                            status = "示例完成 · 可点击开始字幕监听电脑音频"
                        }
                        writeSelfTestResult()
                    } catch is CancellationError { }
                    catch {
                        await stop()
                        errorMessage = tr(error.localizedDescription)
                        writeSelfTestResult()
                    }
                }
            }
        } catch {
            await pipeline?.stop(finalize: false)
            self.pipeline = nil
            session = nil
            busy = false
            running = false
            status = "启动失败"
            let nsError = error as NSError
            if nsError.domain == SCStreamErrorDomain && nsError.code == -3801 {
                errorMessage = tr("尚未允许录制电脑音频。请打开权限设置，添加并允许 CaptionBridge，然后退出并重新打开 App。")
            } else {
                errorMessage = tr(error.localizedDescription)
            }
        }
    }

    func stop() async {
        guard !busy else { return }
        busy = true
        draftTimer?.cancel()
        draftTimer = nil
        // Cancel sample input only when this is an external stop, rather than
        // cancelling the task that is about to drain final translations.
        await pipeline?.stop(finalize: true)
        pipeline = nil
        // Final results can arrive during finalize; drain their translations.
        await worker?.value
        session = nil
        running = false
        busy = false
        status = "已停止"
    }

    func requestStop() {
        sampleTask?.cancel()
        sampleTask = nil
        Task { await stop() }
    }

    private func accept(_ result: SpeechTranscriber.Result) {
        let text = String(result.text.characters).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let id = "\(result.range.start.value)/\(result.range.start.timescale)"
        if let index = segments.firstIndex(where: { $0.id == id }) {
            if segments[index].isFinal && !result.isFinal { return }
            segments[index].english = text
            segments[index].isFinal = result.isFinal
        } else {
            segments.append(CaptionSegment(id: id, english: text, isFinal: result.isFinal))
        }
        if segments.count > 24 { segments.removeFirst(segments.count - 24) }
        if result.isFinal { enqueue(id) }
    }

    private func enqueue(_ id: String) {
        guard let segment = segments.first(where: { $0.id == id }),
              segment.translatedSource != segment.english else { return }
        if !pending.contains(id) { pending.append(id) }
        guard worker == nil else { return }
        let run = generation
        worker = Task {
            while !pending.isEmpty, generation == run, !Task.isCancelled {
                let id = pending.removeFirst()
                guard let snapshot = segments.first(where: { $0.id == id }), let session,
                      snapshot.english != snapshot.translatedSource else { continue }
                do {
                    let start = ContinuousClock.now
                    let response = try await session.translate(snapshot.english)
                    guard generation == run else { break }
                    if let index = segments.firstIndex(where: { $0.id == id }) {
                        // Never publish a translation for text that has since been revised.
                        if segments[index].english == snapshot.english {
                            segments[index].chinese = response.targetText
                            segments[index].translatedSource = snapshot.english
                            let elapsed = start.duration(to: .now).components
                            translationSeconds = Double(elapsed.seconds) + Double(elapsed.attoseconds) / 1e18
                        } else if !pending.contains(id) { pending.append(id) }
                    }
                } catch {
                    errorMessage = tr("翻译失败：") + error.localizedDescription
                }
            }
            worker = nil
        }
    }

    private func writeSelfTestResult() {
        guard let index = CommandLine.arguments.firstIndex(of: "--self-test-report"),
              CommandLine.arguments.indices.contains(index + 1) else { return }
        let result: [String: Any] = [
            "english": segments.map(\.english).joined(separator: " "),
            "chinese": segments.map(\.chinese).joined(separator: " "),
            "final": segments.allSatisfy(\.isFinal),
            "segmentCount": segments.count,
            "error": errorMessage ?? "",
            "running": running,
            "translationSeconds": translationSeconds ?? -1
        ]
        if let data = try? JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: URL(fileURLWithPath: CommandLine.arguments[index + 1]), options: .atomic)
        }
    }
}
