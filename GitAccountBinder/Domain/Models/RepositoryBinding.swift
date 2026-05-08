import Foundation

struct RepositoryBinding: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var repositoryPath: String
    var accountID: UUID
    var remoteURL: String?
    var branchPattern: String?
    var priority: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        repositoryPath: String,
        accountID: UUID,
        remoteURL: String? = nil,
        branchPattern: String? = nil,
        priority: Int = 0,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.repositoryPath = repositoryPath
        self.accountID = accountID
        self.remoteURL = remoteURL
        self.branchPattern = branchPattern
        self.priority = priority
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
