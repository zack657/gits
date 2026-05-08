import Foundation

struct WorkspaceRule: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var workspaceRootPath: String
    var defaultAccountID: UUID?
    var includePatterns: [String]
    var excludePatterns: [String]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        workspaceRootPath: String,
        defaultAccountID: UUID? = nil,
        includePatterns: [String] = [],
        excludePatterns: [String] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.workspaceRootPath = workspaceRootPath
        self.defaultAccountID = defaultAccountID
        self.includePatterns = includePatterns
        self.excludePatterns = excludePatterns
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
