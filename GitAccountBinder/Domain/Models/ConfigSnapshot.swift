import Foundation

struct ConfigSnapshot: Identifiable, Codable, Equatable, Sendable {
    enum Scope: String, Codable, CaseIterable, Sendable {
        case global
        case repository
        case workspace
    }

    let id: UUID
    var scope: Scope
    var targetPath: String
    var gitConfigContent: String
    var sshConfigContent: String
    var knownHostsContent: String?
    var note: String?
    var createdAt: Date

    init(
        id: UUID,
        scope: Scope,
        targetPath: String,
        gitConfigContent: String,
        sshConfigContent: String,
        knownHostsContent: String? = nil,
        note: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.scope = scope
        self.targetPath = targetPath
        self.gitConfigContent = gitConfigContent
        self.sshConfigContent = sshConfigContent
        self.knownHostsContent = knownHostsContent
        self.note = note
        self.createdAt = createdAt
    }
}
