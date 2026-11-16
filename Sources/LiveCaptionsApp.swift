import SwiftUI
import AppKit
import Combine
import Translation

@main
struct LiveCaptionsApp: App {
    @NSApplicationDelegateAdaptor(CaptionAppDelegate.self) var delegate
    @StateObject private var model = CaptionModel.shared
    var body: some Scene {
        MenuBarExtra(model.tr("听桥 · CaptionBridge"), systemImage: "captions.bubble") {
            Text(model.status)
            Button(model.tr(model.running ? "停止字幕" : "开始字幕")) {
                if model.running { model.requestStop() }
                else { Task { await model.start() } }
            }.disabled(model.busy || model.setupBusy)
            Button(model.tr("显示控制窗口")) { model.showControls?() }
            Button(model.tr("显示悬浮字幕")) { model.showOverlay?() }
            Button(model.tr("使用指南")) { model.showGuide?() }
            Divider()
            Button(model.tr("退出")) { NSApp.terminate(nil) }.keyboardShortcut("q")
        }
    }
}

@MainActor
final class CaptionAppDelegate: NSObject, NSApplicationDelegate {
    private var controls: NSWindow?
    private var panel: NSPanel?
    private var guide: NSWindow?
    private var preparation: NSWindow?
    private var languageSubscription: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let model = CaptionModel.shared
        let controls = makeWindow(title: model.tr("听桥 · CaptionBridge"), size: NSSize(width: 600, height: 690))
        controls.contentView = NSHostingView(rootView: ControlView(model: model))
        controls.minSize = NSSize(width: 560, height: 500)
        self.controls = controls
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 850, height: 240),
            styleMask: [.borderless, .nonactivatingPanel, .resizable], backing: .buffered, defer: false)
        panel.title = "CaptionBridge — Captions"
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.minSize = NSSize(width: 480, height: 160)
        panel.contentView = NSHostingView(rootView: OverlayView(model: model, hide: { [weak panel] in panel?.orderOut(nil) }))
        if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(x: frame.midX - 425, y: frame.minY + 55))
        }
        panel.setFrameAutosaveName("BilingualCaptionOverlay")
        self.panel = panel
        model.showOverlay = { [weak self] in self?.panel?.orderFrontRegardless() }
        model.showControls = { [weak self] in
            NSApp.activate(ignoringOtherApps: true)
            self?.controls?.makeKeyAndOrderFront(nil)
        }
        model.showGuide = { [weak self] in self?.openGuide() }
        model.setupModels = { [weak self] in self?.prepareModels() }
        languageSubscription = model.$language.sink { [weak self] language in
            self?.controls?.title = Copy.text("听桥 · CaptionBridge", language)
            self?.guide?.title = Copy.text("使用指南", language) + " · CaptionBridge"
            self?.preparation?.title = Copy.text("准备语言模型", language)
        }
        model.showControls?()
        Task { await model.refreshModelStatus() }
        if CommandLine.arguments.contains("--self-test-report") {
            model.showOverlay?()
            Task { await model.start(sample: true) }
        } else if !UserDefaults.standard.bool(forKey: "didShowCaptionBridgeGuide") {
            openGuide()
            UserDefaults.standard.set(true, forKey: "didShowCaptionBridgeGuide")
        }
    }

    private func makeWindow(title: String, size: NSSize) -> NSWindow {
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = title
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }

    private func openGuide() {
        if guide == nil {
            let window = makeWindow(title: CaptionModel.shared.tr("使用指南") + " · CaptionBridge", size: NSSize(width: 660, height: 700))
            window.minSize = NSSize(width: 560, height: 450)
            window.contentView = NSHostingView(rootView: GuideView(model: .shared))
            guide = window
        }
        NSApp.activate(ignoringOtherApps: true)
        guide?.makeKeyAndOrderFront(nil)
    }

    private func prepareModels() {
        let model = CaptionModel.shared
        guard !model.running, !model.busy else { return }
        if !model.setupBusy {
            model.setupBusy = true
            model.errorMessage = nil
            let window = makeWindow(title: model.tr("准备语言模型"), size: NSSize(width: 540, height: 300))
            window.contentView = NSHostingView(rootView: ModelSetupView(model: model))
            preparation = window
        }
        NSApp.activate(ignoringOtherApps: true)
        preparation?.makeKeyAndOrderFront(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}

struct LanguagePicker: View {
    @ObservedObject var model: CaptionModel
    var body: some View {
        Picker(model.tr("界面语言"), selection: $model.language) {
            ForEach(InterfaceLanguage.allCases) { language in Text(language.label).tag(language) }
        }.frame(maxWidth: 290).disabled(model.running || model.busy || model.setupBusy)
    }
}

struct ControlView: View {
    @ObservedObject var model: CaptionModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 54, height: 54)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.tr("听桥 · CaptionBridge")).font(.title2.bold())
                        Text(model.tr("听见英语，看见中文。")).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button { model.showGuide?() } label: { Image(systemName: "questionmark.circle") }.help(model.tr("使用指南"))
                }
                LanguagePicker(model: model)
                HStack {
                    Circle().fill(model.running ? .green : .secondary).frame(width: 8, height: 8)
                    Text(model.status).font(.callout)
                    if model.busy || model.setupBusy { ProgressView().controlSize(.small) }
                }
                if let error = model.errorMessage {
                    Text(error).font(.callout).foregroundStyle(.red).textSelection(.enabled)
                }
                if !model.modelsReady {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(model.tr("首次使用")).font(.headline)
                        Text(model.tr("首次需联网下载英语识别与英中翻译模型。下载完成后，语音识别和字幕翻译可离线运行。"))
                            .font(.callout).foregroundStyle(.secondary)
                        Button(model.tr("准备语言模型")) { model.setupModels?() }
                            .disabled(model.busy || model.running || model.setupBusy)
                    }.padding(14).frame(maxWidth: .infinity, alignment: .leading).background(.blue.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                }
                HStack {
                    Button(model.tr(model.running ? "停止字幕" : "开始字幕")) {
                        if model.running { model.requestStop() }
                        else { Task { await model.start() } }
                    }.buttonStyle(.borderedProminent).disabled(model.busy || model.setupBusy)
                    Button(model.tr("运行示例")) { Task { await model.start(sample: true) } }
                        .disabled(model.busy || model.running || model.setupBusy)
                    Button(model.tr("显示悬浮窗")) { model.showOverlay?() }
                }
                Divider()
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 14) {
                    GridRow {
                        Text(model.tr("字幕字号"))
                        Slider(value: $model.fontSize, in: 18...42, step: 1)
                        Text("\(Int(model.fontSize))").monospacedDigit().frame(width: 30)
                    }
                    GridRow {
                        Text(model.tr("背景不透明度"))
                        Slider(value: $model.opacity, in: 0.35...1)
                        Text("\(Int(model.opacity * 100))%").monospacedDigit().frame(width: 38)
                    }
                }
                Toggle(model.tr("优先翻译质量（High Fidelity）"), isOn: $model.highFidelity)
                    .disabled(model.running || model.busy || model.setupBusy)
                Text(model.tr("默认优先速度。策略变更在下次启动字幕时生效。"))
                    .font(.caption).foregroundStyle(.secondary)
                Divider()
                Text(model.tr("打开英文会议或视频后，点击「开始字幕」。只处理电脑播放的声音，不采集麦克风。"))
                    .font(.callout).foregroundStyle(.secondary)
                HStack {
                    Button(model.tr("打开音频录制权限设置"), action: openRecordingSettings).font(.caption)
                    Spacer()
                    Button(model.tr("使用指南")) { model.showGuide?() }.font(.caption)
                }
                Text(model.tr("音频和翻译在本机处理")).font(.caption).foregroundStyle(.secondary)
                Text("CaptionBridge 0.2.0 · " + model.tr("测试版 · 尚未完成 Apple 公证"))
                    .font(.caption2).foregroundStyle(.tertiary)
            }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

