import Foundation

enum PersistencePathNormalizer {
    static func normalizedStoredPath(_ path: String) -> String {
        var normalized = URL(fileURLWithPath: path)
            .standardizedFileURL
            .resolvingSymlinksInPath()
            .path

        if normalized.count > 1 {
            normalized = normalized.replacingOccurrences(of: "/+$", with: "", options: .regularExpression)
        }

        return normalized
    }

    static func logicalLookupKey(for path: String) -> String {
        normalizedStoredPath(path).folding(options: [.caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }
}
