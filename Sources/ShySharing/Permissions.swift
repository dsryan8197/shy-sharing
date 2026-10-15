import AppKit
import ApplicationServices
import CoreGraphics

/// The two macOS permissions the app needs:
/// - Accessibility, to read which entry the pointer is over in Teams' share list.
/// - Screen Recording, so the window list includes other apps' window titles.
enum Permissions {
    static var hasAccessibility: Bool { AXIsProcessTrusted() }

    static func requestAccessibility() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    static var hasScreenRecording: Bool { CGPreflightScreenCaptureAccess() }

    static func requestScreenRecording() {
        _ = CGRequestScreenCaptureAccess()
    }

    static func openAccessibilitySettings() {
        open("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    static func openScreenRecordingSettings() {
        open("x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")
    }

    private static func open(_ address: String) {
        if let url = URL(string: address) {
            NSWorkspace.shared.open(url)
        }
    }
}
