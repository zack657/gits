import SwiftUI

struct HistoryView: View {
    let viewModel: HistoryViewModel

    var body: some View {
        if viewModel.snapshots.isEmpty {
            EmptyStateView(title: "历史版本", message: "还没有快照")
        } else {
            List(viewModel.snapshots) { snapshot in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(snapshot.note ?? "未命名快照")
                        Text(snapshot.createdAt.formatted())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("恢复到此版本") {
                        viewModel.restore(snapshot: snapshot)
                    }
                }
            }
            .alert(
                "历史版本",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { isPresented in
                        if !isPresented {
                            viewModel.errorMessage = nil
                        }
                    }
                )
            ) {
                Button("好") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}
