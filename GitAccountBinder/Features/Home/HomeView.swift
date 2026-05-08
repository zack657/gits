import SwiftUI

struct HomeView: View {
    let container: AppContainer
    @State private var selection: AppRouter.SidebarDestination? = .accounts

    var body: some View {
        NavigationSplitView {
            sidebarNavigation
                .navigationSplitViewColumnWidth(min: 240, ideal: 280)
        } detail: {
            detailContent
        }
        .navigationTitle(AppStrings.homeTitle)
    }

    @ViewBuilder
    private var sidebarNavigation: some View {
        List(selection: $selection) {
            NavigationLink(AppStrings.accountsTitle, value: AppRouter.SidebarDestination.accounts)
            NavigationLink(AppStrings.repositoriesTitle, value: AppRouter.SidebarDestination.repositories)
            NavigationLink(AppStrings.workspaceDefaultsTitle, value: AppRouter.SidebarDestination.workspaceDefaults)
            NavigationLink(AppStrings.historyTitle, value: AppRouter.SidebarDestination.history)
            NavigationLink(AppStrings.diagnosticsTitle, value: AppRouter.SidebarDestination.diagnostics)
        }
        .navigationTitle(AppStrings.navigationTitle)
    }

    @ViewBuilder
    private var detailContent: some View {
        switch selection ?? container.router.defaultSidebarSelection {
        case .accounts:
            AccountListView(accounts: container.homeViewModel.accounts)
        case .repositories:
            RepositoryListView(repositories: container.homeViewModel.repositories)
        case .workspaceDefaults:
            WorkspaceDefaultsView(viewModel: container.workspaceDefaultsViewModel)
        case .history:
            HistoryView(viewModel: container.historyViewModel)
        case .diagnostics:
            DiagnosticsView(viewModel: container.diagnosticsViewModel)
        }
    }
}
