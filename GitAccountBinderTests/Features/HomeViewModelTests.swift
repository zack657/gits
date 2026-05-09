import Foundation
import Testing
@testable import GitAccountBinder

private struct FakeSSHKeyGenerator: SSHKeyGenerating {
    func generateKeyPair(accountID: UUID, keyName: String) throws -> SSHKeyPair {
        SSHKeyPair(
            privateKeyPath: "/tmp/\(keyName)",
            publicKeyPath: "/tmp/\(keyName).pub"
        )
    }

    func readPublicKey(at path: String) throws -> String {
        "ssh-ed25519 AAAATEST test@example.com"
    }
}

private struct FakeGitHubSSHTester: GitHubSSHTesting {
    let result: GitHubSSHTestResult

    func testConnection(privateKeyPath: String) throws -> GitHubSSHTestResult {
        result
    }
}

struct HomeViewModelTests {
    @Test
    func bindStoresSelectedAccountForRepositoryPath() {
        let viewModel = HomeViewModel()
        let accountID = UUID()

        viewModel.bind(repositoryPath: "/tmp/repo-a", accountID: accountID)

        #expect(viewModel.selectedAccountIDByRepositoryPath["/tmp/repo-a"] == accountID)
    }

    @Test
    func bindingDisplayNameReflectsRepositoryAndManualSelection() {
        let viewModel = HomeViewModel()
        let personalID = UUID()
        let workID = UUID()
        viewModel.setAccounts([
            Account(
                id: personalID,
                displayName: "个人 GitHub",
                gitUserName: "Chen TW",
                gitUserEmail: "chen.tw@example.com",
                platformType: .github,
                sshKeyID: nil,
                signingKey: nil,
                isGlobalDefault: true
            ),
            Account(
                id: workID,
                displayName: "公司 GitHub",
                gitUserName: "Chen Team",
                gitUserEmail: "chen.team@company.com",
                platformType: .github,
                sshKeyID: nil,
                signingKey: nil,
                isGlobalDefault: false
            )
        ])
        viewModel.setRepositories([
            RepositoryRecord(
                id: UUID(),
                repositoryPath: "/tmp/repo-a",
                repositoryName: "repo-a",
                currentAccountID: personalID
            )
        ])

        #expect(viewModel.bindingAccountDisplayName(forRepositoryPath: "/tmp/repo-a") == "个人 GitHub")

        viewModel.bind(repositoryPath: "/tmp/repo-a", accountID: workID)

        #expect(viewModel.bindingAccountDisplayName(forRepositoryPath: "/tmp/repo-a") == "公司 GitHub")
    }

    @Test
    func addAccountCreatesGitHubAccountAndUsesFirstAccountAsGlobalDefault() {
        let viewModel = HomeViewModel(sshKeyGenerator: FakeSSHKeyGenerator())

        let accountID = try! viewModel.addAccount(
            displayName: "新账号",
            gitUserName: "New User",
            gitUserEmail: "new@example.com"
        )

        #expect(viewModel.accounts.count == 1)
        #expect(viewModel.accounts.first?.id == accountID)
        #expect(viewModel.accounts.first?.displayName == "新账号")
        #expect(viewModel.accounts.first?.platformType == .github)
        #expect(viewModel.accounts.first?.isGlobalDefault == true)
    }

    @Test
    func deleteAccountRemovesManualBindingsForThatAccount() {
        let viewModel = HomeViewModel(sshKeyGenerator: FakeSSHKeyGenerator())
        let personalID = try! viewModel.addAccount(
            displayName: "个人 GitHub",
            gitUserName: "Chen TW",
            gitUserEmail: "chen.tw@example.com"
        )
        let workID = try! viewModel.addAccount(
            displayName: "公司 GitHub",
            gitUserName: "Chen Team",
            gitUserEmail: "chen.team@company.com"
        )

        viewModel.bind(repositoryPath: "/tmp/repo-a", accountID: workID)

        viewModel.deleteAccount(id: workID)

        #expect(viewModel.accounts.map(\.id) == [personalID])
        #expect(viewModel.selectedAccountIDByRepositoryPath["/tmp/repo-a"] == nil)
    }

    @Test
    func addAccountGeneratesSSHKeyGuidanceForGitHubAccountKeys() throws {
        let viewModel = HomeViewModel(sshKeyGenerator: FakeSSHKeyGenerator())

        let accountID = try viewModel.addAccount(
            displayName: "公司 GitHub",
            gitUserName: "Chen Team",
            gitUserEmail: "chen.team@company.com"
        )

        let guidance = try #require(viewModel.sshKeyGuidanceByAccountID[accountID])
        #expect(guidance.publicKey == "ssh-ed25519 AAAATEST test@example.com")
        #expect(guidance.statusText == "待添加到 GitHub")
        #expect(guidance.githubSSHKeysURL == URL(string: "https://github.com/settings/keys")!)
        #expect(guidance.deployKeyWarning.contains("不要添加到仓库的 Deploy keys"))
    }

