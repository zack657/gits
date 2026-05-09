import Foundation
import Testing
@testable import GitAccountBinder

struct AppPathServiceTests {
    @Test
    func applicationSupportPathDoesNotPercentEncodeSpaces() {
        let paths = AppPathService.applicationSupportDefault

        #expect(paths.root.contains("Application Support"))
        #expect(!paths.root.contains("Application%20Support"))
    }

    @Test
    func legacyEncodedDirectoryIsCopiedIntoCanonicalDirectory() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let legacy = AppPathService(root: root.appendingPathComponent("Application%20Support/GitAccountBinder").path())
        let canonical = AppPathService(root: root.appendingPathComponent("Application Support/GitAccountBinder").path())
        let legacyKey = URL(fileURLWithPath: legacy.root)
            .appendingPathComponent("Keys/github_test.pub")
        try FileManager.default.createDirectory(
            at: legacyKey.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try "ssh-ed25519 AAAATEST".write(to: legacyKey, atomically: true, encoding: .utf8)

        try canonical.migrateLegacyDirectoryIfNeeded(from: legacy)

        let copiedKey = URL(fileURLWithPath: canonical.root)
            .appendingPathComponent("Keys/github_test.pub")
        #expect(FileManager.default.fileExists(atPath: copiedKey.path()))
    }
}
