import AppKit

public struct BrowserApp: Identifiable, Equatable {
    /// Bundle id, or "bundleId#profileDirectory" for a Chromium profile entry.
    public let id: String
    public let name: String
    public let bundleURL: URL
    public let icon: NSImage
    public var isDefault: Bool
    /// Chromium profile folder (e.g. "Profile 1"); nil opens the browser's last-used profile.
    public let profileDirectory: String?

    public init(id: String, name: String, bundleURL: URL, icon: NSImage, isDefault: Bool = false, profileDirectory: String? = nil) {
        self.id = id
        self.name = name
        self.bundleURL = bundleURL
        self.icon = icon
        self.isDefault = isDefault
        self.profileDirectory = profileDirectory
    }

    public static func == (lhs: BrowserApp, rhs: BrowserApp) -> Bool {
        return lhs.id == rhs.id && lhs.isDefault == rhs.isDefault
    }
}
