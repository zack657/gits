import Foundation
import Testing
@testable import GitAccountBinder

struct AccountModelTests {
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
