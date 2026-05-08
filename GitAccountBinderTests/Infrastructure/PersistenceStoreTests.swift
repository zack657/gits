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
        #expect(bindings[0].id == original.id)
        #expect(bindings[0].repositoryPath == replacement.repositoryPath)
        #expect(bindings[0].accountID == replacement.accountID)
        #expect(bindings[0].remoteURL == replacement.remoteURL)
        #expect(bindings[0].branchPattern == replacement.branchPattern)
        #expect(bindings[0].priority == replacement.priority)
        #expect(bindings[0].createdAt == originalCreatedAt)
        #expect(bindings[0].updatedAt == updatedAt)
    }

    @Test
    func repositoryBindingSaveNormalizesPathCasingAndTrailingSlash() throws {
        let databaseManager = try DatabaseManager.inMemory()
        let accountStore = AccountStore(databaseWriter: databaseManager.writer)
        let store = RepositoryBindingStore(databaseWriter: databaseManager.writer)
        let account = makeAccount(
            id: UUID(),
            name: "路径规范账号",
            createdAt: Date(timeIntervalSince1970: 2_500),
            updatedAt: Date(timeIntervalSince1970: 2_500)
        )
        let original = RepositoryBinding(
            id: UUID(),
            repositoryPath: "/tmp/Repo-Normalized/",
            accountID: account.id,
            remoteURL: "git@github.com:normalized/repo.git",
            branchPattern: "main",
            priority: 1
        )
        let replacement = RepositoryBinding(
            id: UUID(),
            repositoryPath: "/tmp/repo-normalized",
            accountID: account.id,
            remoteURL: "git@github.com:normalized/repo-v2.git",
            branchPattern: "release/*",
            priority: 2
        )

        try accountStore.save(account)
        try store.save(original)
        try store.save(replacement)
        let bindings = try store.fetchAll()

        #expect(bindings.count == 1)
        #expect(bindings[0].id == original.id)
        #expect(bindings[0].repositoryPath == "/tmp/repo-normalized")
        #expect(bindings[0].remoteURL == replacement.remoteURL)
    }

    @Test
    func repositoryBindingSaveMatchesUnicodeCaseVariants() throws {
        let databaseManager = try DatabaseManager.inMemory()
        let accountStore = AccountStore(databaseWriter: databaseManager.writer)
        let store = RepositoryBindingStore(databaseWriter: databaseManager.writer)
        let account = makeAccount(
            id: UUID(),
            name: "Unicode路径账号",
            createdAt: Date(timeIntervalSince1970: 2_700),
            updatedAt: Date(timeIntervalSince1970: 2_700)
        )
        let original = RepositoryBinding(
            id: UUID(),
            repositoryPath: "/tmp/ÄRepo",
            accountID: account.id,
            remoteURL: "git@github.com:unicode/repo.git",
            branchPattern: "main",
            priority: 1
        )
        let replacement = RepositoryBinding(
            id: UUID(),
            repositoryPath: "/tmp/ärepo/",
            accountID: account.id,
            remoteURL: "git@github.com:unicode/repo-v2.git",
            branchPattern: "release/*",
            priority: 2
        )

        try accountStore.save(account)
        try store.save(original)
        try store.save(replacement)
        let bindings = try store.fetchAll()

        #expect(bindings.count == 1)
        #expect(bindings[0].id == original.id)
        #expect(bindings[0].remoteURL == replacement.remoteURL)
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
        #expect(rules[0].id == original.id)
        #expect(rules[0].workspaceRootPath == replacement.workspaceRootPath)
        #expect(rules[0].defaultAccountID == replacement.defaultAccountID)
        #expect(rules[0].includePatterns == replacement.includePatterns)
        #expect(rules[0].excludePatterns == replacement.excludePatterns)
        #expect(rules[0].createdAt == originalCreatedAt)
        #expect(rules[0].updatedAt == updatedAt)
    }

    @Test
    func workspaceRuleSaveNormalizesPathCasingAndTrailingSlash() throws {
        let databaseManager = try DatabaseManager.inMemory()
        let accountStore = AccountStore(databaseWriter: databaseManager.writer)
        let store = WorkspaceRuleStore(databaseWriter: databaseManager.writer)
        let account = makeAccount(
            id: UUID(),
            name: "目录规范账号",
            createdAt: Date(timeIntervalSince1970: 25_000),
            updatedAt: Date(timeIntervalSince1970: 25_000)
        )
        let original = WorkspaceRule(
            id: UUID(),
            workspaceRootPath: "/tmp/Workspace-Normalized/",
            defaultAccountID: account.id,
            includePatterns: ["apps/*"],
            excludePatterns: [".build"]
        )
        let replacement = WorkspaceRule(
            id: UUID(),
            workspaceRootPath: "/tmp/workspace-normalized",
            defaultAccountID: account.id,
            includePatterns: ["tools/*"],
            excludePatterns: ["DerivedData"]
        )

        try accountStore.save(account)
        try store.save(original)
        try store.save(replacement)
        let rules = try store.fetchAll()

        #expect(rules.count == 1)
        #expect(rules[0].id == original.id)
        #expect(rules[0].workspaceRootPath == "/tmp/workspace-normalized")
        #expect(rules[0].includePatterns == replacement.includePatterns)
        #expect(rules[0].excludePatterns == replacement.excludePatterns)
    }

    @Test
    func workspaceRuleSaveMatchesUnicodeCaseVariants() throws {
        let databaseManager = try DatabaseManager.inMemory()
        let accountStore = AccountStore(databaseWriter: databaseManager.writer)
        let store = WorkspaceRuleStore(databaseWriter: databaseManager.writer)
        let account = makeAccount(
            id: UUID(),
            name: "Unicode目录账号",
            createdAt: Date(timeIntervalSince1970: 26_000),
            updatedAt: Date(timeIntervalSince1970: 26_000)
        )
        let original = WorkspaceRule(
            id: UUID(),
            workspaceRootPath: "/tmp/ÄWorkspace",
            defaultAccountID: account.id,
            includePatterns: ["apps/*"],
            excludePatterns: [".build"]
        )
        let replacement = WorkspaceRule(
            id: UUID(),
            workspaceRootPath: "/tmp/äworkspace/",
            defaultAccountID: account.id,
            includePatterns: ["tools/*"],
            excludePatterns: ["DerivedData"]
        )

        try accountStore.save(account)
        try store.save(original)
        try store.save(replacement)
        let rules = try store.fetchAll()

        #expect(rules.count == 1)
        #expect(rules[0].id == original.id)
        #expect(rules[0].includePatterns == replacement.includePatterns)
        #expect(rules[0].excludePatterns == replacement.excludePatterns)
    }

    @Test
    func repositoryBindingSaveThrowsOnConflictingIdentifierAndRepositoryPathMatches() throws {
        let databaseManager = try DatabaseManager.inMemory()
        let accountStore = AccountStore(databaseWriter: databaseManager.writer)
        let store = RepositoryBindingStore(databaseWriter: databaseManager.writer)
        let createdAt = Date(timeIntervalSince1970: 3_000)
        let updatedAt = Date(timeIntervalSince1970: 4_000)
        let firstAccount = makeAccount(
            id: UUID(),
            name: "冲突绑定账号A",
            createdAt: createdAt,
            updatedAt: createdAt
        )
        let secondAccount = makeAccount(
            id: UUID(),
            name: "冲突绑定账号B",
            createdAt: updatedAt,
            updatedAt: updatedAt
        )
        let idMatched = RepositoryBinding(
            id: UUID(),
            repositoryPath: "/tmp/repo-conflict-id",
            accountID: firstAccount.id,
            remoteURL: "git@github.com:conflict/id.git",
            branchPattern: "main",
            priority: 1,
            createdAt: createdAt,
            updatedAt: createdAt
        )
        let logicalKeyMatched = RepositoryBinding(
            id: UUID(),
            repositoryPath: "/tmp/repo-conflict-path",
            accountID: secondAccount.id,
            remoteURL: "git@github.com:conflict/path.git",
            branchPattern: "release/*",
            priority: 2,
            createdAt: createdAt,
            updatedAt: createdAt
        )
        let conflictingSave = RepositoryBinding(
            id: idMatched.id,
            repositoryPath: logicalKeyMatched.repositoryPath,
            accountID: secondAccount.id,
            remoteURL: "git@github.com:conflict/new.git",
            branchPattern: "hotfix/*",
            priority: 9,
            createdAt: updatedAt,
            updatedAt: updatedAt
        )

        try accountStore.save(firstAccount)
        try accountStore.save(secondAccount)
        try store.save(idMatched)
        try store.save(logicalKeyMatched)

        do {
            try store.save(conflictingSave)
            Issue.record("Expected conflicting repository binding save to throw")
        } catch {
            #expect(String(describing: error).contains("Ambiguous repository binding save conflict"))
        }

        let bindings = try store.fetchAll()
        #expect(bindings.count == 2)
        #expect(bindings.first(where: { $0.id == idMatched.id })?.repositoryPath == idMatched.repositoryPath)
        #expect(bindings.first(where: { $0.id == logicalKeyMatched.id })?.repositoryPath == logicalKeyMatched.repositoryPath)
        #expect(bindings.first(where: { $0.id == idMatched.id })?.accountID == idMatched.accountID)
        #expect(bindings.first(where: { $0.id == logicalKeyMatched.id })?.accountID == logicalKeyMatched.accountID)
    }

    @Test
    func workspaceRuleSaveThrowsOnConflictingIdentifierAndWorkspaceRootMatches() throws {
        let databaseManager = try DatabaseManager.inMemory()
        let accountStore = AccountStore(databaseWriter: databaseManager.writer)
        let store = WorkspaceRuleStore(databaseWriter: databaseManager.writer)
        let createdAt = Date(timeIntervalSince1970: 21_000)
        let updatedAt = Date(timeIntervalSince1970: 22_000)
        let firstAccount = makeAccount(
            id: UUID(),
            name: "冲突规则账号A",
            createdAt: createdAt,
            updatedAt: createdAt
        )
        let secondAccount = makeAccount(
            id: UUID(),
            name: "冲突规则账号B",
            createdAt: updatedAt,
            updatedAt: updatedAt
        )
        let idMatched = WorkspaceRule(
            id: UUID(),
            workspaceRootPath: "/tmp/workspace-conflict-id",
            defaultAccountID: firstAccount.id,
            includePatterns: ["client/*"],
            excludePatterns: [".build"],
            createdAt: createdAt,
            updatedAt: createdAt
        )
        let logicalKeyMatched = WorkspaceRule(
            id: UUID(),
            workspaceRootPath: "/tmp/workspace-conflict-root",
            defaultAccountID: secondAccount.id,
            includePatterns: ["apps/*"],
            excludePatterns: ["DerivedData"],
            createdAt: createdAt,
            updatedAt: createdAt
        )
        let conflictingSave = WorkspaceRule(
            id: idMatched.id,
            workspaceRootPath: logicalKeyMatched.workspaceRootPath,
            defaultAccountID: secondAccount.id,
            includePatterns: ["tools/*"],
            excludePatterns: ["tmp/cache"],
            createdAt: updatedAt,
            updatedAt: updatedAt
        )

        try accountStore.save(firstAccount)
        try accountStore.save(secondAccount)
        try store.save(idMatched)
        try store.save(logicalKeyMatched)

        do {
            try store.save(conflictingSave)
            Issue.record("Expected conflicting workspace rule save to throw")
        } catch {
            #expect(String(describing: error).contains("Ambiguous workspace rule save conflict"))
        }

        let rules = try store.fetchAll()
        #expect(rules.count == 2)
        #expect(rules.first(where: { $0.id == idMatched.id })?.workspaceRootPath == idMatched.workspaceRootPath)
        #expect(rules.first(where: { $0.id == logicalKeyMatched.id })?.workspaceRootPath == logicalKeyMatched.workspaceRootPath)
        #expect(rules.first(where: { $0.id == idMatched.id })?.defaultAccountID == idMatched.defaultAccountID)
        #expect(rules.first(where: { $0.id == logicalKeyMatched.id })?.defaultAccountID == logicalKeyMatched.defaultAccountID)
    }

    @Test
    func deletingAccountCascadeDeletesRelatedRepositoryBindings() throws {
        let databaseManager = try DatabaseManager.inMemory()
        let accountStore = AccountStore(databaseWriter: databaseManager.writer)
        let bindingStore = RepositoryBindingStore(databaseWriter: databaseManager.writer)
        let account = makeAccount(
            id: UUID(),
            name: "级联绑定账号",
            createdAt: Date(timeIntervalSince1970: 40_000),
            updatedAt: Date(timeIntervalSince1970: 40_000)
        )
        let binding = RepositoryBinding(
            id: UUID(),
            repositoryPath: "/tmp/repo-cascade",
            accountID: account.id,
            remoteURL: "git@github.com:cascade/repo.git",
            branchPattern: "main",
            priority: 1
        )

        try accountStore.save(account)
        try bindingStore.save(binding)

        try databaseManager.writer.write { db in
            try db.execute(
                sql: "DELETE FROM accounts WHERE id = ?",
                arguments: [account.id.uuidString]
            )
        }

        let bindings = try bindingStore.fetchAll()
        #expect(bindings.isEmpty)
    }

    @Test
    func deletingAccountNullsWorkspaceRuleDefaultAccount() throws {
        let databaseManager = try DatabaseManager.inMemory()
        let accountStore = AccountStore(databaseWriter: databaseManager.writer)
        let ruleStore = WorkspaceRuleStore(databaseWriter: databaseManager.writer)
        let account = makeAccount(
            id: UUID(),
            name: "置空规则账号",
            createdAt: Date(timeIntervalSince1970: 50_000),
            updatedAt: Date(timeIntervalSince1970: 50_000)
        )
        let rule = WorkspaceRule(
            id: UUID(),
            workspaceRootPath: "/tmp/workspace-null-default",
            defaultAccountID: account.id,
            includePatterns: ["apps/*"],
            excludePatterns: [".build"]
        )

        try accountStore.save(account)
        try ruleStore.save(rule)

        try databaseManager.writer.write { db in
            try db.execute(
                sql: "DELETE FROM accounts WHERE id = ?",
                arguments: [account.id.uuidString]
            )
        }

        let rules = try ruleStore.fetchAll()
        #expect(rules.count == 1)
        #expect(rules[0].id == rule.id)
        #expect(rules[0].defaultAccountID == nil)
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