    @Test
    func testGitHubSSHConnectionMarksMatchingAccountReady() throws {
        let viewModel = HomeViewModel(
            sshKeyGenerator: FakeSSHKeyGenerator(),
            githubSSHTester: FakeGitHubSSHTester(
                result: GitHubSSHTestResult(
                    authenticatedLogin: "Chen Team",
                    rawOutput: "Hi Chen Team! You've successfully authenticated."
                )
            )
        )
        let accountID = try viewModel.addAccount(
            displayName: "公司 GitHub",
            gitUserName: "Chen Team",
            gitUserEmail: "chen.team@company.com"
        )

        viewModel.testGitHubSSHConnection(accountID: accountID)

        let guidance = try #require(viewModel.sshKeyGuidanceByAccountID[accountID])
        #expect(guidance.statusText == "GitHub SSH 连接成功：Chen Team")
        #expect(guidance.isReady == true)
    }

    @Test
    func testGitHubSSHConnectionKeepsMismatchedAccountNotReady() throws {
        let viewModel = HomeViewModel(
            sshKeyGenerator: FakeSSHKeyGenerator(),
            githubSSHTester: FakeGitHubSSHTester(
                result: GitHubSSHTestResult(
                    authenticatedLogin: "zack-commits",
                    rawOutput: "Hi zack-commits! You've successfully authenticated."
                )
            )
        )
        let accountID = try viewModel.addAccount(
            displayName: "zack657",
            gitUserName: "zack657",
            gitUserEmail: "zjc348@gmail.com"
        )

        viewModel.testGitHubSSHConnection(accountID: accountID)

        let guidance = try #require(viewModel.sshKeyGuidanceByAccountID[accountID])
        #expect(guidance.statusText == "SSH key 属于 zack-commits，不匹配当前账号 zack657")
        #expect(guidance.isReady == false)
    }

    @Test
    func addRepositoryRequiresGitFolderAndBindsSelectedAccount() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let repo = root.appendingPathComponent("client-app")
        try FileManager.default.createDirectory(
            at: repo.appendingPathComponent(".git"),
            withIntermediateDirectories: true
        )
        let viewModel = HomeViewModel(sshKeyGenerator: FakeSSHKeyGenerator())
        let accountID = try viewModel.addAccount(
            displayName: "公司 GitHub",
            gitUserName: "Chen Team",
            gitUserEmail: "chen.team@company.com"
        )

        try viewModel.addRepository(path: repo.path(), accountID: accountID)

        #expect(viewModel.repositories.map(\.repositoryName) == ["client-app"])
        #expect(viewModel.bindingAccountID(forRepositoryPath: repo.path()) == accountID)
    }

    @Test
    func deleteRepositoryOnlyRemovesManagedRecordAndBinding() throws {
        let viewModel = HomeViewModel(sshKeyGenerator: FakeSSHKeyGenerator())
        let accountID = try viewModel.addAccount(
            displayName: "公司 GitHub",
            gitUserName: "Chen Team",
            gitUserEmail: "chen.team@company.com"
        )
        viewModel.setRepositories([
            RepositoryRecord(
                id: UUID(),
                repositoryPath: "/tmp/repo-a",
                repositoryName: "repo-a",
                currentAccountID: accountID
            )
        ])
        viewModel.bind(repositoryPath: "/tmp/repo-a", accountID: accountID)

        viewModel.deleteRepository(path: "/tmp/repo-a")

        #expect(viewModel.repositories.isEmpty)
        #expect(viewModel.selectedAccountIDByRepositoryPath["/tmp/repo-a"] == nil)
    }

    @Test
    func loadPersistedStateRestoresAccountsRepositoriesBindingsAndSSHStatus() throws {
        let databaseManager = try DatabaseManager.inMemory()
        let accountStore = AccountStore(databaseWriter: databaseManager.writer)
        let bindingStore = RepositoryBindingStore(databaseWriter: databaseManager.writer)
        let guidanceStore = SSHKeyGuidanceStore(databaseWriter: databaseManager.writer)
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let repo = root.appendingPathComponent("persisted-app")
        try FileManager.default.createDirectory(
            at: repo.appendingPathComponent(".git"),
            withIntermediateDirectories: true
        )

        let firstViewModel = HomeViewModel(
            sshKeyGenerator: FakeSSHKeyGenerator(),
            githubSSHTester: FakeGitHubSSHTester(
                result: GitHubSSHTestResult(
                    authenticatedLogin: "Persisted User",
                    rawOutput: "Hi Persisted User!"
                )
            ),
            accountStore: accountStore,
            repositoryBindingStore: bindingStore,
            sshKeyGuidanceStore: guidanceStore
        )
        let accountID = try firstViewModel.addAccount(
            displayName: "持久化账号",
            gitUserName: "Persisted User",
            gitUserEmail: "persisted@example.com"
        )
        firstViewModel.testGitHubSSHConnection(accountID: accountID)
        try firstViewModel.addRepository(path: repo.path(), accountID: accountID)

        let reloadedViewModel = HomeViewModel(
            sshKeyGenerator: FakeSSHKeyGenerator(),
            accountStore: accountStore,
            repositoryBindingStore: bindingStore,
            sshKeyGuidanceStore: guidanceStore
        )
        try reloadedViewModel.loadPersistedState()

        #expect(reloadedViewModel.accounts.map(\.displayName) == ["持久化账号"])
        #expect(reloadedViewModel.repositories.map(\.repositoryName) == ["persisted-app"])
        #expect(reloadedViewModel.bindingAccountID(forRepositoryPath: repo.path()) == accountID)
        #expect(reloadedViewModel.sshKeyGuidanceByAccountID[accountID]?.isReady == true)
        #expect(reloadedViewModel.sshKeyGuidanceByAccountID[accountID]?.statusText == "GitHub SSH 连接成功：Persisted User")
    }
}
