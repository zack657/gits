import Foundation
import Testing
@testable import GitAccountBinder

struct SnapshotServiceTests {
    @Test
    func snapshotRoundTripRestoresOriginalFileContents() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let file = root.appendingPathComponent("gitconfig")
        try "before".write(to: file, atomically: true, encoding: .utf8)

        let service = SnapshotService(snapshotRoot: root.path())
        let snapshot = try service.createSnapshot(
            files: [file.path()],
            summary: "test"
        )

        try "after".write(to: file, atomically: true, encoding: .utf8)
        try service.restore(snapshot: snapshot)

        let restored = try String(contentsOf: file, encoding: .utf8)
        #expect(restored == "before")
    }
}
