import SwiftUI

struct DiagnosticsView: View {
    let viewModel: DiagnosticsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppStrings.diagnosticsTitle)
                .font(.title3.bold())

            if !viewModel.repositoryPath.isEmpty {
                Text(viewModel.repositoryPath)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }

            Text(viewModel.explanation)
                .font(.body)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
    }
}
