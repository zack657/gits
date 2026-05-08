import SwiftUI

struct AccountDetailView: View {
    let viewModel: AccountDetailViewModel

    var body: some View {
        Form {
            LabeledContent("名称", value: viewModel.account.displayName)
            LabeledContent("Git Name", value: viewModel.account.gitUserName)
            LabeledContent("Git Email", value: viewModel.account.gitUserEmail)
            LabeledContent("Public Key", value: viewModel.publicKeyPath ?? "未生成")
        }
        .navigationTitle("账号详情")
    }
}
