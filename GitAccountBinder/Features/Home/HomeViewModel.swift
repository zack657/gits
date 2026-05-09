import Foundation
import Observation

struct SSHKeyGuidance: Equatable, Sendable {
    let accountID: UUID
    let privateKeyPath: String
    let publicKeyPath: String
    let publicKey: String
    let githubSSHKeysURL: URL
    let statusText: String
    let deployKeyWarning: String
    let isReady: Bool
}

@Observable
final class HomeViewModel {
    private(set) var accounts: [Account] = []
    private(set) var repositories: [RepositoryRecord] = []
    private(set) var selectedAccountIDByRepositoryPath: [String: UUID] = [:]
    private(set) var sshKeyGuidanceByAccountID: [UUID: SSHKeyGuidance] = [:]
    private(set) var applyPreview: ApplyPreview?
    private(set) var lastApplyResultText: String?
    var errorMessage: String?

    private let sshKeyGenerator: any SSHKeyGenerating
    private let gitConfigApplyService: GitConfigApplyService
    private let accountStore: AccountStore?
    private let repositoryBindingStore: RepositoryBindingStore?
    private let sshKeyGuidanceStore: SSHKeyGuidanceStore?
    private let snapshotStore: SnapshotStore?

    init(
        sshKeyGenerator: any SSHKeyGenerating = SSHKeyService(
            paths: .applicationSupportDefault,
            runner: ShellCommandRunner()
        ),
        gitConfigApplyService: GitConfigApplyService = GitConfigApplyService(),
        accountStore: AccountStore? = nil,
        repositoryBindingStore: RepositoryBindingStore? = nil,
        sshKeyGuidanceStore: SSHKeyGuidanceStore? = nil,
        snapshotStore: SnapshotStore? = nil
    ) {
        self.sshKeyGenerator = sshKeyGenerator
        self.gitConfigApplyService = gitConfigApplyService
        self.accountStore = accountStore
        self.repositoryBindingStore = repositoryBindingStore
        self.sshKeyGuidanceStore = sshKeyGuidanceStore
        self.snapshotStore = snapshotStore
    }

    func loadPersistedState() throws {
        if let accountStore {
            accounts = try accountStore.fetchAll()
        }

        if let repositoryBindingStore {
            let bindings = try repositoryBindingStore.fetchAll()
            repositories = bindings.map { binding in
                RepositoryRecord(
                    id: binding.id,
                    repositoryPath: binding.repositoryPath,
                    repositoryName: URL(fileURLWithPath: binding.repositoryPath).lastPathComponent,
                    originURL: binding.remoteURL,
                    currentAccountID: binding.accountID,
                    lastScannedAt: binding.updatedAt
                )
            }
            selectedAccountIDByRepositoryPath = Dictionary(
                uniqueKeysWithValues: bindings.map {
                    (normalizedRepositoryPath($0.repositoryPath), $0.accountID)
                }
            )
        }

        if let sshKeyGuidanceStore {
            sshKeyGuidanceByAccountID = try sshKeyGuidanceStore.fetchAll()
        }
    }

    func setAccounts(_ accounts: [Account]) {
        self.accounts = accounts
    }

    func setRepositories(_ repositories: [RepositoryRecord]) {
        self.repositories = repositories
    }

    @discardableResult
    func addAccount(
        displayName: String,
        gitUserName: String,
        gitUserEmail: String
    ) throws -> UUID {
        let accountID = UUID()
        let sshKeyID = UUID()
        let now = Date()
        let keyName = "github_\(accountID.uuidString.lowercased())"
        let keyPair = try sshKeyGenerator.generateKeyPair(
            accountID: accountID,
            keyName: keyName
        )
        let publicKey = try sshKeyGenerator.readPublicKey(at: keyPair.publicKeyPath)
        let account = Account(
            id: accountID,
            displayName: displayName,
            gitUserName: gitUserName,
            gitUserEmail: gitUserEmail,
            platformType: .github,
            sshKeyID: sshKeyID,
            signingKey: nil,
            isGlobalDefault: accounts.isEmpty,
            createdAt: now,
            updatedAt: now
        )

        accounts.append(account)
        let guidance = SSHKeyGuidance(
            accountID: accountID,
            privateKeyPath: keyPair.privateKeyPath,
            publicKeyPath: keyPair.publicKeyPath,
            publicKey: publicKey,
            githubSSHKeysURL: URL(string: "https://github.com/settings/keys")!,
            statusText: "待添加到 GitHub",
            deployKeyWarning: "请添加到 GitHub 账号的 SSH keys，不要添加到仓库的 Deploy keys。",
            isReady: false
        )
        sshKeyGuidanceByAccountID[accountID] = guidance
        try accountStore?.save(account)
        try sshKeyGuidanceStore?.save(guidance)
        return accountID
    }

