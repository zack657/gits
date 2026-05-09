import Foundation

struct SSHKeyPair: Equatable, Sendable {
    let privateKeyPath: String
    let publicKeyPath: String
}

protocol SSHKeyGenerating: Sendable {
    func generateKeyPair(accountID: UUID, keyName: String) throws -> SSHKeyPair
    func readPublicKey(at path: String) throws -> String
}

struct GitHubSSHTestResult: Equatable, Sendable {
    let authenticatedLogin: String?
    let rawOutput: String

    var isAuthenticated: Bool {
        authenticatedLogin != nil
    }
}

protocol GitHubSSHTesting: Sendable {
    func testConnection(privateKeyPath: String) throws -> GitHubSSHTestResult
}

final class SSHKeyService: SSHKeyGenerating, GitHubSSHTesting, @unchecked Sendable {
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

    func readPublicKey(at path: String) throws -> String {
        try String(contentsOfFile: path, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func testConnection(privateKeyPath: String) throws -> GitHubSSHTestResult {
        let output: String
        do {
            output = try runner.run(
                "/usr/bin/ssh",
                arguments: [
                    "-i", privateKeyPath,
                    "-o", "IdentitiesOnly=yes",
                    "-o", "BatchMode=yes",
                    "-T", "git@github.com"
                ]
            )
        } catch let error as ShellCommandError {
            output = error.output
        }

        return GitHubSSHTestResult(
            authenticatedLogin: Self.githubLogin(from: output),
            rawOutput: output.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private static func githubLogin(from output: String) -> String? {
        guard let match = output.range(
            of: #"Hi ([^!]+)!"#,
            options: .regularExpression
        ) else {
            return nil
        }

        let matchedText = String(output[match])
        return matchedText
            .replacingOccurrences(of: "Hi ", with: "")
            .replacingOccurrences(of: "!", with: "")
    }
}
