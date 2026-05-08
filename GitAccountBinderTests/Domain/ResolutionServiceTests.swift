import Foundation
import Testing
@testable import GitAccountBinder

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

    @Test
    func accountStoreRoundTripsDefaultFlag() throws {
        let databaseManager = try DatabaseManager.inMemory()
        let store = AccountStore(databaseWriter: databaseManager.writer)
        let account = Account(
            id: UUID(),
            displayName: "工作账号",
            gitUserName: "worker",
            gitUserEmail: "worker@example.com",
            platformType: .gitlab,
            sshKeyID: UUID(),
            signingKey: "ABC123",
            isGlobalDefault: true
        )

        try store.save(account)
        let accounts = try store.fetchAll()

        #expect(accounts.count == 1)
        #expect(accounts.first?.isGlobalDefault == true)
        #expect(accounts.first?.platformType == .gitlab)
    }
}
