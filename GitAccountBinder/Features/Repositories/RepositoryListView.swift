import SwiftUI

struct RepositoryListView: View {
    let repositories: [RepositoryRecord]

    var body: some View {
        if repositories.isEmpty {
            EmptyStateView(title: AppStrings.repositoriesTitle, message: "还没有仓库")
        } else {
            List(repositories) { repository in
                VStack(alignment: .leading, spacing: 4) {
                    Text(repository.repositoryName)
                    Text(repository.repositoryPath)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
