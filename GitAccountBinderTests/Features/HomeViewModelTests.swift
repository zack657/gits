import Foundation
import Testing
@testable import GitAccountBinder

struct HomeViewModelTests {
    @Test
    func bindStoresSelectedAccountForRepositoryPath() {
        let viewModel = HomeViewModel()
        let accountID = UUID()

        viewModel.bind(repositoryPath: "/tmp/repo-a", accountID: accountID)

        #expect(viewModel.selectedAccountIDByRepositoryPath["/tmp/repo-a"] == accountID)
    }
}
