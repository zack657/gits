import SwiftUI

struct WorkspaceDefaultsView: View {
    let viewModel: WorkspaceDefaultsViewModel

    var body: some View {
        if viewModel.rules.isEmpty {
            EmptyStateView(title: AppStrings.workspaceDefaultsTitle, message: "还没有目录默认规则")
        } else {
            List(viewModel.rules) { rule in
                VStack(alignment: .leading, spacing: 4) {
                    Text(rule.workspaceRootPath)
                    Text(rule.includePatterns.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