    func confirmGitHubKeyAdded(accountID: UUID) {
        guard let guidance = sshKeyGuidanceByAccountID[accountID] else {
            return
        }

        let updatedGuidance = SSHKeyGuidance(
            accountID: guidance.accountID,
            privateKeyPath: guidance.privateKeyPath,
            publicKeyPath: guidance.publicKeyPath,
            publicKey: guidance.publicKey,
            githubSSHKeysURL: guidance.githubSSHKeysURL,
            statusText: "GitHub SSH key 已就绪",
            deployKeyWarning: guidance.deployKeyWarning,
            isReady: true
        )
        sshKeyGuidanceByAccountID[accountID] = updatedGuidance

        do {
            try sshKeyGuidanceStore?.save(updatedGuidance)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteAccount(id accountID: UUID) {
        accounts.removeAll { $0.id == accountID }
        sshKeyGuidanceByAccountID[accountID] = nil
        selectedAccountIDByRepositoryPath = selectedAccountIDByRepositoryPath.filter { $0.value != accountID }
        repositories = repositories.map { repository in
            var updated = repository
            if updated.currentAccountID == accountID {
                updated.currentAccountID = nil
            }
            return updated
        }
        do {
            try accountStore?.delete(id: accountID)
            try sshKeyGuidanceStore?.delete(accountID: accountID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func bind(repositoryPath: String, accountID: UUID) {
        let normalizedPath = normalizedRepositoryPath(repositoryPath)
        selectedAccountIDByRepositoryPath[normalizedPath] = accountID
        repositories = repositories.map { repository in
            guard repository.repositoryPath == normalizedPath else {
                return repository
            }

            var updated = repository
            updated.currentAccountID = accountID
            return updated
        }

        guard let repository = repositories.first(where: { $0.repositoryPath == normalizedPath }) else {
            return
        }

        do {
            try repositoryBindingStore?.save(
                RepositoryBinding(
                    id: repository.id,
                    repositoryPath: normalizedPath,
                    accountID: accountID,
                    remoteURL: repository.originURL,
                    createdAt: repository.lastScannedAt ?? .now,
                    updatedAt: .now
                )
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addRepository(path repositoryPath: String, accountID: UUID) throws {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(
            atPath: URL(fileURLWithPath: repositoryPath).appendingPathComponent(".git").path(),
            isDirectory: &isDirectory
        ) else {
            throw HomeViewModelError.notAGitRepository
        }

        let normalizedPath = URL(fileURLWithPath: repositoryPath).standardizedFileURL.path()
        guard !repositories.contains(where: { $0.repositoryPath == normalizedPath }) else {
            throw HomeViewModelError.repositoryAlreadyManaged
        }

        repositories.append(
            RepositoryRecord(
                id: UUID(),
                repositoryPath: normalizedPath,
                repositoryName: URL(fileURLWithPath: normalizedPath).lastPathComponent,
                currentAccountID: accountID,
                lastScannedAt: .now
            )
        )
        bind(repositoryPath: normalizedPath, accountID: accountID)
    }

    func deleteRepository(path repositoryPath: String) {
        let normalizedPath = normalizedRepositoryPath(repositoryPath)
        repositories.removeAll { $0.repositoryPath == normalizedPath }
        selectedAccountIDByRepositoryPath[normalizedPath] = nil
        do {
            try repositoryBindingStore?.delete(repositoryPath: normalizedPath)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func bindingAccountID(forRepositoryPath repositoryPath: String) -> UUID? {
        let normalizedPath = normalizedRepositoryPath(repositoryPath)
        if let selectedAccountID = selectedAccountIDByRepositoryPath[normalizedPath] {
            return selectedAccountID
        }

        return repositories.first { $0.repositoryPath == normalizedPath }?.currentAccountID
    }

    func bindingAccountDisplayName(forRepositoryPath repositoryPath: String) -> String {
        guard let accountID = bindingAccountID(forRepositoryPath: repositoryPath),
              let account = accounts.first(where: { $0.id == accountID }) else {
            return "未绑定"
        }

        return account.displayName
    }

    func buildApplyPreview(
        workspaceRuleRoots: [String] = [],
        hasGlobalDefault: Bool = false,
        service: ApplyPreviewService = ApplyPreviewService()
    ) throws {
        applyPreview = try service.buildPreview(
            repositoryPaths: repositories.map(\.repositoryPath),
            workspaceRuleRoots: workspaceRuleRoots,
            hasGlobalDefault: hasGlobalDefault
        )
    }

    @discardableResult
    func applyRepositoryBindings() throws -> GitConfigApplyResult {
        let result = try gitConfigApplyService.applyRepositoryBindings(
            repositories: repositories,
            accounts: accounts,
            sshKeyGuidanceByAccountID: sshKeyGuidanceByAccountID
        )

        if let snapshot = result.snapshot {
            try snapshotStore?.save(snapshot)
        }

        lastApplyResultText = "已应用 \(result.appliedRepositoryPaths.count) 个仓库配置，并创建应用前快照。"
        return result
    }

    private func normalizedRepositoryPath(_ path: String) -> String {
        URL(fileURLWithPath: path).standardizedFileURL.path()
    }
}

enum HomeViewModelError: LocalizedError {
    case notAGitRepository
    case repositoryAlreadyManaged

    var errorDescription: String? {
        switch self {
        case .notAGitRepository:
            return "请选择包含 .git 的本地仓库目录。"
        case .repositoryAlreadyManaged:
            return "这个仓库已经在管理列表中。"
        }
    }
}