func openRecordingSettings() {
    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
        NSWorkspace.shared.open(url)
    }
}

struct GuideView: View {
    @ObservedObject var model: CaptionModel
    func section(_ heading: String, _ body: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(model.tr(heading), systemImage: icon).font(.headline)
            Text(model.tr(body)).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                LanguagePicker(model: model)
                Text(model.tr("听桥 · CaptionBridge")).font(.largeTitle.bold())
                Text(model.tr("听见英语，看见中文。")).font(.title3).foregroundStyle(.secondary)
                Text(model.tr("轻量级 Mac 菜单栏字幕工具，为会议、课程和视频生成本地双语悬浮字幕。"))
                Text(model.tr("三语界面与指南；当前字幕方向为英语 → 简体中文。"))
                    .font(.callout).foregroundStyle(.secondary)
                section("首次使用", "首次需联网下载英语识别与英中翻译模型。下载完成后，语音识别和字幕翻译可离线运行。", icon: "1.circle")
                Button(model.tr("准备语言模型")) { model.setupModels?() }.disabled(model.running || model.busy || model.setupBusy)
                section("屏幕与系统音频录制", "打开系统设置 → 隐私与安全性 → 屏幕与系统音频录制，允许 CaptionBridge。若列表没有它，先点击「开始字幕」或用 + 添加 App。按系统提示用 Touch ID 或密码确认；需要时退出并重新打开 App。", icon: "2.circle")
                Text(model.tr("系统把这一权限归类为屏幕与音频录制；听桥仅消费音频缓冲，不保存屏幕画面。"))
                    .font(.caption).foregroundStyle(.secondary)
                Button(model.tr("打开音频录制权限设置"), action: openRecordingSettings)
                section("开始字幕", "打开英文会议或视频后，点击「开始字幕」。只处理电脑播放的声音，不采集麦克风。", icon: "3.circle")
                section("权限与隐私", "只处理电脑播放的声音，不采集麦克风。不保存会议音频或字幕，也不上传会议内容。", icon: "lock.shield")
                Text(model.tr("适用于 Apple Silicon · macOS 27 或更新版本")).font(.caption).foregroundStyle(.secondary)
                HStack {
                    Button(model.tr("显示控制窗口")) { model.showControls?() }.buttonStyle(.borderedProminent)
                    Button(model.tr("使用指南") + " · 中文 / English / 日本語") {
                        if let url = Bundle.main.url(forResource: "Guide", withExtension: "html") { NSWorkspace.shared.open(url) }
                    }
                }
            }.padding(26).frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct ModelSetupView: View {
    @ObservedObject var model: CaptionModel
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label(model.tr("准备语言模型"), systemImage: "arrow.down.circle").font(.title2.bold())
            Text(model.tr("首次需联网下载英语识别与英中翻译模型。下载完成后，语音识别和字幕翻译可离线运行。"))
            if model.setupBusy { ProgressView() }
            else { Text(model.errorMessage ?? model.tr("语言模型已就绪")).foregroundStyle(model.errorMessage == nil ? Color.secondary : Color.red) }
        }
        .padding(28).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .translationTask(source: Locale.Language(identifier: "en"), target: Locale.Language(identifier: "zh-Hans"), preferredStrategy: .lowLatency) { session in
            await model.prepareModels(using: session)
        }
        .onDisappear { model.setupBusy = false }
    }
}

