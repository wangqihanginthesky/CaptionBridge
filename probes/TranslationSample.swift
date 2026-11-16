import SwiftUI
import Translation

@main
struct TranslationSample: App {
    var body: some Scene {
        WindowGroup("本地翻译验证") { TranslationSampleView() }
    }
}

struct TranslationSampleView: View {
    @State private var output = "正在准备英中翻译模型…"
    let sample = "We have seen significant improvements in our ranking model."

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Apple 本地英译中验证").font(.title2)
            Text(sample).textSelection(.enabled)
            Text(output).textSelection(.enabled)
        }
        .padding(28)
        .frame(width: 600, height: 220)
        .translationTask(source: Locale.Language(identifier: "en"), target: Locale.Language(identifier: "zh-Hans"), preferredStrategy: .lowLatency) { session in
            do {
                try await session.prepareTranslation()
                let start = ContinuousClock.now
                let response = try await session.translate(sample)
                output = response.targetText + "\n耗时：\(start.duration(to: .now))"
                print("TRANSLATION: \(output)")
                let log = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("caption-translation-result.txt")
                try output.write(to: log, atomically: true, encoding: .utf8)
            } catch {
                output = "翻译失败：\(error)"
                print(output)
            }
        }
    }
}
