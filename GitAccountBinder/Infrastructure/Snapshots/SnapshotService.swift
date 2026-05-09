import Foundation

final class SnapshotService {
    private let snapshotRoot: String

    init(snapshotRoot: String) {
        self.snapshotRoot = snapshotRoot
    }

    func createSnapshot(files: [String], summary: String) throws -> ConfigSnapshot {
        let snapshotID = UUID()
        let storagePath = "\(snapshotRoot)/\(snapshotID.uuidString)"
        try FileManager.default.createDirectory(
            atPath: storagePath,
            withIntermediateDirectories: true
        )

        for file in files where FileManager.default.fileExists(atPath: file) {
            let backupURL = URL(fileURLWithPath: storagePath)
                .appendingPathComponent(file.replacingOccurrences(of: "/", with: "__"))
            try FileManager.default.copyItem(
                at: URL(fileURLWithPath: file),
                to: backupURL
            )
        }

        return ConfigSnapshot(
            id: snapshotID,
            scope: .global,
            targetPath: summary,
            gitConfigContent: "",
            sshConfigContent: "",
            note: summary,
            createdAt: .now
        )
    }

    func restore(snapshot: ConfigSnapshot) throws {
        let storagePath = "\(snapshotRoot)/\(snapshot.id.uuidString)"
        let fileManager = FileManager.default

        guard let enumerator = fileManager.enumerator(atPath: storagePath) else {
            return
        }

        while let entry = enumerator.nextObject() as? String {
            let backupURL = URL(fileURLWithPath: storagePath).appendingPathComponent(entry)
            let originalPath = entry.replacingOccurrences(of: "__", with: "/")
            let originalURL = URL(fileURLWithPath: originalPath)

            if fileManager.fileExists(atPath: originalURL.path()) {
                try fileManager.removeItem(at: originalURL)
            }

            try fileManager.createDirectory(
                at: originalURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try fileManager.copyItem(at: backupURL, to: originalURL)
        }
    }

    func verifyRestore(snapshot: ConfigSnapshot, files: [String]) -> Bool {
        let storagePath = "\(snapshotRoot)/\(snapshot.id.uuidString)"

        return files.allSatisfy { file in
            let backupURL = URL(fileURLWithPath: storagePath)
                .appendingPathComponent(file.replacingOccurrences(of: "/", with: "__"))
            return FileManager.default.fileExists(atPath: backupURL.path())
        }
    }
}
