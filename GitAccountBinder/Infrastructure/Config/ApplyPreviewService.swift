import Foundation

struct ApplyPreview: Equatable, Sendable {
    let filePaths: [String]
}

struct ApplyPreviewService {
    func buildPreview(
        repositoryPaths: [String],
        workspaceRuleRoots: [String],
        hasGlobalDefault: Bool
    ) throws -> ApplyPreview {
        var filePaths = repositoryPaths.map { "\($0)/.git/config" }

        if hasGlobalDefault || !workspaceRuleRoots.isEmpty {
            filePaths.append("~/.gitconfig")
            filePaths.append("~/.ssh/config")
        }

        return ApplyPreview(filePaths: Array(Set(filePaths)).sorted())
    }
}
