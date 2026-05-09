import AppKit
import SwiftUI

struct HomeView: View {
    let container: AppContainer
    @State private var selection: AppRouter.SidebarDestination? = .workbench

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
            NavigationLink(AppStrings.workbenchTitle, value: AppRouter.SidebarDestination.workbench)
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
        case .workbench:
            AccountRepositoryWorkbenchView(
                viewModel: container.homeViewModel,
                onApplied: container.reloadSnapshots
            )
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

struct AccountRepositoryWorkbenchView: View {
    let viewModel: HomeViewModel
    let onApplied: () -> Void
    @State private var isShowingApplyPreview = false
    @State private var isShowingAddAccount = false
    @State private var draftDisplayName = ""
    @State private var draftGitUserName = ""
    @State private var draftGitUserEmail = ""
    @State private var isShowingAddRepository = false
    @State private var draftRepositoryPath = ""
    @State private var draftRepositoryAccountID: UUID?

    var body: some View {
        ZStack {
            HSplitView {
                accountsPane
                    .frame(minWidth: 240, idealWidth: 300, maxWidth: 360)

                repositoriesPane
                    .frame(minWidth: 520)
            }

            if isShowingApplyPreview, let preview = viewModel.applyPreview {
                ApplyPreviewOverlay(preview: preview) {
                    isShowingApplyPreview = false
                }
            }
        }
        .navigationTitle(AppStrings.homeTitle)
        .sheet(isPresented: $isShowingAddAccount) {
            AddAccountSheet(
                displayName: $draftDisplayName,
                gitUserName: $draftGitUserName,
                gitUserEmail: $draftGitUserEmail,
                onCancel: {
                    clearAccountDraft()
                    isShowingAddAccount = false
                },
                onSave: {
                    do {
                        _ = try viewModel.addAccount(
                            displayName: draftDisplayName,
                            gitUserName: draftGitUserName,
                            gitUserEmail: draftGitUserEmail
                        )
                        clearAccountDraft()
                        isShowingAddAccount = false
                    } catch {
                        viewModel.errorMessage = error.localizedDescription
                    }
                }
            )
            .frame(minWidth: 420)
        }
        .sheet(isPresented: $isShowingAddRepository) {
            AddRepositorySheet(
                repositoryPath: $draftRepositoryPath,
                accountID: Binding(
                    get: {
                        draftRepositoryAccountID
                            ?? viewModel.accounts.first?.id
                            ?? UUID()
                    },
                    set: { draftRepositoryAccountID = $0 }
                ),
                accounts: viewModel.accounts,
                onCancel: {
                    clearRepositoryDraft()
                    isShowingAddRepository = false
                },
                onSave: {
                    guard let accountID = draftRepositoryAccountID ?? viewModel.accounts.first?.id else {
                        viewModel.errorMessage = "请先新增 Git 账号。"
                        return
                    }

                    do {
                        try viewModel.addRepository(
                            path: draftRepositoryPath,
                            accountID: accountID
                        )
                        clearRepositoryDraft()
                        isShowingAddRepository = false
                    } catch {
                        viewModel.errorMessage = error.localizedDescription
                    }
                }
            )
            .frame(minWidth: 500)
        }
        .alert(
            "操作失败",
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

    private var accountsPane: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(AppStrings.accountsTitle)
                    .font(.title3.bold())

                Spacer()

                Button {
                    isShowingAddAccount = true
                } label: {
                    Label("新增账号", systemImage: "plus")
                }
                .labelStyle(.iconOnly)
                .help("新增账号")
            }

            List(viewModel.accounts) { account in
                AccountWorkbenchRow(
                    account: account,
                    guidance: viewModel.sshKeyGuidanceByAccountID[account.id],
                    canDelete: viewModel.accounts.count > 1,
                    onConfirmGitHubKeyAdded: {
                        viewModel.confirmGitHubKeyAdded(accountID: account.id)
                    },
                    onDelete: {
                        viewModel.deleteAccount(id: account.id)
                    }
                )
            }
        }
        .padding(20)
    }

    private var repositoriesPane: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(AppStrings.repositoriesTitle)
                    .font(.title3.bold())

                Spacer()

                Button {
                    draftRepositoryAccountID = viewModel.accounts.first?.id
                    isShowingAddRepository = true
                } label: {
                    Label("新增仓库", systemImage: "folder.badge.plus")
                }
                .disabled(viewModel.accounts.isEmpty)

                Button {
                    try? viewModel.buildApplyPreview(
                        hasGlobalDefault: viewModel.accounts.contains { $0.isGlobalDefault }
                    )
                    isShowingApplyPreview = viewModel.applyPreview != nil
                } label: {
                    Label("预览更改", systemImage: "doc.text.magnifyingglass")
                }
                .disabled(viewModel.repositories.isEmpty)

