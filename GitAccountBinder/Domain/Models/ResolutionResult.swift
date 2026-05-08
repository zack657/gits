import Foundation

struct ResolutionResult: Codable, Equatable, Sendable {
    enum Reason: String, Codable, CaseIterable, Sendable {
        case repositoryBinding
        case workspaceRule
        case globalDefault
        case unresolved
    }

    var repositoryPath: String
    var accountID: UUID?
    var reason: Reason

    init(
        repositoryPath: String,
        accountID: UUID? = nil,
        reason: Reason
    ) {
        self.repositoryPath = repositoryPath
        self.accountID = accountID
        self.reason = reason
    }
}
