import Foundation

/// Run with `--debug` (or SHY_DEBUG=1) to print what the app sees in Teams' share list.
let debugEnabled = CommandLine.arguments.contains("--debug")
    || ProcessInfo.processInfo.environment["SHY_DEBUG"] == "1"

func debugLog(_ message: @autoclosure () -> String) {
    guard debugEnabled else { return }
    print("[shy] \(message())")
    fflush(stdout)
}
