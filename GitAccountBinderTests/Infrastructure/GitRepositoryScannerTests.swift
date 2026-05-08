import Foundation
import Testing
@testable import GitAccountBinder

struct GitRepositoryScannerTests {
    @Test
    func scannerReturnsFoldersContainingDotGitDirectory() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(
            at: root.appendingPathComponent("demo/.git"),
            withIntermediateDirectories: true
        )

        let scanner = GitRepositoryScanner()
        let results = try scanner.scan(rootPaths: [root.path()])

        #expect(results.map(\.path).contains(root.appendingPathComponent("demo").path()))
    }
}
