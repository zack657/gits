import Foundation

@MainActor
struct AppContainer {
    let router: AppRouter
    let homeViewModel: HomeViewModel
    let historyViewModel: HistoryViewModel
    let diagnosticsViewModel: DiagnosticsViewModel
    let workspaceDefaultsViewModel: WorkspaceDefaultsViewModel

    static func bootstrap() -> AppContainer {
        AppContainer(
            router: AppRouter(),
            homeViewModel: HomeViewModel(),
            historyViewModel: HistoryViewModel(),
            diagnosticsViewModel: DiagnosticsViewModel(),
            workspaceDefaultsViewModel: WorkspaceDefaultsViewModel()
        )
    }
}
