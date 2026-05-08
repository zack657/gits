import Foundation
import Testing
@testable import GitAccountBinder

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
