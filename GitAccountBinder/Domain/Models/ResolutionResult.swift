import Foundation

struct ResolutionResult: Codable, Equatable, Sendable {
    enum Source: String, Codable, CaseIterable, Sendable {
        case repositoryBinding
        case workspaceRule
        case globalDefault
        case unresolved
    }

    var repositoryPath: String
    var resolvedAccountID: UUID?
    var matchedRuleID: UUID?
    var matchedBindingID: UUID?
    var source: Source
    var diagnostics: [String]

    init(
        repositoryPath: String,
        resolvedAccountID: UUID? = nil,
        matchedRuleID: UUID? = nil,
        matchedBindingID: UUID? = nil,
        source: Source,
        diagnostics: [String] = []
    ) {
        self.repositoryPath = repositoryPath
        self.resolvedAccountID = resolvedAccountID
        self.matchedRuleID = matchedRuleID
        self.matchedBindingID = matchedBindingID
        self.source = source
        self.diagnostics = diagnostics
    }
}
