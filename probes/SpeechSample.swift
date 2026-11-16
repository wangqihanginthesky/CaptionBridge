import Foundation
import Speech
import AVFAudio

@main
struct SpeechSample {
    static func main() async {
        do {
            let transcriber = SpeechTranscriber(locale: Locale(identifier: "en-US"), preset: .transcription)
            if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
                print("Downloading English speech model…")
                try await request.downloadAndInstall()
            }
            print("English model ready")
            guard CommandLine.arguments.count == 2 else { return }
            let file = try AVAudioFile(forReading: URL(fileURLWithPath: CommandLine.arguments[1]))
            let analyzer = SpeechAnalyzer(modules: [transcriber])
            let results = Task {
                for try await result in transcriber.results {
                    print("TRANSCRIPT: \(String(result.text.characters)) | final=\(result.isFinal)")
                }
            }
            if let last = try await analyzer.analyzeSequence(from: file) {
                try await analyzer.finalizeAndFinish(through: last)
            } else {
                await analyzer.cancelAndFinishNow()
            }
            try await results.value
        } catch {
            print("ERROR: \(error)")
            exit(1)
        }
    }
}
