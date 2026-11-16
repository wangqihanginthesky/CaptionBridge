import Foundation
import Speech
import Translation

// Does not request permissions, download assets, or process user audio.
@main
struct ModernCapabilities {
    static func main() async {
        var report: [String: Any] = [:]
        report["osVersion"] = ProcessInfo.processInfo.operatingSystemVersionString
        report["speechTranscriberAvailable"] = SpeechTranscriber.isAvailable
        let supported = await SpeechTranscriber.supportedLocales
        let installed = await SpeechTranscriber.installedLocales
        report["englishSupportedLocales"] = supported.map(\.identifier).filter { $0.hasPrefix("en") }.sorted()
        report["englishInstalledLocales"] = installed.map(\.identifier).filter { $0.hasPrefix("en") }.sorted()
        let availability = LanguageAvailability(preferredStrategy: .lowLatency)
        let status = await availability.status(from: Locale.Language(identifier: "en"), to: Locale.Language(identifier: "zh-Hans"))
        report["englishToChineseTranslationStatus"] = String(describing: status)
        do {
            let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
            print(String(decoding: data, as: UTF8.self))
        } catch {
            fputs("Failed to encode probe output: \(error)\n", stderr)
            exit(1)
        }
    }
}
