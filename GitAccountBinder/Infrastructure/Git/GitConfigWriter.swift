import Foundation

struct GitConfigApplyResult: Equatable, Sendable {
    let appliedRepositoryPaths: [String]
    let snapshot: ConfigSnapshot?
}

struct GitConfigWriter {
    func generatedIncludeBlock(configPath: String) -> String {
        """
        [include]
            path = \(configPath)
        """
    }

    func repositoryOverrideBlock(account: Account) -> String {
        """
        [user]
            name = \(account.gitUserName)
            email = \(account.gitUserEmail)
        """
    }
}

struct GitConfigApplyService {
    private let runner: any ShellCommandRunning
    private let snapshotService: SnapshotService?

    init(
        runner: any ShellCommandRunning = ShellCommandRunner(),
        snapshotService: SnapshotService? = nil
    ) {
        self.runner = runner
        self.snapshotService = snapshotService
    }

    func applyRepositoryBindings(
        repositories: [RepositoryRecord],
        accounts: [Account],
        sshKeyGuidanceByAccountID: [UUID: SSHKeyGuidance]
    ) throws -> GitConfigApplyResult {
        let bindings = repositories.compactMap { repository -> (RepositoryRecord, Account)? in
            guard let accountID = repository.currentAccountID,
                  let account = accounts.first(where: { $0.id == accountID }) else {
                return nil
            }
            return (repository, account)
        }

        let configPaths = bindings.map { "\($0.0.repositoryPath)/.git/config" }
        let snapshot = try snapshotService?.createSnapshot(
            files: Array(Set(configPaths)).sorted(),
            summary: "应用 Git 账号绑定前自动备份"
        )

        var appliedPaths: [String] = []
        for (repository, account) in bindings {
            try apply(account: account, toRepositoryAt: repository.repositoryPath)

            if let guidance = sshKeyGuidanceByAccountID[account.id] {
                try setSSHCommand(
                    privateKeyPath: guidance.privateKeyPath,
                    repositoryPath: repository.repositoryPath
                )
            }

            appliedPaths.append(repository.repositoryPath)
        }

        return GitConfigApplyResult(
            appliedRepositoryPaths: appliedPaths.sorted(),
            snapshot: snapshot
        )
    }

    private func apply(account: Account, toRepositoryAt repositoryPath: String) throws {
        try runGitConfig(repositoryPath: repositoryPath, key: "user.name", value: account.gitUserName)
        try runGitConfig(repositoryPath: repositoryPath, key: "user.email", value: account.gitUserEmail)
    }

    private func setSSHCommand(privateKeyPath: String, repositoryPath: String) throws {
        let sshCommand = "ssh -i \(Self.shellQuoted(privateKeyPath)) -o IdentitiesOnly=yes"
        try runGitConfig(repositoryPath: repositoryPath, key: "core.sshCommand", value: sshCommand)
    }

    private func runGitConfig(repositoryPath: String, key: String, value: String) throws {
        _ = try runner.run(
            "/usr/bin/git",
            arguments: ["-C", repositoryPath, "config", "--local", key, value]
        )
    }

    private static func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}
