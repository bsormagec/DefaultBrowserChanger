import Foundation

/// Commands sent to the app by URL, for Shortcuts, Raycast, Alfred, Focus filters or a terminal:
///   dbc://select?browser=com.google.Chrome      (bundle id, profile id like com.google.Chrome#Profile 1, or name)
///   dbc://cycle
///   dbc://open?url=https%3A%2F%2Fexample.com[&browser=…][&private=1]
/// `defaultbrowserchanger://` works the same as `dbc://`.
public enum AutomationCommand: Equatable {
    case select(browser: String)
    case cycle
    case open(url: URL, browser: String?, privateWindow: Bool)

    public static let schemes: Set<String> = ["dbc", "defaultbrowserchanger"]

    /// nil when the URL isn't one of ours or is malformed.
    public static func parse(_ url: URL) -> AutomationCommand? {
        guard let scheme = url.scheme?.lowercased(), schemes.contains(scheme) else { return nil }
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func value(_ name: String) -> String? {
            items.first { $0.name == name }?.value.flatMap { $0.isEmpty ? nil : $0 }
        }

        switch url.host?.lowercased() {
        case "select":
            return value("browser").map { .select(browser: $0) }
        case "cycle":
            return .cycle
        case "open":
            // Only web links: this scheme can be triggered by any app or web page.
            guard let target = value("url").flatMap(URL.init(string:)),
                  let targetScheme = target.scheme?.lowercased(), targetScheme == "http" || targetScheme == "https" else { return nil }
            let isPrivate = ["1", "true", "yes"].contains(value("private")?.lowercased() ?? "")
            return .open(url: target, browser: value("browser"), privateWindow: isPrivate)
        default:
            return nil
        }
    }
}
