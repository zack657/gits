import Foundation
import Observation

@Observable
final class HomeViewModel {
    private(set) var accounts: [Account] = []
    private(set) var repositories: [RepositoryRecord] = []
    private(set) var selectedAccountIDByRepositoryPath: [String: UUID] = [:]
    private(set) var applyPreview: ApplyPreview?

    func setAccounts(_ accounts: [Account]) {
        self.accounts = accounts
    }

    func setRepositories(_ repositories: [RepositoryRecord]) {
        self.repositories = repositories
    }

    func bind(repositoryPath: String, accountID: UUID) {
        selectedAccountIDByRepositoryPath[repositoryPath] = accountID
    }

    func buildApplyPreview(
        workspaceRuleRoots: [String] = [],
        hasGlobalDefault: Bool = false,
        service: ApplyPreviewService = ApplyPreviewService()
    ) throws {
        applyPreview = try service.buildPreview(
            repositoryPaths: repositories.map(\.repositoryPath),
            workspaceRuleRoots: workspaceRuleRoots,
            hasGlobalDefault: hasGlobalDefault
        )
    }
}
