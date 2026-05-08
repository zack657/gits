import SwiftUI

struct AccountListView: View {
    let accounts: [Account]

    var body: some View {
        if accounts.isEmpty {
            EmptyStateView(title: AppStrings.accountsTitle, message: "还没有账号")
        } else {
            List(accounts) { account in
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.displayName)
                    Text(account.gitUserEmail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
