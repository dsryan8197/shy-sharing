import AppKit

/// A click-through red frame drawn around a window, with its name in a tag.
final class OutlineOverlay {
    private let window: NSWindow
    private let outlineView = OutlineView()

    init() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: .borderless,
            backing: .buffered,
            defer: true
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        // Keep the outline itself out of screen shares and recordings.
        window.sharingType = .none
        window.isReleasedWhenClosed = false
        window.contentView = outlineView
    }

    func show(around target: ShareableWindow) {
        let padding: CGFloat = 6
        let frame = Self.cocoaFrame(for: target.bounds).insetBy(dx: -padding, dy: -padding)
        outlineView.label = target.displayName
        window.setFrame(frame, display: true)
        outlineView.needsDisplay = true
        window.orderFrontRegardless()
    }

    func hide() {
        window.orderOut(nil)
    }

    /// Converts a top-left-origin global rect to AppKit's bottom-left-origin coordinates.
    static func cocoaFrame(for rect: CGRect) -> NSRect {
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 0
        return NSRect(x: rect.minX, y: primaryHeight - rect.maxY, width: rect.width, height: rect.height)
    }
}

private final class OutlineView: NSView {
    var label = ""

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        let lineWidth: CGFloat = 5
        let frame = bounds.insetBy(dx: lineWidth / 2 + 1, dy: lineWidth / 2 + 1)
        let border = NSBezierPath(roundedRect: frame, xRadius: 12, yRadius: 12)
        border.lineWidth = lineWidth
        NSColor.systemRed.setStroke()
        border.stroke()

        guard !label.isEmpty else { return }
        let text = NSAttributedString(string: label, attributes: [
            .font: NSFont.systemFont(ofSize: 15, weight: .semibold),
            .foregroundColor: NSColor.white,
        ])
        let textSize = text.size()
        let tag = NSRect(
            x: 14,
            y: 14,
            width: min(textSize.width + 24, max(bounds.width - 40, 60)),
            height: textSize.height + 10
        )
        NSColor.systemRed.setFill()
        NSBezierPath(roundedRect: tag, xRadius: 7, yRadius: 7).fill()
        text.draw(with: tag.insetBy(dx: 12, dy: 5), options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], context: nil)
    }
}
