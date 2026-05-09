import Foundation

@MainActor
struct AppContainer {
    let router: AppRouter
    let homeViewModel: HomeViewModel
    let historyViewModel: HistoryViewModel
    let diagnosticsViewModel: DiagnosticsViewModel
    let workspaceDefaultsViewModel: WorkspaceDefaultsViewModel
    private let snapshotStore: SnapshotStore?

    static func bootstrap() -> AppContainer {
        let router = AppRouter()
        let appPaths = AppPathService.applicationSupportDefault
        let legacyPaths = AppPathService.legacyPercentEncodedApplicationSupportDefault
        let snapshotService = SnapshotService(snapshotRoot: appPaths.snapshotsDirectory)
        let persistence = makePersistence(appPaths: appPaths, legacyPaths: legacyPaths)
        let historyViewModel = HistoryViewModel(snapshotService: snapshotService)
        let diagnosticsViewModel = DiagnosticsViewModel()
        let workspaceDefaultsViewModel = WorkspaceDefaultsViewModel()
        let homeViewModel = makePersistentHomeViewModel(
            appPaths: appPaths,
            persistence: persistence,
            snapshotService: snapshotService
        )

        if let snapshotStore = persistence?.snapshotStore,
           let snapshots = try? snapshotStore.fetchAll() {
            historyViewModel.setSnapshots(snapshots)
        }

        if let firstRepository = homeViewModel.repositories.first {
            diagnosticsViewModel.update(
                repositoryPath: firstRepository.repositoryPath,
                result: ResolutionResult(
                    repositoryPath: firstRepository.repositoryPath,
                    accountID: firstRepository.currentAccountID,
                    reason: firstRepository.currentAccountID == nil ? .unresolved : .repositoryBinding
                )
            )
        }

        return AppContainer(
            router: router,
            homeViewModel: homeViewModel,
            historyViewModel: historyViewModel,
            diagnosticsViewModel: diagnosticsViewModel,
            workspaceDefaultsViewModel: workspaceDefaultsViewModel,
            snapshotStore: persistence?.snapshotStore
        )
    }

    func reloadSnapshots() {
        guard let snapshotStore else {
            return
        }

        do {
            historyViewModel.setSnapshots(try snapshotStore.fetchAll())
        } catch {
            historyViewModel.errorMessage = error.localizedDescription
        }
    }

    private static func makePersistentHomeViewModel(
        appPaths: AppPathService,
        persistence: Persistence?,
        snapshotService: SnapshotService
    ) -> HomeViewModel {
        guard let persistence else {
            let homeViewModel = HomeViewModel()
            homeViewModel.errorMessage = "无法初始化本地持久化。"
            return homeViewModel
        }

        let homeViewModel = HomeViewModel(
            sshKeyGenerator: SSHKeyService(
                paths: appPaths,
                runner: ShellCommandRunner()
            ),
            githubSSHTester: SSHKeyService(
                paths: appPaths,
                runner: ShellCommandRunner()
            ),
            gitConfigApplyService: GitConfigApplyService(
                runner: ShellCommandRunner(),
                snapshotService: snapshotService
            ),
            accountStore: persistence.accountStore,
            repositoryBindingStore: persistence.repositoryBindingStore,
            sshKeyGuidanceStore: persistence.sshKeyGuidanceStore,
            snapshotStore: persistence.snapshotStore
        )

        do {
            try homeViewModel.loadPersistedState()
            return homeViewModel
        } catch {
            homeViewModel.errorMessage = error.localizedDescription
            return homeViewModel
        }
    }

    private static func makePersistence(
        appPaths: AppPathService,
        legacyPaths: AppPathService
    ) -> Persistence? {
        do {
            try appPaths.migrateLegacyDirectoryIfNeeded(from: legacyPaths)
            try FileManager.default.createDirectory(
                atPath: appPaths.root,
                withIntermediateDirectories: true
            )

            let databaseURL = URL(fileURLWithPath: appPaths.root)
                .appendingPathComponent("State.sqlite")
            let databaseManager = try DatabaseManager(url: databaseURL)
            return Persistence(
                accountStore: AccountStore(databaseWriter: databaseManager.writer),
                repositoryBindingStore: RepositoryBindingStore(databaseWriter: databaseManager.writer),
                sshKeyGuidanceStore: SSHKeyGuidanceStore(databaseWriter: databaseManager.writer),
                snapshotStore: SnapshotStore(databaseWriter: databaseManager.writer)
            )
        } catch {
            return nil
        }
    }

    private struct Persistence {
        let accountStore: AccountStore
        let repositoryBindingStore: RepositoryBindingStore
        let sshKeyGuidanceStore: SSHKeyGuidanceStore
        let snapshotStore: SnapshotStore
    }
}