                Button {
                    do {
                        _ = try viewModel.applyRepositoryBindings()
                        onApplied()
                    } catch {
                        viewModel.errorMessage = error.localizedDescription
                    }
                } label: {
                    Label("应用配置", systemImage: "checkmark.seal")
                }
                .disabled(viewModel.repositories.isEmpty)
            }

            if let lastApplyResultText = viewModel.lastApplyResultText {
                Text(lastApplyResultText)
                    .font(.caption)
                    .foregroundStyle(.green)
            }

            List(viewModel.repositories) { repository in
                RepositoryBindingRow(
                    repository: repository,
                    accounts: viewModel.accounts,
                    currentAccountName: viewModel.bindingAccountDisplayName(
                        forRepositoryPath: repository.repositoryPath
                    ),
                    onDelete: {
                        viewModel.deleteRepository(path: repository.repositoryPath)
                    },
                    selection: Binding(
                        get: {
                            viewModel.bindingAccountID(forRepositoryPath: repository.repositoryPath)
                                ?? viewModel.accounts.first?.id
                                ?? UUID()
                        },
                        set: { accountID in
                            viewModel.bind(
                                repositoryPath: repository.repositoryPath,
                                accountID: accountID
                            )
                        }
                    )
                )
            }
        }
        .padding(20)
    }

    private func clearAccountDraft() {
        draftDisplayName = ""
        draftGitUserName = ""
        draftGitUserEmail = ""
    }

    private func clearRepositoryDraft() {
        draftRepositoryPath = ""
        draftRepositoryAccountID = nil
    }
}

private struct AccountWorkbenchRow: View {
    let account: Account
    let guidance: SSHKeyGuidance?
    let canDelete: Bool
    let onConfirmGitHubKeyAdded: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "person.crop.circle")
                        .foregroundStyle(.secondary)
                    Text(account.displayName)
                        .font(.headline)
                    if account.isGlobalDefault {
                        Text("默认")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(account.gitUserEmail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let guidance {
                    Text(guidance.statusText)
                        .font(.caption)
                        .foregroundStyle(guidance.isReady ? .green : .orange)

                    if !guidance.isReady {
                        Text(guidance.deployKeyWarning)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    HStack(spacing: 8) {
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(
                                guidance.publicKey,
                                forType: .string
                            )
                        } label: {
                            Label("复制 Public Key", systemImage: "doc.on.doc")
                        }

                        Button {
                            NSWorkspace.shared.open(guidance.githubSSHKeysURL)
                        } label: {
                            Label("打开 GitHub", systemImage: "arrow.up.right.square")
                        }

                        Button(action: onConfirmGitHubKeyAdded) {
                            Label("我已添加", systemImage: "checkmark.circle")
                        }
                        .disabled(guidance.isReady)
                    }
                    .font(.caption)
                }
            }

            Spacer()

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .disabled(!canDelete)
            .help(canDelete ? "删除账号" : "至少保留一个账号")
        }
        .padding(.vertical, 4)
    }
}

private struct RepositoryBindingRow: View {
    let repository: RepositoryRecord
    let accounts: [Account]
    let currentAccountName: String
    let onDelete: () -> Void
    @Binding var selection: UUID

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(repository.repositoryName)
                    .font(.headline)
                Text(repository.repositoryPath)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text("当前绑定：\(currentAccountName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 16)

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help("从管理列表移除，不删除本地代码")

            Picker("账号", selection: $selection) {
                ForEach(accounts) { account in
                    Text(account.displayName).tag(account.id)
                }
            }
            .labelsHidden()
            .frame(width: 180)
        }
        .padding(.vertical, 6)
    }
}

private struct AddRepositorySheet: View {
    @Binding var repositoryPath: String
    @Binding var accountID: UUID
    let accounts: [Account]
    let onCancel: () -> Void
    let onSave: () -> Void

    private var canSave: Bool {
        !repositoryPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && accounts.contains { $0.id == accountID }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("新增仓库")
                .font(.title3.bold())

            Form {
                HStack {
                    TextField("本地仓库路径", text: $repositoryPath)
                    Button("选择...") {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        panel.allowsMultipleSelection = false

                        if panel.runModal() == .OK, let url = panel.url {
                            repositoryPath = url.path()
                        }
                    }
                }
                Picker("绑定账号", selection: $accountID) {
                    ForEach(accounts) { account in
                        Text(account.displayName).tag(account.id)
                    }
                }
            }
            .formStyle(.grouped)

            Text("删除仓库只会移出本应用的管理列表，不会删除本地代码。")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Spacer()
                Button("取消", action: onCancel)
                Button("保存", action: onSave)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canSave)
            }
        }
        .padding(24)
    }
}

private struct AddAccountSheet: View {
    @Binding var displayName: String
    @Binding var gitUserName: String
    @Binding var gitUserEmail: String
    let onCancel: () -> Void
    let onSave: () -> Void

    private var canSave: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !gitUserName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !gitUserEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("新增 Git 账号")
                .font(.title3.bold())

            Form {
                TextField("账号名称", text: $displayName)
                TextField("Git 用户名", text: $gitUserName)
                TextField("Git 邮箱", text: $gitUserEmail)
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("取消", action: onCancel)
                Button("保存", action: onSave)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canSave)
            }
        }
        .padding(24)
    }
}

private struct ApplyPreviewOverlay: View {
    let preview: ApplyPreview
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            ApplyPreviewSheet(preview: preview)
                .frame(width: 620, height: 400)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 20)
        }
    }
}
