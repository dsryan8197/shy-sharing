import AppKit
import ApplicationServices

/// While Teams is the front app, watches what the pointer is over. When it's an entry in
/// Teams' "share a window" list, reports the real window that entry stands for.
final class TeamsPickerWatcher {
    static let teamsBundleIDs: Set<String> = ["com.microsoft.teams2", "com.microsoft.teams"]

    /// Called on the main thread with the hovered window, or nil when nothing is hovered.
    var onHover: ((ShareableWindow?) -> Void)?

    private var timer: Timer?
    private var teamsApp: (pid: pid_t, element: AXUIElement)?
    private var lastHit: AXUIElement?
    private var current: ShareableWindow?

    func start() {
        guard timer == nil else { return }
        let timer = Timer(timeInterval: 1.0 / 15.0, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        clear()
    }

    private func tick() {
        guard let front = NSWorkspace.shared.frontmostApplication,
              let bundleID = front.bundleIdentifier,
              Self.teamsBundleIDs.contains(bundleID)
        else { return clear() }

        let app = appElement(for: front.processIdentifier)
        guard let hit = AX.element(at: Self.pointerLocation(), in: app) else { return clear() }

        // Still over the same element: keep whatever is showing.
        if let lastHit, CFEqual(lastHit, hit) { return }
        lastHit = hit

        if debugEnabled { logAncestry(of: hit) }
        let matcher = WindowMatcher(windows: WindowCatalog.onScreenWindows())
        let window = resolve(hit, matcher: matcher)
        debugLog(window.map { "→ outlining \"\($0.displayName)\" (\($0.ownerName))" } ?? "→ not a share-list entry")
        publish(window)
    }

    /// Walks up from the hovered element. The first level whose text names exactly one
    /// window is the hovered entry; it counts only once a higher level names two or more
    /// windows, which shows we're inside a list of windows rather than, say, a chat message.
    private func resolve(_ hit: AXUIElement, matcher: WindowMatcher) -> ShareableWindow? {
        var element: AXUIElement? = hit
        var candidate: ShareableWindow?
        for _ in 0..<12 {
            guard let level = element else { break }
            let found = windowsNamed(under: level, matcher: matcher, limit: 2)
            if found.count >= 2 { return candidate }
            if candidate == nil { candidate = found.first }
            element = AX.parent(level)
        }
        return nil
    }

    /// Distinct windows named by text in a small subtree, stopping early at `limit`.
    private func windowsNamed(under root: AXUIElement, matcher: WindowMatcher, limit: Int) -> [ShareableWindow] {
        var found: [ShareableWindow] = []
        var queue: [(AXUIElement, Int)] = [(root, 0)]
        var visited = 0
        while !queue.isEmpty, visited < 150 {
            let (element, depth) = queue.removeFirst()
            visited += 1
            for label in AX.labels(element) {
                guard let window = matcher.match(label), !found.contains(where: { $0.id == window.id }) else { continue }
                found.append(window)
                if found.count >= limit { return found }
            }
            if depth < 4 {
                queue += AX.children(element).map { ($0, depth + 1) }
            }
        }
        return found
    }

    private func appElement(for pid: pid_t) -> AXUIElement {
        if let teamsApp, teamsApp.pid == pid { return teamsApp.element }
        let element = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(element, 0.2)
        // Asks Chromium/Electron-based apps to expose their full accessibility tree.
        AXUIElementSetAttributeValue(element, "AXManualAccessibility" as CFString, kCFBooleanTrue)
        teamsApp = (pid, element)
        return element
    }

    private func clear() {
        lastHit = nil
        publish(nil)
    }

    private func publish(_ window: ShareableWindow?) {
        guard window != current else { return }
        current = window
        onHover?(window)
    }

    private func logAncestry(of hit: AXUIElement) {
        var element: AXUIElement? = hit
        var level = 0
        debugLog("pointer over:")
        while let ancestor = element, level < 6 {
            debugLog("  \(level) \(AX.role(ancestor)) \(AX.labels(ancestor))")
            element = AX.parent(ancestor)
            level += 1
        }
    }

    /// Pointer position in global coordinates with the origin at the top-left of the
    /// primary display, as the Accessibility and window-list APIs expect.
    static func pointerLocation() -> CGPoint {
        let location = NSEvent.mouseLocation
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 0
        return CGPoint(x: location.x, y: primaryHeight - location.y)
    }
}
