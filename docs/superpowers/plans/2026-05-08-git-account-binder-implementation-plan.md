# Git Account Binder Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a macOS-native app that manages multiple Git identities, binds repositories to the correct account, applies Git and SSH config safely, and supports snapshot-based rollback with Simplified Chinese UI by default.

**Architecture:** Use a SwiftUI macOS app with a small service layer around Git, SSH, snapshots, and diagnostics. Persist app state in SQLite-backed storage, write runtime behavior through native Git/SSH config files, and validate every apply with snapshot-first rollback protection.

**Tech Stack:** SwiftUI, Swift 6, Swift Testing or XCTest, SQLite via GRDB, `Process` for shell tooling, macOS sandbox-disabled local file access, Git, ssh, ssh-keygen

---

## File Structure

### App Target

- `GitAccountBinder/GitAccountBinderApp.swift`
  App entry point, dependency container bootstrap, default Chinese locale wiring.
- `GitAccountBinder/App/AppRouter.swift`
  Top-level navigation state for Home, Account Detail, Workspace Defaults, History, Diagnostics.
- `GitAccountBinder/App/AppContainer.swift`
  Central dependency container for repositories, services, and stores.
- `GitAccountBinder/App/AppStrings.swift`
  Default Simplified Chinese labels and copy constants used across initial screens.

### Models

- `GitAccountBinder/Domain/Models/Account.swift`
- `GitAccountBinder/Domain/Models/RepositoryBinding.swift`
- `GitAccountBinder/Domain/Models/WorkspaceRule.swift`
- `GitAccountBinder/Domain/Models/ConfigSnapshot.swift`
- `GitAccountBinder/Domain/Models/RepositoryRecord.swift`
- `GitAccountBinder/Domain/Models/ResolutionResult.swift`

### Persistence

- `GitAccountBinder/Infrastructure/Database/DatabaseManager.swift`
- `GitAccountBinder/Infrastructure/Database/Migrations.swift`
- `GitAccountBinder/Infrastructure/Repositories/AccountStore.swift`
- `GitAccountBinder/Infrastructure/Repositories/RepositoryBindingStore.swift`
- `GitAccountBinder/Infrastructure/Repositories/WorkspaceRuleStore.swift`
- `GitAccountBinder/Infrastructure/Repositories/SnapshotStore.swift`

### Services

- `GitAccountBinder/Infrastructure/Shell/ShellCommandRunner.swift`
- `GitAccountBinder/Infrastructure/Git/GitRepositoryScanner.swift`
- `GitAccountBinder/Infrastructure/Git/GitConfigWriter.swift`
- `GitAccountBinder/Infrastructure/SSH/SSHKeyService.swift`
- `GitAccountBinder/Infrastructure/Config/ResolutionService.swift`
- `GitAccountBinder/Infrastructure/Config/ApplyPreviewService.swift`
- `GitAccountBinder/Infrastructure/Snapshots/SnapshotService.swift`
- `GitAccountBinder/Infrastructure/Diagnostics/DiagnosticsService.swift`
- `GitAccountBinder/Infrastructure/Paths/AppPathService.swift`

### View Models

- `GitAccountBinder/Features/Home/HomeViewModel.swift`
- `GitAccountBinder/Features/Accounts/AccountDetailViewModel.swift`
- `GitAccountBinder/Features/WorkspaceDefaults/WorkspaceDefaultsViewModel.swift`
- `GitAccountBinder/Features/History/HistoryViewModel.swift`
- `GitAccountBinder/Features/Diagnostics/DiagnosticsViewModel.swift`

### Views

