import Foundation

struct Account: Identifiable, Codable, Equatable, Sendable {
    enum PlatformType: String, Codable, CaseIterable, Sendable {
        case github
        case gitlab
        case gitee
        case custom
    }

    let id: UUID
    var displayName: String
    var gitUserName: String
    var gitUserEmail: String
    var platformType: PlatformType
    var sshKeyID: UUID?
    var signingKey: String?
    var isGlobalDefault: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        displayName: String,
        gitUserName: String,
        gitUserEmail: String,
        platformType: PlatformType,
        sshKeyID: UUID?,
        signingKey: String?,
        isGlobalDefault: Bool,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.displayName = displayName
        self.gitUserName = gitUserName
        self.gitUserEmail = gitUserEmail
        self.platformType = platformType
        self.sshKeyID = sshKeyID
        self.signingKey = signingKey
        self.isGlobalDefault = isGlobalDefault
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
