import Foundation
import Testing
@testable import GitAccountBinder

private struct FakeShellCommandRunner: ShellCommandRunning {
    @discardableResult
    func run(_ launchPath: String, arguments: [String]) throws -> String {
        guard let privateKeyPath = arguments.dropFirst(3).first else {
            return ""
        }

        let privateKeyURL = URL(fileURLWithPath: privateKeyPath)
        let publicKeyURL = URL(fileURLWithPath: "\(privateKeyPath).pub")
        try FileManager.default.createDirectory(
            at: privateKeyURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("private".utf8).write(to: privateKeyURL)
        try Data("public".utf8).write(to: publicKeyURL)
        return ""
    }
}

struct SSHKeyServiceTests {
    @Test
    func generatedKeyPairCreatesPrivateAndPublicKeyFiles() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let paths = AppPathService(root: root.path())
        let runner = FakeShellCommandRunner()
        let service = SSHKeyService(paths: paths, runner: runner)

        let result = try service.generateKeyPair(
            accountID: UUID(),
            keyName: "work"
        )

        #expect(result.privateKeyPath.hasSuffix("work"))
        #expect(result.publicKeyPath.hasSuffix("work.pub"))
    }
}
