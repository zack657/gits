import Foundation
import Testing
@testable import GitAccountBinder

struct GitConfigWriterTests {
    @Test
    func previewIncludesGlobalGeneratedConfigAndRepositoryOverrides() throws {
        let preview = try ApplyPreviewService().buildPreview(
            repositoryPaths: ["/Users/ctw/work/app-api"],
            workspaceRuleRoots: ["/Users/ctw/work"],
            hasGlobalDefault: true
        )

        #expect(preview.filePaths.contains("~/.gitconfig"))
        #expect(preview.filePaths.contains("/Users/ctw/work/app-api/.git/config"))
    }

    @Test
    func applyRepositoryBindingWritesLocalIdentitySSHCommandAndSnapshot() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let repo = root.appendingPathComponent("repo")
        try FileManager.default.createDirectory(at: repo, withIntermediateDirectories: true)
        _ = try ShellCommandRunner().run("/usr/bin/git", arguments: ["-C", repo.path(), "init"])

        let snapshotRoot = root.appendingPathComponent("snapshots")
        let service = GitConfigApplyService(
            runner: ShellCommandRunner(),
            snapshotService: SnapshotService(snapshotRoot: snapshotRoot.path())
        )
        let accountID = UUID()
        let account = Account(
            id: accountID,
            displayName: "个人 GitHub",
            gitUserName: "zack657",
            gitUserEmail: "zjc348@gmail.com",
            platformType: .github,
            sshKeyID: nil,
            signingKey: nil,
            isGlobalDefault: true
        )
        let guidance = SSHKeyGuidance(
            accountID: accountID,
            privateKeyPath: "/tmp/key with space",
            publicKeyPath: "/tmp/key with space.pub",
            publicKey: "ssh-ed25519 AAAATEST",
            githubSSHKeysURL: URL(string: "https://github.com/settings/keys")!,
            statusText: "GitHub SSH key 已就绪",
            deployKeyWarning: "",
            isReady: true
        )

        let result = try service.applyRepositoryBindings(
            repositories: [
                RepositoryRecord(
                    id: UUID(),
                    repositoryPath: repo.path(),
                    repositoryName: "repo",
                    currentAccountID: accountID
                )
            ],
            accounts: [account],
            sshKeyGuidanceByAccountID: [accountID: guidance]
        )

        let name = try ShellCommandRunner().run(
            "/usr/bin/git",
            arguments: ["-C", repo.path(), "config", "--local", "user.name"]
        )
        let email = try ShellCommandRunner().run(
            "/usr/bin/git",
            arguments: ["-C", repo.path(), "config", "--local", "user.email"]
        )
        let sshCommand = try ShellCommandRunner().run(
            "/usr/bin/git",
            arguments: ["-C", repo.path(), "config", "--local", "core.sshCommand"]
        )

        #expect(result.appliedRepositoryPaths == [repo.path()])
        #expect(result.snapshot != nil)
        #expect(name.trimmingCharacters(in: .whitespacesAndNewlines) == "zack657")
        #expect(email.trimmingCharacters(in: .whitespacesAndNewlines) == "zjc348@gmail.com")
        #expect(sshCommand.trimmingCharacters(in: .whitespacesAndNewlines) == "ssh -i '/tmp/key with space' -o IdentitiesOnly=yes")
    }
}
