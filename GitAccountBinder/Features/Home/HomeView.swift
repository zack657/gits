import SwiftUI

struct HomeView: View {
    let container: AppContainer

    @State private var selection: AppRouter.SidebarDestination?

    init(container: AppContainer) {
        self.container = container
        _selection = State(initialValue: container.router.defaultSidebarSelection)
    }

    var body: some View {
        NavigationSplitView {
            EmptyStateView(
                title: AppStrings.accountsTitle,
                message: "还没有账号"
            )
            .navigationSplitViewColumnWidth(min: 240, ideal: 280)
        } detail: {
            EmptyStateView(
                title: AppStrings.repositoriesTitle,
                message: "还没有仓库"
            )
        }
        .navigationTitle(AppStrings.homeTitle)
    }
}
