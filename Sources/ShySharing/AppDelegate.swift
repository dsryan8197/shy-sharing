import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private let watcher = TeamsPickerWatcher()
    private let overlay = OutlineOverlay()
    private var enabled = true

    private var toggleItem: NSMenuItem!
    private var accessibilityItem: NSMenuItem!
    private var screenRecordingItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setUpStatusItem()

        watcher.onHover = { [weak self] window in
            guard let self else { return }
            if let window {
                self.overlay.show(around: window)
            } else {
                self.overlay.hide()
            }
        }

        if !Permissions.hasAccessibility { Permissions.requestAccessibility() }
        if !Permissions.hasScreenRecording { Permissions.requestScreenRecording() }

        if debugEnabled {
            debugLog("accessibility allowed: \(Permissions.hasAccessibility), screen recording allowed: \(Permissions.hasScreenRecording)")
            for window in WindowCatalog.onScreenWindows() {
                debugLog("window: \(window.ownerName) — \"\(window.title)\"")
            }
        }

        watcher.start()
    }

    private func setUpStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let image = NSImage(systemSymbolName: "rectangle.dashed", accessibilityDescription: "Shy Sharing")
        image?.isTemplate = true
        item.button?.image = image

        let menu = NSMenu()
        menu.delegate = self

        toggleItem = NSMenuItem(title: "Outline windows in Teams' share list", action: #selector(toggleEnabled), keyEquivalent: "")
        toggleItem.target = self
        toggleItem.state = .on
        menu.addItem(toggleItem)
        menu.addItem(.separator())

        accessibilityItem = NSMenuItem(title: "", action: #selector(openAccessibility), keyEquivalent: "")
        accessibilityItem.target = self
        menu.addItem(accessibilityItem)

        screenRecordingItem = NSMenuItem(title: "", action: #selector(openScreenRecording), keyEquivalent: "")
        screenRecordingItem.target = self
        menu.addItem(screenRecordingItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Shy Sharing", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        item.menu = menu
        statusItem = item
        refreshPermissionItems()
    }

    func menuWillOpen(_ menu: NSMenu) {
        refreshPermissionItems()
    }

    private func refreshPermissionItems() {
        accessibilityItem.title = Permissions.hasAccessibility
            ? "Accessibility: allowed"
            : "Accessibility: not allowed (click to fix)"
        screenRecordingItem.title = Permissions.hasScreenRecording
            ? "Screen Recording: allowed"
            : "Screen Recording: not allowed (click to fix)"
    }

    @objc private func toggleEnabled() {
        enabled.toggle()
        toggleItem.state = enabled ? .on : .off
        if enabled {
            watcher.start()
        } else {
            watcher.stop()
        }
    }

    @objc private func openAccessibility() {
        Permissions.openAccessibilitySettings()
    }

    @objc private func openScreenRecording() {
        Permissions.openScreenRecordingSettings()
    }
}
