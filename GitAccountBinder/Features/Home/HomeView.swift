import SwiftUI

struct HomeView: View {
    let container: AppContainer

    var body: some View {
        NavigationSplitView {
            sidebarContent
                .navigationSplitViewColumnWidth(min: 240, ideal: 280)
        } detail: {
            RepositoryListView(repositories: container.homeViewModel.repositories)
        }
        .navigationTitle(AppStrings.homeTitle)
    }

    @ViewBuilder
    private var sidebarContent: some View {
        switch container.router.defaultSidebarSelection {
        case .accounts:
            AccountListView(accounts: container.homeViewModel.accounts)
        case .repositories:
            RepositoryListView(repositories: container.homeViewModel.repositories)
        }
    }
}
