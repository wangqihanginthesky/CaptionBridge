import Foundation
import AppKit
import ApplicationServices
import Speech
import CoreGraphics

// Read-only capability probe. Does not request permission or record audio.
var report: [String: Any] = [:]
report["osVersion"] = ProcessInfo.processInfo.operatingSystemVersionString
report["accessibilityTrusted"] = AXIsProcessTrusted()
report["screenCaptureAuthorized"] = CGPreflightScreenCaptureAccess()
report["speechAuthorizationStatus"] = SFSpeechRecognizer.authorizationStatus().rawValue
if let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) {
    report["legacyEnglishRecognizerAvailable"] = recognizer.isAvailable
    report["legacyEnglishSupportsOnDeviceRecognition"] = recognizer.supportsOnDeviceRecognition
}
let apps = NSWorkspace.shared.runningApplications.filter {
    let identifier = ($0.bundleIdentifier ?? "").lowercased()
    let name = ($0.localizedName ?? "").lowercased()
    return identifier.contains("caption") || name.contains("caption")
}
report["captionApplications"] = apps.map { app -> [String: Any] in
    let element = AXUIElementCreateApplication(app.processIdentifier)
    var windows: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(element, kAXWindowsAttribute as CFString, &windows)
    return ["bundleIdentifier": app.bundleIdentifier ?? "", "pid": app.processIdentifier,
            "axWindowQueryError": result.rawValue, "windowCount": (windows as? [AXUIElement])?.count ?? 0]
}
let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
print(String(decoding: data, as: UTF8.self))
