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

    @Test
    func workspaceRuleWinsWhenNoRepositoryBindingExists() {
        let accountID = UUID()
        let service = ResolutionService()

        let result = service.resolve(
            repositoryPath: "/Users/ctw/work/tooling",
            repositoryBindings: [],
            workspaceRules: [
                WorkspaceRule(
                    id: UUID(),
                    workspaceRootPath: "/Users/ctw/work",
                    defaultAccountID: accountID
                )
            ],
            globalDefaultAccountID: nil
        )

        #expect(result.accountID == accountID)
        #expect(result.reason == .workspaceRule)
    }

    @Test
    func globalDefaultWinsWhenNoBindingOrWorkspaceRuleExists() {
        let accountID = UUID()
        let service = ResolutionService()

        let result = service.resolve(
            repositoryPath: "/Users/ctw/personal/blog",
            repositoryBindings: [],
            workspaceRules: [],
            globalDefaultAccountID: accountID
        )

        #expect(result.accountID == accountID)
        #expect(result.reason == .globalDefault)
    }

    @Test
    func unresolvedWhenNoRulesMatch() {
        let service = ResolutionService()

        let result = service.resolve(
            repositoryPath: "/Users/ctw/misc/scratch",
            repositoryBindings: [],
            workspaceRules: [],
            globalDefaultAccountID: nil
        )

        #expect(result.accountID == nil)
        #expect(result.reason == .unresolved)
    }
}
