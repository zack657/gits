import Foundation
import Testing
@testable import GitAccountBinder

struct PersistenceStoreTests {
    @Test
    func repositoryBindingSaveReusesLogicalRepositoryPath() throws {
        let databaseManager = try DatabaseManager.inMemory()
        let accountStore = AccountStore(databaseWriter: databaseManager.writer)
        let store = RepositoryBindingStore(databaseWriter: databaseManager.writer)
        let originalCreatedAt = Date(timeIntervalSince1970: 1_000)
        let updatedAt = Date(timeIntervalSince1970: 2_000)
        let originalAccount = makeAccount(
            id: UUID(),
            name: "绑定账号-原始",
            createdAt: originalCreatedAt,
            updatedAt: originalCreatedAt
        )
        let replacementAccount = makeAccount(
            id: UUID(),
            name: "绑定账号-更新",
            createdAt: updatedAt,
            updatedAt: updatedAt
        )
        let original = RepositoryBinding(
            id: UUID(),
            repositoryPath: "/tmp/repo-a",
            accountID: originalAccount.id,
            remoteURL: "git@github.com:old/repo.git",
            branchPattern: "main",
            priority: 1,
            createdAt: originalCreatedAt,
            updatedAt: originalCreatedAt
        )
        let replacement = RepositoryBinding(
            id: UUID(),
            repositoryPath: original.repositoryPath,
            accountID: replacementAccount.id,
            remoteURL: "git@github.com:new/repo.git",
            branchPattern: "release/*",
            priority: 9,
            createdAt: updatedAt,
            updatedAt: updatedAt
        )

        try accountStore.save(originalAccount)
        try accountStore.save(replacementAccount)
        try store.save(original)
        try store.save(replacement)
        let bindings = try store.fetchAll()

        #expect(bindings.count == 1)
        #expect(bindings[0].id == replacement.id)
        #expect(bindings[0].repositoryPath == replacement.repositoryPath)
        #expect(bindings[0].accountID == replacement.accountID)
        #expect(bindings[0].remoteURL == replacement.remoteURL)
        #expect(bindings[0].branchPattern == replacement.branchPattern)
        #expect(bindings[0].priority == replacement.priority)
        #expect(bindings[0].createdAt == originalCreatedAt)
        #expect(bindings[0].updatedAt == updatedAt)
    }

    @Test
    func workspaceRuleSaveReusesLogicalWorkspaceRootPath() throws {
        let databaseManager = try DatabaseManager.inMemory()
        let accountStore = AccountStore(databaseWriter: databaseManager.writer)
        let store = WorkspaceRuleStore(databaseWriter: databaseManager.writer)
        let originalCreatedAt = Date(timeIntervalSince1970: 10_000)
        let updatedAt = Date(timeIntervalSince1970: 20_000)
        let originalAccount = makeAccount(
            id: UUID(),
            name: "规则账号-原始",
            createdAt: originalCreatedAt,
            updatedAt: originalCreatedAt
        )
        let replacementAccount = makeAccount(
            id: UUID(),
            name: "规则账号-更新",
            createdAt: updatedAt,
            updatedAt: updatedAt
        )
        let original = WorkspaceRule(
            id: UUID(),
            workspaceRootPath: "/tmp/workspace-a",
            defaultAccountID: originalAccount.id,
            includePatterns: ["client/*"],
            excludePatterns: [".build"],
            createdAt: originalCreatedAt,
            updatedAt: originalCreatedAt
        )
        let replacement = WorkspaceRule(
            id: UUID(),
            workspaceRootPath: original.workspaceRootPath,
            defaultAccountID: replacementAccount.id,
            includePatterns: ["apps/*", "tools/*"],
            excludePatterns: [".build", "DerivedData"],
            createdAt: updatedAt,
            updatedAt: updatedAt
        )

        try accountStore.save(originalAccount)
        try accountStore.save(replacementAccount)
        try store.save(original)
        try store.save(replacement)
        let rules = try store.fetchAll()

        #expect(rules.count == 1)
        #expect(rules[0].id == replacement.id)
        #expect(rules[0].workspaceRootPath == replacement.workspaceRootPath)
        #expect(rules[0].defaultAccountID == replacement.defaultAccountID)
        #expect(rules[0].includePatterns == replacement.includePatterns)
        #expect(rules[0].excludePatterns == replacement.excludePatterns)
        #expect(rules[0].createdAt == originalCreatedAt)
        #expect(rules[0].updatedAt == updatedAt)
    }

    @Test
    func workspaceRuleRoundTripsIncludeAndExcludePatterns() throws {
        let databaseManager = try DatabaseManager.inMemory()
        let accountStore = AccountStore(databaseWriter: databaseManager.writer)
        let store = WorkspaceRuleStore(databaseWriter: databaseManager.writer)
        let account = makeAccount(
            id: UUID(),
            name: "规则账号-模式",
            createdAt: Date(timeIntervalSince1970: 30_000),
            updatedAt: Date(timeIntervalSince1970: 30_000)
        )
        let rule = WorkspaceRule(
            id: UUID(),
            workspaceRootPath: "/tmp/workspace-b",
            defaultAccountID: account.id,
            includePatterns: ["apps/*", "packages/shared", "scripts/**"],
            excludePatterns: [".build", "DerivedData", "tmp/cache"]
        )

        try accountStore.save(account)
        try store.save(rule)
        let rules = try store.fetchAll()

        #expect(rules.count == 1)
        #expect(rules[0].includePatterns == rule.includePatterns)
        #expect(rules[0].excludePatterns == rule.excludePatterns)
    }

