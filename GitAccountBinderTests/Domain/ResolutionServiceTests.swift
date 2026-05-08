import Foundation
import Testing
@testable import GitAccountBinder

struct ResolutionServiceTests {
    @Test
    func repositoryBindingWinsOverWorkspaceAndGlobalDefault() {
        let workID = UUID()
        let personalID = UUID()
        let service = ResolutionService()

        let result = service.resolve(
            repositoryPath: "/Users/ctw/work/app-api",
            repositoryBindings: [
                RepositoryBinding(
                    id: UUID(),
                    repositoryPath: "/Users/ctw/work/app-api",
                    accountID: workID
                )
            ],
            workspaceRules: [
                WorkspaceRule(
                    id: UUID(),
                    workspaceRootPath: "/Users/ctw/work",
                    defaultAccountID: personalID
                )
            ],
            globalDefaultAccountID: personalID
        )

        #expect(result.accountID == workID)
        #expect(result.reason == .repositoryBinding)
    }
}
