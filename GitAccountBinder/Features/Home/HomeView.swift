import SwiftUI

struct HomeView: View {
    let container: AppContainer

    var body: some View {
        NavigationSplitView {
            sidebarContent
                .navigationSplitViewColumnWidth(min: 240, ideal: 280)
        } detail: {
            EmptyStateView(
                title: AppStrings.repositoriesTitle,
                message: "还没有仓库"
            )
        }
        .navigationTitle(AppStrings.homeTitle)
    }

    @ViewBuilder
    private var sidebarContent: some View {
        switch container.router.defaultSidebarSelection {
        case .accounts:
            EmptyStateView(
                title: AppStrings.accountsTitle,
                message: "还没有账号"
            )
        case .repositories:
            EmptyStateView(
                title: AppStrings.repositoriesTitle,
                message: "还没有仓库"
            )
        }
    }
}
