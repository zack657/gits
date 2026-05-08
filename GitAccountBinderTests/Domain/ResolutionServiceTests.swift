import Foundation
import Testing
@testable import GitAccountBinder

private struct Account {
    enum PlatformType: String {
        case github
        case gitlab
        case gitee
        case custom
    }

    let id: UUID
    let displayName: String
    let gitUserName: String
    let gitUserEmail: String
    let platformType: PlatformType
    let sshKeyID: UUID?
    let signingKey: String?
    let isGlobalDefault: Bool

    init(
        id: UUID,
        displayName: String,
        gitUserName: String,
        gitUserEmail: String,
        platformType: PlatformType,
        sshKeyID: UUID?,
        signingKey: String?,
        isGlobalDefault: Bool
    ) {
        self.id = id
        self.displayName = displayName
        self.gitUserName = gitUserName
        self.gitUserEmail = gitUserEmail
        self.platformType = platformType
        self.sshKeyID = sshKeyID
        self.signingKey = signingKey
        self.isGlobalDefault = false
    }
}

struct ResolutionServiceTests {
    @Test
    func accountModelSupportsDefaultFlag() {
        let account = Account(
            id: UUID(),
            displayName: "个人账号",
            gitUserName: "ctw",
            gitUserEmail: "ctw@example.com",
            platformType: .github,
            sshKeyID: nil,
            signingKey: nil,
            isGlobalDefault: true
        )

        #expect(account.isGlobalDefault)
    }
}
