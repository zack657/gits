import Foundation

struct AppPathService {
    let root: String

    static var applicationSupportDefault: AppPathService {
        let rootURL = FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/GitAccountBinder")
        return AppPathService(root: rootURL.path(percentEncoded: false))
    }

    static var legacyPercentEncodedApplicationSupportDefault: AppPathService {
        let root = FileManager.default
            .homeDirectoryForCurrentUser
            .path(percentEncoded: false)
            + "/Library/Application%20Support/GitAccountBinder"
        return AppPathService(root: root)
    }

    func migrateLegacyDirectoryIfNeeded(from legacyPaths: AppPathService) throws {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: legacyPaths.root) else {
            return
        }

        try fileManager.createDirectory(
            atPath: root,
            withIntermediateDirectories: true
        )

        guard let children = fileManager.enumerator(atPath: legacyPaths.root) else {
            return
        }

        while let child = children.nextObject() as? String {
            let legacyURL = URL(fileURLWithPath: legacyPaths.root).appendingPathComponent(child)
            let canonicalURL = URL(fileURLWithPath: root).appendingPathComponent(child)

            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: legacyURL.path(percentEncoded: false), isDirectory: &isDirectory) else {
                continue
            }

            if isDirectory.boolValue {
                try fileManager.createDirectory(
                    at: canonicalURL,
                    withIntermediateDirectories: true
                )
                continue
            }

            if !fileManager.fileExists(atPath: canonicalURL.path(percentEncoded: false)) {
                try fileManager.createDirectory(
                    at: canonicalURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try fileManager.copyItem(at: legacyURL, to: canonicalURL)
            }
        }
    }

    var sshDirectory: String {
        "\(root)/Keys"
    }

    var generatedConfigDirectory: String {
        "\(root)/Generated"
    }

    var snapshotsDirectory: String {
        "\(root)/Snapshots"
    }
}