    @Test
    func accountStorePreservesCreatedAtWhenUpdatingExistingAccount() throws {
        let databaseManager = try DatabaseManager.inMemory()
        let store = AccountStore(databaseWriter: databaseManager.writer)
        let accountID = UUID()
        let originalCreatedAt = Date(timeIntervalSince1970: 100)
        let updatedAt = Date(timeIntervalSince1970: 500)
        let original = Account(
            id: accountID,
            displayName: "工作账号",
            gitUserName: "worker",
            gitUserEmail: "worker@example.com",
            platformType: .gitlab,
            sshKeyID: UUID(),
            signingKey: "OLDKEY",
            isGlobalDefault: false,
            createdAt: originalCreatedAt,
            updatedAt: originalCreatedAt
        )
        let updated = Account(
            id: accountID,
            displayName: "工作账号-更新",
            gitUserName: "worker-updated",
            gitUserEmail: "worker+updated@example.com",
            platformType: .github,
            sshKeyID: nil,
            signingKey: "NEWKEY",
            isGlobalDefault: true,
            createdAt: updatedAt,
            updatedAt: updatedAt
        )

        try store.save(original)
        try store.save(updated)
        let accounts = try store.fetchAll()

        #expect(accounts.count == 1)
        #expect(accounts[0].displayName == updated.displayName)
        #expect(accounts[0].gitUserName == updated.gitUserName)
        #expect(accounts[0].gitUserEmail == updated.gitUserEmail)
        #expect(accounts[0].platformType == updated.platformType)
        #expect(accounts[0].sshKeyID == updated.sshKeyID)
        #expect(accounts[0].signingKey == updated.signingKey)
        #expect(accounts[0].isGlobalDefault == updated.isGlobalDefault)
        #expect(accounts[0].createdAt == originalCreatedAt)
        #expect(accounts[0].updatedAt == updatedAt)
    }

    @Test
    func snapshotStorePreservesCreatedAtWhenUpdatingExistingSnapshot() throws {
        let databaseManager = try DatabaseManager.inMemory()
        let store = SnapshotStore(databaseWriter: databaseManager.writer)
        let snapshotID = UUID()
        let originalCreatedAt = Date(timeIntervalSince1970: 700)
        let updatedCreatedAt = Date(timeIntervalSince1970: 1_400)
        let original = ConfigSnapshot(
            id: snapshotID,
            scope: .global,
            targetPath: "/tmp/.gitconfig",
            gitConfigContent: "[user]\n\tname = old",
            sshConfigContent: "Host old",
            knownHostsContent: "github.com ssh-ed25519 AAAA",
            note: "original",
            createdAt: originalCreatedAt
        )
        let updated = ConfigSnapshot(
            id: snapshotID,
            scope: .repository,
            targetPath: "/tmp/repo/.git/config",
            gitConfigContent: "[user]\n\tname = new",
            sshConfigContent: "Host new",
            knownHostsContent: nil,
            note: "updated",
            createdAt: updatedCreatedAt
        )

        try store.save(original)
        try store.save(updated)
        let snapshots = try store.fetchAll()

        #expect(snapshots.count == 1)
        #expect(snapshots[0].id == snapshotID)
        #expect(snapshots[0].scope == updated.scope)
        #expect(snapshots[0].targetPath == updated.targetPath)
        #expect(snapshots[0].gitConfigContent == updated.gitConfigContent)
        #expect(snapshots[0].sshConfigContent == updated.sshConfigContent)
        #expect(snapshots[0].knownHostsContent == updated.knownHostsContent)
        #expect(snapshots[0].note == updated.note)
        #expect(snapshots[0].createdAt == originalCreatedAt)
    }

    @Test
    func accountStoreKeepsOnlyOneGlobalDefaultAfterSavingNewDefault() throws {
        let databaseManager = try DatabaseManager.inMemory()
        let store = AccountStore(databaseWriter: databaseManager.writer)
        let firstDefault = Account(
            id: UUID(),
            displayName: "默认账号A",
            gitUserName: "default-a",
            gitUserEmail: "default-a@example.com",
            platformType: .github,
            sshKeyID: nil,
            signingKey: nil,
            isGlobalDefault: true,
            createdAt: Date(timeIntervalSince1970: 50),
            updatedAt: Date(timeIntervalSince1970: 50)
        )
        let secondDefault = Account(
            id: UUID(),
            displayName: "默认账号B",
            gitUserName: "default-b",
            gitUserEmail: "default-b@example.com",
            platformType: .gitlab,
            sshKeyID: nil,
            signingKey: nil,
            isGlobalDefault: true,
            createdAt: Date(timeIntervalSince1970: 100),
            updatedAt: Date(timeIntervalSince1970: 100)
        )

        try store.save(firstDefault)
        try store.save(secondDefault)
        let accounts = try store.fetchAll()
        let defaults = accounts.filter(\.isGlobalDefault)

        #expect(accounts.count == 2)
        #expect(defaults.count == 1)
        #expect(defaults[0].id == secondDefault.id)
        #expect(accounts.first(where: { $0.id == firstDefault.id })?.isGlobalDefault == false)
    }

    private func makeAccount(
        id: UUID,
        name: String,
        createdAt: Date,
        updatedAt: Date
    ) -> Account {
        Account(
            id: id,
            displayName: name,
            gitUserName: name,
            gitUserEmail: "\(name)@example.com",
            platformType: .github,
            sshKeyID: nil,
            signingKey: nil,
            isGlobalDefault: false,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
