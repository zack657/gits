import Foundation

struct SSHKeyPair: Equatable, Sendable {
    let privateKeyPath: String
    let publicKeyPath: String
}

final class SSHKeyService {
    private let paths: AppPathService
    private let runner: ShellCommandRunning

    init(paths: AppPathService, runner: ShellCommandRunning) {
        self.paths = paths
        self.runner = runner
    }

    func generateKeyPair(accountID: UUID, keyName: String) throws -> SSHKeyPair {
        try FileManager.default.createDirectory(
            atPath: paths.sshDirectory,
            withIntermediateDirectories: true
        )

        let privateKeyPath = "\(paths.sshDirectory)/\(keyName)"
        _ = try runner.run(
            "/usr/bin/ssh-keygen",
            arguments: [
                "-t", "ed25519",
                "-f", privateKeyPath,
                "-N", "",
                "-C", accountID.uuidString
            ]
        )

        return SSHKeyPair(
            privateKeyPath: privateKeyPath,
            publicKeyPath: "\(privateKeyPath).pub"
        )
    }
}