- `GitAccountBinder/Features/Home/HomeView.swift`
- `GitAccountBinder/Features/Accounts/AccountListView.swift`
- `GitAccountBinder/Features/Accounts/AccountDetailView.swift`
- `GitAccountBinder/Features/Repositories/RepositoryListView.swift`
- `GitAccountBinder/Features/WorkspaceDefaults/WorkspaceDefaultsView.swift`
- `GitAccountBinder/Features/History/HistoryView.swift`
- `GitAccountBinder/Features/Diagnostics/DiagnosticsView.swift`
- `GitAccountBinder/Shared/Components/EmptyStateView.swift`
- `GitAccountBinder/Shared/Components/StatusBadge.swift`
- `GitAccountBinder/Shared/Components/ApplyPreviewSheet.swift`

### Tests

- `GitAccountBinderTests/Domain/ResolutionServiceTests.swift`
- `GitAccountBinderTests/Infrastructure/GitRepositoryScannerTests.swift`
- `GitAccountBinderTests/Infrastructure/GitConfigWriterTests.swift`
- `GitAccountBinderTests/Infrastructure/SSHKeyServiceTests.swift`
- `GitAccountBinderTests/Infrastructure/SnapshotServiceTests.swift`
- `GitAccountBinderTests/Infrastructure/DiagnosticsServiceTests.swift`
- `GitAccountBinderTests/Features/HomeViewModelTests.swift`

## Task 1: Scaffold The macOS App Shell

**Files:**
- Create: `GitAccountBinder/GitAccountBinderApp.swift`
- Create: `GitAccountBinder/App/AppContainer.swift`
- Create: `GitAccountBinder/App/AppRouter.swift`
- Create: `GitAccountBinder/App/AppStrings.swift`
- Create: `GitAccountBinder/Features/Home/HomeView.swift`
- Create: `GitAccountBinder/Shared/Components/EmptyStateView.swift`
- Test: `GitAccountBinderTests/Features/HomeViewModelTests.swift`

- [ ] **Step 1: Write the failing app-shell test**

```swift
import Testing
@testable import GitAccountBinder

struct HomeViewModelTests {
    @Test func homeTitleUsesChineseDefaultCopy() {
        #expect(AppStrings.homeTitle == "Git 账号绑定器")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme GitAccountBinder -destination 'platform=macOS' -only-testing:GitAccountBinderTests/HomeViewModelTests`
Expected: FAIL with missing `AppStrings` or test target compile errors because the app shell files do not exist yet.

- [ ] **Step 3: Create the minimal app shell**

```swift
import SwiftUI

@main
struct GitAccountBinderApp: App {
    @State private var container = AppContainer.bootstrap()

    var body: some Scene {
        WindowGroup {
            HomeView(container: container)
                .environment(\.locale, Locale(identifier: "zh-Hans"))
        }
    }
}
```

```swift
import Foundation

struct AppStrings {
    static let homeTitle = "Git 账号绑定器"
    static let accountsTitle = "账号"
    static let repositoriesTitle = "仓库"
}
```

- [ ] **Step 4: Add a minimal Home screen**

```swift
import SwiftUI

struct HomeView: View {
    let container: AppContainer

    var body: some View {
        NavigationSplitView {
            EmptyStateView(title: AppStrings.accountsTitle, message: "还没有账号")
        } detail: {
            EmptyStateView(title: AppStrings.repositoriesTitle, message: "还没有仓库")
        }
        .navigationTitle(AppStrings.homeTitle)
    }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `xcodebuild test -scheme GitAccountBinder -destination 'platform=macOS' -only-testing:GitAccountBinderTests/HomeViewModelTests`
Expected: PASS with `homeTitleUsesChineseDefaultCopy` green.

- [ ] **Step 6: Commit**

```bash
git add GitAccountBinder GitAccountBinderTests
git commit -m "feat: scaffold macOS app shell"
```

## Task 2: Add Domain Models And SQLite Persistence

**Files:**
- Create: `GitAccountBinder/Domain/Models/Account.swift`
- Create: `GitAccountBinder/Domain/Models/RepositoryBinding.swift`
- Create: `GitAccountBinder/Domain/Models/WorkspaceRule.swift`
- Create: `GitAccountBinder/Domain/Models/ConfigSnapshot.swift`
- Create: `GitAccountBinder/Domain/Models/RepositoryRecord.swift`
- Create: `GitAccountBinder/Domain/Models/ResolutionResult.swift`
- Create: `GitAccountBinder/Infrastructure/Database/DatabaseManager.swift`
- Create: `GitAccountBinder/Infrastructure/Database/Migrations.swift`
- Create: `GitAccountBinder/Infrastructure/Repositories/AccountStore.swift`
- Create: `GitAccountBinder/Infrastructure/Repositories/RepositoryBindingStore.swift`
- Create: `GitAccountBinder/Infrastructure/Repositories/WorkspaceRuleStore.swift`
- Create: `GitAccountBinder/Infrastructure/Repositories/SnapshotStore.swift`
- Test: `GitAccountBinderTests/Domain/ResolutionServiceTests.swift`

- [ ] **Step 1: Write the failing persistence smoke test**

```swift
import Testing
@testable import GitAccountBinder