struct OverlayView: View {
    @ObservedObject var model: CaptionModel
    var hide: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Circle().fill(model.running ? .green : .gray).frame(width: 7, height: 7)
                Text(model.status).font(.caption)
                if model.running && !model.sampleMode && !model.receivedAudio {
                    Text(model.tr("· 等待电脑音频")).font(.caption).foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Button { model.showControls?() } label: { Image(systemName: "slider.horizontal.3") }.help(model.tr("打开控制窗口"))
                Button(action: hide) { Image(systemName: "xmark") }.help(model.tr("隐藏字幕，菜单栏可重新显示"))
            }.foregroundStyle(.white.opacity(0.75)).buttonStyle(.plain)
            if model.visibleSegments.isEmpty {
                Spacer(minLength: 0)
                Text(model.errorMessage ?? model.tr("点击「开始字幕」，然后播放英文会议或视频。"))
                    .font(.system(size: model.fontSize)).foregroundStyle(.white)
                Text(model.tr("拖动此窗口调整位置，拖动边缘调整大小。"))
                    .font(.callout).foregroundStyle(.white.opacity(0.6))
                Spacer(minLength: 0)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(model.visibleSegments) { segment in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(segment.english).font(.system(size: model.fontSize * 0.72))
                                        .foregroundStyle(.white.opacity(segment.isFinal ? 0.8 : 0.6))
                                    Text(segment.chinese.isEmpty ? model.tr("翻译中…") : segment.chinese)
                                        .font(.system(size: model.fontSize, weight: .medium)).foregroundStyle(.white)
                                }.frame(maxWidth: .infinity, alignment: .leading).id(segment.id)
                            }
                        }
                    }.onChange(of: model.segments.last?.english) {
                        if let id = model.segments.last?.id { proxy.scrollTo(id, anchor: .bottom) }
                    }
                }
            }
        }
        .padding(18).frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(model.opacity), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.15)))
        .preferredColorScheme(.dark)
    }
}
