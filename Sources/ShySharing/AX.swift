import ApplicationServices

/// Small wrappers around the macOS Accessibility API.
enum AX {
    static func attribute(_ element: AXUIElement, _ name: String) -> AnyObject? {
        var value: AnyObject?
        let error = AXUIElementCopyAttributeValue(element, name as CFString, &value)
        return error == .success ? value : nil
    }

    static func string(_ element: AXUIElement, _ name: String) -> String? {
        attribute(element, name) as? String
    }

    static func parent(_ element: AXUIElement) -> AXUIElement? {
        guard let value = attribute(element, kAXParentAttribute),
              CFGetTypeID(value) == AXUIElementGetTypeID()
        else { return nil }
        return (value as! AXUIElement)
    }

    static func children(_ element: AXUIElement) -> [AXUIElement] {
        guard let values = attribute(element, kAXChildrenAttribute) as? [AnyObject] else { return [] }
        return values.compactMap { value in
            CFGetTypeID(value) == AXUIElementGetTypeID() ? (value as! AXUIElement) : nil
        }
    }

    /// The visible or spoken text of an element.
    static func labels(_ element: AXUIElement) -> [String] {
        [kAXTitleAttribute, kAXDescriptionAttribute, kAXValueAttribute]
            .compactMap { string(element, $0) }
            .filter { !$0.isEmpty }
    }

    static func role(_ element: AXUIElement) -> String {
        string(element, kAXRoleAttribute) ?? "?"
    }

    /// The deepest element of `app` at a point in global top-left-origin coordinates.
    static func element(at point: CGPoint, in app: AXUIElement) -> AXUIElement? {
        var element: AXUIElement?
        let error = AXUIElementCopyElementAtPosition(app, Float(point.x), Float(point.y), &element)
        return error == .success ? element : nil
    }
}