struct ResolutionServiceTests {
    @Test func accountModelSupportsDefaultFlag() {
        let account = Account(
            id: UUID(),
            displayName: "个人账号",
            gitUserName: "ctw",
            gitUserEmail: "ctw@example.com",
            platformType: .github,
            sshKeyID: nil,
            signingKey: nil,
            isGlobalDefault: true
        )

        #expect(account.isGlobalDefault)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme GitAccountBinder -destination 'platform=macOS' -only-testing:GitAccountBinderTests/ResolutionServiceTests`
Expected: FAIL because `Account` and related model types do not exist yet.

- [ ] **Step 3: Implement the core models**

```swift
import Foundation

struct Account: Identifiable, Codable, Equatable {
    enum PlatformType: String, Codable {
        case github
        case gitlab
        case gitee
        case custom
    }

    let id: UUID
    var displayName: String
    var gitUserName: String
    var gitUserEmail: String
    var platformType: PlatformType
    var sshKeyID: UUID?
    var signingKey: String?
    var isGlobalDefault: Bool
}
```

```swift
import Foundation

struct RepositoryBinding: Identifiable, Codable, Equatable {
    let id: UUID
    var repoPath: String
    var remoteURL: String?
    var accountID: UUID
}
```

- [ ] **Step 4: Add database bootstrap and migrations**

```swift
import Foundation
import GRDB

final class DatabaseManager {
    let dbQueue: DatabaseQueue

    init(path: String) throws {
        dbQueue = try DatabaseQueue(path: path)
        try Migrations.migrator.migrate(dbQueue)
    }
}
```

```swift
import GRDB

enum Migrations {
    static let migrator: DatabaseMigrator = {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1_core") { db in
            try db.create(table: "accounts") { t in
                t.column("id", .text).primaryKey()
                t.column("displayName", .text).notNull()
                t.column("gitUserName", .text).notNull()
                t.column("gitUserEmail", .text).notNull()
                t.column("platformType", .text).notNull()
                t.column("sshKeyID", .text)
                t.column("signingKey", .text)
                t.column("isGlobalDefault", .boolean).notNull()
            }
        }
        return migrator
    }()
}
```

- [ ] **Step 5: Run tests to verify model compilation passes**

Run: `xcodebuild test -scheme GitAccountBinder -destination 'platform=macOS' -only-testing:GitAccountBinderTests/ResolutionServiceTests`
Expected: PASS for the model smoke test, with database code compiling cleanly.

- [ ] **Step 6: Commit**

```bash
git add GitAccountBinder GitAccountBinderTests
git commit -m "feat: add domain models and persistence layer"
```

## Task 3: Implement Account Resolution Rules

**Files:**
- Create: `GitAccountBinder/Infrastructure/Config/ResolutionService.swift`
- Modify: `GitAccountBinder/Domain/Models/ResolutionResult.swift`
- Test: `GitAccountBinderTests/Domain/ResolutionServiceTests.swift`

- [ ] **Step 1: Write the failing resolution-priority test**

```swift
import Testing
@testable import GitAccountBinder

struct ResolutionServiceTests {
    @Test func repositoryBindingWinsOverWorkspaceAndGlobalDefault() throws {
        let workID = UUID()
        let personalID = UUID()

        let service = ResolutionService()
        let result = service.resolve(
            repoPath: "/Users/ctw/work/app-api",
            repositoryBindings: [
                RepositoryBinding(id: UUID(), repoPath: "/Users/ctw/work/app-api", remoteURL: nil, accountID: workID)
            ],
            workspaceRules: [
                WorkspaceRule(id: UUID(), rootPath: "/Users/ctw/work", accountID: personalID)
            ],
            globalDefaultAccountID: personalID
        )

        #expect(result.accountID == workID)
        #expect(result.reason == .repositoryBinding)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme GitAccountBinder -destination 'platform=macOS' -only-testing:GitAccountBinderTests/ResolutionServiceTests`
Expected: FAIL because `ResolutionService`, `WorkspaceRule`, or `ResolutionResult.Reason` is missing.

- [ ] **Step 3: Implement the resolution model**

```swift
import Foundation

struct ResolutionResult: Equatable {
    enum Reason: Equatable {
        case repositoryBinding
        case workspaceRule
        case globalDefault
        case unresolved
    }

    let accountID: UUID?
    let reason: Reason
}
```

```swift
import Foundation

struct ResolutionService {
    func resolve(
        repoPath: String,
        repositoryBindings: [RepositoryBinding],
        workspaceRules: [WorkspaceRule],
        globalDefaultAccountID: UUID?
    ) -> ResolutionResult {
        if let binding = repositoryBindings.first(where: { $0.repoPath == repoPath }) {
            return ResolutionResult(accountID: binding.accountID, reason: .repositoryBinding)
        }

        if let rule = workspaceRules
            .sorted(by: { $0.rootPath.count > $1.rootPath.count })
            .first(where: { repoPath.hasPrefix($0.rootPath) }) {
            return ResolutionResult(accountID: rule.accountID, reason: .workspaceRule)
        }

        if let globalDefaultAccountID {
            return ResolutionResult(accountID: globalDefaultAccountID, reason: .globalDefault)
        }

        return ResolutionResult(accountID: nil, reason: .unresolved)
    }
}
```

- [ ] **Step 4: Add tests for the remaining branches**

```swift
@Test func workspaceRuleWinsWhenNoRepositoryBindingExists() {
    let accountID = UUID()
    let service = ResolutionService()

    let result = service.resolve(
        repoPath: "/Users/ctw/work/tooling",
        repositoryBindings: [],
        workspaceRules: [WorkspaceRule(id: UUID(), rootPath: "/Users/ctw/work", accountID: accountID)],
        globalDefaultAccountID: nil
    )

    #expect(result.accountID == accountID)
    #expect(result.reason == .workspaceRule)
}
```

- [ ] **Step 5: Run tests to verify all resolution rules pass**

Run: `xcodebuild test -scheme GitAccountBinder -destination 'platform=macOS' -only-testing:GitAccountBinderTests/ResolutionServiceTests`
Expected: PASS for repository binding, workspace default, global default, and unresolved cases.

- [ ] **Step 6: Commit**

```bash
git add GitAccountBinder GitAccountBinderTests
git commit -m "feat: implement account resolution rules"
```

## Task 4: Implement SSH Key Generation And Account Readiness

**Files:**
- Create: `GitAccountBinder/Infrastructure/Paths/AppPathService.swift`
- Create: `GitAccountBinder/Infrastructure/Shell/ShellCommandRunner.swift`
- Create: `GitAccountBinder/Infrastructure/SSH/SSHKeyService.swift`
- Modify: `GitAccountBinder/Features/Accounts/AccountDetailView.swift`
- Modify: `GitAccountBinder/Features/Accounts/AccountDetailViewModel.swift`
- Test: `GitAccountBinderTests/Infrastructure/SSHKeyServiceTests.swift`

- [ ] **Step 1: Write the failing SSH key generation test**

```swift
import Testing
@testable import GitAccountBinder

struct SSHKeyServiceTests {
    @Test func generatedKeyPairCreatesPrivateAndPublicKeyFiles() throws {
        let paths = AppPathService(root: FileManager.default.temporaryDirectory.path)
        let runner = FakeShellCommandRunner()
        let service = SSHKeyService(paths: paths, runner: runner)

        let result = try service.generateKeyPair(accountID: UUID(), keyName: "work")

        #expect(result.privateKeyPath.hasSuffix("work"))
        #expect(result.publicKeyPath.hasSuffix("work.pub"))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme GitAccountBinder -destination 'platform=macOS' -only-testing:GitAccountBinderTests/SSHKeyServiceTests`
Expected: FAIL because the shell runner, path service, and SSH service do not exist yet.

- [ ] **Step 3: Implement shell execution and path helpers**

```swift
import Foundation

protocol ShellCommandRunning {
    @discardableResult
    func run(_ launchPath: String, arguments: [String]) throws -> String
}

struct ShellCommandRunner: ShellCommandRunning {
    func run(_ launchPath: String, arguments: [String]) throws -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }
}
```

```swift
import Foundation

struct AppPathService {
    let root: String

    var sshDirectory: String { "\(root)/Keys" }
    var generatedConfigDirectory: String { "\(root)/Generated" }
}
```

- [ ] **Step 4: Implement SSH key generation**

```swift
import Foundation

struct SSHKeyPair {
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
        try FileManager.default.createDirectory(atPath: paths.sshDirectory, withIntermediateDirectories: true)
        let privateKeyPath = "\(paths.sshDirectory)/\(keyName)"
        _ = try runner.run("/usr/bin/ssh-keygen", arguments: ["-t", "ed25519", "-f", privateKeyPath, "-N", "", "-C", accountID.uuidString])
        return SSHKeyPair(privateKeyPath: privateKeyPath, publicKeyPath: "\(privateKeyPath).pub")
    }
}
```

- [ ] **Step 5: Run tests to verify key path behavior**

Run: `xcodebuild test -scheme GitAccountBinder -destination 'platform=macOS' -only-testing:GitAccountBinderTests/SSHKeyServiceTests`
Expected: PASS with fake shell execution and deterministic generated paths.

- [ ] **Step 6: Commit**

```bash
git add GitAccountBinder GitAccountBinderTests
git commit -m "feat: add ssh key generation service"
```

## Task 5: Implement Repository Scanning And Home Binding Flow

**Files:**
- Create: `GitAccountBinder/Infrastructure/Git/GitRepositoryScanner.swift`
- Create: `GitAccountBinder/Features/Home/HomeViewModel.swift`
- Create: `GitAccountBinder/Features/Repositories/RepositoryListView.swift`
- Create: `GitAccountBinder/Features/Accounts/AccountListView.swift`
- Modify: `GitAccountBinder/Features/Home/HomeView.swift`
- Test: `GitAccountBinderTests/Infrastructure/GitRepositoryScannerTests.swift`
- Test: `GitAccountBinderTests/Features/HomeViewModelTests.swift`

- [ ] **Step 1: Write the failing repository scan test**

```swift
import Testing
@testable import GitAccountBinder

struct GitRepositoryScannerTests {
    @Test func scannerReturnsFoldersContainingDotGitDirectory() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("demo/.git"), withIntermediateDirectories: true)

        let scanner = GitRepositoryScanner()
        let results = try scanner.scan(rootPaths: [root.path])

        #expect(results.map(\.path).contains(root.appendingPathComponent("demo").path))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme GitAccountBinder -destination 'platform=macOS' -only-testing:GitAccountBinderTests/GitRepositoryScannerTests`
Expected: FAIL because `GitRepositoryScanner` and `RepositoryRecord` behavior is not implemented yet.

- [ ] **Step 3: Implement scanner and repository record**

```swift
import Foundation

struct RepositoryRecord: Identifiable, Equatable {
    let id = UUID()
    let path: String
    let remoteURL: String?
}
```

```swift
import Foundation

struct GitRepositoryScanner {
    func scan(rootPaths: [String]) throws -> [RepositoryRecord] {
        let fileManager = FileManager.default
        var results: [RepositoryRecord] = []

        for rootPath in rootPaths {
            let enumerator = fileManager.enumerator(atPath: rootPath)
            while let entry = enumerator?.nextObject() as? String {
                guard entry.hasSuffix("/.git") || entry == ".git" else { continue }
                let repoPath = URL(fileURLWithPath: rootPath).appendingPathComponent(entry).deletingLastPathComponent().path
                results.append(RepositoryRecord(path: repoPath, remoteURL: nil))
                enumerator?.skipDescendants()
            }
        }

        return results.sorted { $0.path < $1.path }
    }
}
```

- [ ] **Step 4: Add Home view model binding actions**

```swift
import Foundation
import Observation

@Observable
final class HomeViewModel {
    private(set) var accounts: [Account] = []
    private(set) var repositories: [RepositoryRecord] = []
    private(set) var selectedAccountIDByRepositoryPath: [String: UUID] = [:]

    func bind(repositoryPath: String, accountID: UUID) {
        selectedAccountIDByRepositoryPath[repositoryPath] = accountID
    }
}
```

- [ ] **Step 5: Run focused tests**

Run: `xcodebuild test -scheme GitAccountBinder -destination 'platform=macOS' -only-testing:GitAccountBinderTests/GitRepositoryScannerTests -only-testing:GitAccountBinderTests/HomeViewModelTests`
Expected: PASS with repo detection and in-memory binding behavior green.

- [ ] **Step 6: Commit**

```bash
git add GitAccountBinder GitAccountBinderTests
git commit -m "feat: add repository scanning and home binding flow"
```

## Task 6: Implement Git Config Writing And Apply Preview

**Files:**
- Create: `GitAccountBinder/Infrastructure/Git/GitConfigWriter.swift`
- Create: `GitAccountBinder/Infrastructure/Config/ApplyPreviewService.swift`
- Create: `GitAccountBinder/Shared/Components/ApplyPreviewSheet.swift`
- Modify: `GitAccountBinder/Features/Home/HomeViewModel.swift`
- Test: `GitAccountBinderTests/Infrastructure/GitConfigWriterTests.swift`

- [ ] **Step 1: Write the failing config preview test**

```swift
import Testing
@testable import GitAccountBinder

struct GitConfigWriterTests {
    @Test func previewIncludesGlobalGeneratedConfigAndRepositoryOverrides() throws {
        let preview = try ApplyPreviewService().buildPreview(
            repositoryPaths: ["/Users/ctw/work/app-api"],
            workspaceRuleRoots: ["/Users/ctw/work"],
            hasGlobalDefault: true
        )

        #expect(preview.filePaths.contains("~/.gitconfig"))
        #expect(preview.filePaths.contains("/Users/ctw/work/app-api/.git/config"))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme GitAccountBinder -destination 'platform=macOS' -only-testing:GitAccountBinderTests/GitConfigWriterTests`
Expected: FAIL because preview and config writer types do not exist.

- [ ] **Step 3: Implement preview generation**

```swift
import Foundation

struct ApplyPreview {
    let filePaths: [String]
}

struct ApplyPreviewService {
    func buildPreview(repositoryPaths: [String], workspaceRuleRoots: [String], hasGlobalDefault: Bool) throws -> ApplyPreview {
        var filePaths = repositoryPaths.map { "\($0)/.git/config" }
        if hasGlobalDefault || !workspaceRuleRoots.isEmpty {
            filePaths.append("~/.gitconfig")
            filePaths.append("~/.ssh/config")
        }
        return ApplyPreview(filePaths: Array(Set(filePaths)).sorted())
    }
}
```

- [ ] **Step 4: Implement the Git config writer**

```swift
import Foundation

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
```

- [ ] **Step 5: Run tests to verify preview and writer formatting**

Run: `xcodebuild test -scheme GitAccountBinder -destination 'platform=macOS' -only-testing:GitAccountBinderTests/GitConfigWriterTests`
Expected: PASS with stable file preview output and deterministic config blocks.

- [ ] **Step 6: Commit**

```bash
git add GitAccountBinder GitAccountBinderTests
git commit -m "feat: add apply preview and git config writer"
```

## Task 7: Implement Snapshot Creation, Restore, And Verification

**Files:**
- Create: `GitAccountBinder/Infrastructure/Snapshots/SnapshotService.swift`
- Modify: `GitAccountBinder/Infrastructure/Repositories/SnapshotStore.swift`
- Modify: `GitAccountBinder/Features/History/HistoryViewModel.swift`
- Modify: `GitAccountBinder/Features/History/HistoryView.swift`
- Test: `GitAccountBinderTests/Infrastructure/SnapshotServiceTests.swift`

- [ ] **Step 1: Write the failing snapshot round-trip test**

```swift
import Testing
@testable import GitAccountBinder

struct SnapshotServiceTests {
    @Test func snapshotRoundTripRestoresOriginalFileContents() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let file = root.appendingPathComponent("gitconfig")
        try "before".write(to: file, atomically: true, encoding: .utf8)

        let service = SnapshotService(snapshotRoot: root.path)
        let snapshot = try service.createSnapshot(files: [file.path], summary: "test")

        try "after".write(to: file, atomically: true, encoding: .utf8)
        try service.restore(snapshot: snapshot)

        let restored = try String(contentsOf: file, encoding: .utf8)
        #expect(restored == "before")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme GitAccountBinder -destination 'platform=macOS' -only-testing:GitAccountBinderTests/SnapshotServiceTests`
Expected: FAIL because snapshot creation and restore are not implemented yet.

- [ ] **Step 3: Implement the snapshot service**

```swift
import Foundation

final class SnapshotService {
    private let snapshotRoot: String

    init(snapshotRoot: String) {
        self.snapshotRoot = snapshotRoot
    }

    func createSnapshot(files: [String], summary: String) throws -> ConfigSnapshot {
        let snapshotID = UUID()
        let storagePath = "\(snapshotRoot)/\(snapshotID.uuidString)"
        try FileManager.default.createDirectory(atPath: storagePath, withIntermediateDirectories: true)

        for file in files where FileManager.default.fileExists(atPath: file) {
            let target = URL(fileURLWithPath: storagePath).appending(path: file.replacingOccurrences(of: "/", with: "__"))
            try FileManager.default.copyItem(at: URL(fileURLWithPath: file), to: target)
        }

        return ConfigSnapshot(id: snapshotID, createdAt: .now, summary: summary, changedFiles: files, changedRepositories: [], storagePath: storagePath, restoreStatus: "ready")
    }

    func restore(snapshot: ConfigSnapshot) throws {
        for file in snapshot.changedFiles {
            let backup = URL(fileURLWithPath: snapshot.storagePath).appending(path: file.replacingOccurrences(of: "/", with: "__"))
            if FileManager.default.fileExists(atPath: backup.path) {
                try FileManager.default.removeItem(at: URL(fileURLWithPath: file))
                try FileManager.default.copyItem(at: backup, to: URL(fileURLWithPath: file))
            }
        }
    }
}
```

- [ ] **Step 4: Add verification behavior**

```swift
extension SnapshotService {
    func verifyRestore(snapshot: ConfigSnapshot) -> Bool {
        snapshot.changedFiles.allSatisfy { FileManager.default.fileExists(atPath: $0) }
    }
}
```

- [ ] **Step 5: Run snapshot tests to verify round-trip restore**

Run: `xcodebuild test -scheme GitAccountBinder -destination 'platform=macOS' -only-testing:GitAccountBinderTests/SnapshotServiceTests`
Expected: PASS with snapshot creation, restore, and verify behavior green.

- [ ] **Step 6: Commit**

```bash
git add GitAccountBinder GitAccountBinderTests
git commit -m "feat: add snapshot restore workflow"
```

## Task 8: Implement Diagnostics And Chinese End-To-End UX

**Files:**
- Create: `GitAccountBinder/Infrastructure/Diagnostics/DiagnosticsService.swift`
- Create: `GitAccountBinder/Features/Diagnostics/DiagnosticsViewModel.swift`
- Modify: `GitAccountBinder/Features/Diagnostics/DiagnosticsView.swift`
- Modify: `GitAccountBinder/App/AppStrings.swift`
- Test: `GitAccountBinderTests/Infrastructure/DiagnosticsServiceTests.swift`

- [ ] **Step 1: Write the failing diagnostics explanation test**

```swift
import Testing
@testable import GitAccountBinder

struct DiagnosticsServiceTests {
    @Test func diagnosticsExplainsRepositoryBindingInChinese() {
        let service = DiagnosticsService()
        let result = ResolutionResult(accountID: UUID(), reason: .repositoryBinding)

        let message = service.explanation(for: result)

        #expect(message == "该仓库使用显式绑定的账号。")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme GitAccountBinder -destination 'platform=macOS' -only-testing:GitAccountBinderTests/DiagnosticsServiceTests`
Expected: FAIL because diagnostics messaging is not implemented.

- [ ] **Step 3: Implement diagnostics explanation service**

```swift
import Foundation

struct DiagnosticsService {
    func explanation(for result: ResolutionResult) -> String {
        switch result.reason {
        case .repositoryBinding:
            return "该仓库使用显式绑定的账号。"
        case .workspaceRule:
            return "该仓库使用目录默认账号。"
        case .globalDefault:
            return "该仓库使用全局默认账号。"
        case .unresolved:
            return "该仓库当前还没有可用账号，请先绑定或设置默认值。"
        }
    }
}
```

- [ ] **Step 4: Wire the diagnostics UI and Chinese copy**

```swift
import Foundation

extension AppStrings {
    static let diagnosticsTitle = "诊断"
    static let historyTitle = "历史版本"
    static let workspaceDefaultsTitle = "目录默认"
}
```

- [ ] **Step 5: Run the diagnostics tests and a full app test pass**

Run: `xcodebuild test -scheme GitAccountBinder -destination 'platform=macOS'`
Expected: PASS for the full test suite with Chinese default copy still intact.

- [ ] **Step 6: Commit**

```bash
git add GitAccountBinder GitAccountBinderTests
git commit -m "feat: add diagnostics and chinese ux copy"
```

## Spec Coverage Check

- Account management: covered by Tasks 2, 4, and 5.
- Repository binding: covered by Tasks 3 and 5.
- Workspace defaults: covered by Tasks 3 and 6.
- Global default account: covered by Tasks 2, 3, and 6.
- Git/SSH native config writing: covered by Tasks 4 and 6.
- Snapshot and restore: covered by Task 7.
- Diagnostics: covered by Task 8.
- Default Simplified Chinese UI: covered by Tasks 1 and 8.

## Placeholder Scan

- No `TODO`, `TBD`, or placeholder markers should remain in this plan.
- Every code-writing step includes concrete file targets and concrete starter code.
- Every verification step includes an exact command and expected result.

## Type Consistency Check

- `Account`, `RepositoryBinding`, `WorkspaceRule`, `ConfigSnapshot`, and `ResolutionResult` are introduced before later tasks depend on them.
- `ResolutionService.resolve(...)` uses the same property names later referenced by diagnostics and apply-preview work.
- `SSHKeyService.generateKeyPair(accountID:keyName:)` and `SnapshotService.createSnapshot(files:summary:)` remain consistent across service and test steps.
