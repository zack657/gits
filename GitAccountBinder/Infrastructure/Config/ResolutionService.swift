import Foundation

struct ResolutionService {
    func resolve(
        repositoryPath: String,
        repositoryBindings: [RepositoryBinding],
        workspaceRules: [WorkspaceRule],
        globalDefaultAccountID: UUID?
    ) -> ResolutionResult {
        if let binding = repositoryBindings.first(where: { $0.repositoryPath == repositoryPath }) {
            return ResolutionResult(
                repositoryPath: repositoryPath,
                accountID: binding.accountID,
                reason: .repositoryBinding
            )
        }

        if let rule = workspaceRules
            .sorted(by: { $0.workspaceRootPath.count > $1.workspaceRootPath.count })
            .first(where: { repositoryPath.hasPrefix($0.workspaceRootPath) }),
           let accountID = rule.defaultAccountID {
            return ResolutionResult(
                repositoryPath: repositoryPath,
                accountID: accountID,
                reason: .workspaceRule
            )
        }

        if let globalDefaultAccountID {
            return ResolutionResult(
                repositoryPath: repositoryPath,
                accountID: globalDefaultAccountID,
                reason: .globalDefault
            )
        }

        return ResolutionResult(
            repositoryPath: repositoryPath,
            accountID: nil,
            reason: .unresolved
        )
    }
}
