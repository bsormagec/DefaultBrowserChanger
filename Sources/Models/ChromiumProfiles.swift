import Foundation

/// Reads profiles of Chromium-based browsers from their `Local State` file.
public enum ChromiumProfiles {
    public struct Profile: Equatable {
        public let directory: String   // e.g. "Default", "Profile 1" — passed as --profile-directory
        public let name: String        // name shown in the browser's profile picker
    }

    /// Folder under ~/Library/Application Support that holds each browser's `Local State`.
    static let dataFolders: [String: String] = [
        "com.google.Chrome": "Google/Chrome",
        "com.google.Chrome.beta": "Google/Chrome Beta",
        "com.google.Chrome.dev": "Google/Chrome Dev",
        "com.google.Chrome.canary": "Google/Chrome Canary",
        "com.brave.Browser": "BraveSoftware/Brave-Browser",
        "com.microsoft.edgemac": "Microsoft Edge",
        "com.vivaldi.Vivaldi": "Vivaldi",
        "org.chromium.Chromium": "Chromium",
        "ai.perplexity.comet": "Comet",
    ]

    /// Profiles for a browser, or empty when it isn't a known Chromium browser or has only one profile.
    public static func profiles(forBundleId bundleId: String) -> [Profile] {
        guard let folder = dataFolders[bundleId] else { return [] }
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/\(folder)/Local State")
        guard let data = try? Data(contentsOf: url) else { return [] }
        let profiles = parse(localState: data)
        return profiles.count > 1 ? profiles : []
    }

    /// Parses `profile.info_cache` from a Local State JSON blob. "Default" first, then "Profile 1", "Profile 2", …
    public static func parse(localState data: Data) -> [Profile] {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let cache = (root["profile"] as? [String: Any])?["info_cache"] as? [String: Any] else { return [] }
        return cache.map { dir, info in
            let name = (info as? [String: Any])?["name"] as? String
            return Profile(directory: dir, name: (name?.isEmpty == false) ? name! : dir)
        }
        .sorted {
            if ($0.directory == "Default") != ($1.directory == "Default") { return $0.directory == "Default" }
            return $0.directory.localizedStandardCompare($1.directory) == .orderedAscending
        }
    }
}
