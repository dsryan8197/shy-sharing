import AppKit
import CoreGraphics

/// A normal app window currently on screen.
struct ShareableWindow: Equatable {
    let id: CGWindowID
    let ownerPID: pid_t
    let ownerName: String
    let title: String
    /// Global display coordinates, origin at the top-left of the primary display.
    let bounds: CGRect

    var displayName: String { title.isEmpty ? ownerName : title }
}

enum WindowCatalog {
    /// On-screen app windows, front-most first. Titles of other apps' windows are only
    /// filled in when the app has Screen Recording permission.
    static func onScreenWindows() -> [ShareableWindow] {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let info = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }
        let ownPID = ProcessInfo.processInfo.processIdentifier
        var windows: [ShareableWindow] = []
        for entry in info {
            guard let layer = entry[kCGWindowLayer as String] as? Int, layer == 0,
                  let id = entry[kCGWindowNumber as String] as? CGWindowID,
                  let pid = entry[kCGWindowOwnerPID as String] as? pid_t, pid != ownPID,
                  let boundsInfo = entry[kCGWindowBounds as String] as? NSDictionary,
                  let bounds = CGRect(dictionaryRepresentation: boundsInfo as CFDictionary),
                  bounds.width >= 40, bounds.height >= 40
            else { continue }
            windows.append(ShareableWindow(
                id: id,
                ownerPID: pid,
                ownerName: entry[kCGWindowOwnerName as String] as? String ?? "",
                title: entry[kCGWindowName as String] as? String ?? "",
                bounds: bounds
            ))
        }
        return windows
    }
}

/// Maps a label shown in Teams' share list (e.g. "danielryan — -zsh — 136×49" or "Claude")
/// to the real window it stands for.
struct WindowMatcher {
    let windows: [ShareableWindow]

    func match(_ rawLabel: String) -> ShareableWindow? {
        let label = Self.normalize(rawLabel)
        guard label.count >= 2 else { return nil }

        // 1. Exact window title. Windows are listed front to back, so the first hit is the
        //    front-most of any windows sharing a title.
        if let window = windows.first(where: { !$0.title.isEmpty && Self.normalize($0.title) == label }) {
            return window
        }

        // 2. A title Teams cut short with an ellipsis.
        for ellipsis in ["…", "..."] where label.hasSuffix(ellipsis) {
            let prefix = String(label.dropLast(ellipsis.count)).trimmingCharacters(in: .whitespaces)
            if prefix.count >= 4,
               let window = windows.first(where: { Self.normalize($0.title).hasPrefix(prefix) }) {
                return window
            }
        }

        // 3. The app name, which Teams shows for windows without a useful title.
        if let window = windows.first(where: { Self.normalize($0.ownerName) == label }) {
            return window
        }

        // 4. A longer label containing a window's title, e.g. an accessibility label like
        //    "Share window Claude Code".
        let containing = windows.filter { $0.title.count >= 6 && label.contains(Self.normalize($0.title)) }
        return containing.max(by: { $0.title.count < $1.title.count })
    }

    static func normalize(_ text: String) -> String {
        text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
