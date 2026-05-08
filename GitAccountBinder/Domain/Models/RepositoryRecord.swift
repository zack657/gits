import Foundation

struct RepositoryRecord: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var repositoryPath: String
    var repositoryName: String
    var originURL: String?
    var currentAccountID: UUID?
    var workspaceRootPath: String?
    var lastScannedAt: Date?
    var isActive: Bool

    init(
        id: UUID,
        repositoryPath: String,
        repositoryName: String,
        originURL: String? = nil,
        currentAccountID: UUID? = nil,
        workspaceRootPath: String? = nil,
        lastScannedAt: Date? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.repositoryPath = repositoryPath
        self.repositoryName = repositoryName
        self.originURL = originURL
        self.currentAccountID = currentAccountID
        self.workspaceRootPath = workspaceRootPath
        self.lastScannedAt = lastScannedAt
        self.isActive = isActive
    }

    var path: String {
        repositoryPath
    }
}
