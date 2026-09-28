import AppKit

public struct BrowserApp: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let bundleURL: URL
    public let icon: NSImage
    public var isDefault: Bool

    public init(id: String, name: String, bundleURL: URL, icon: NSImage, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.bundleURL = bundleURL
        self.icon = icon
        self.isDefault = isDefault
    }

    public static func == (lhs: BrowserApp, rhs: BrowserApp) -> Bool {
        return lhs.id == rhs.id && lhs.isDefault == rhs.isDefault
    }
}
