import Foundation
import Observation

@Observable
final class HomeViewModel {
    private(set) var accounts: [Account] = []
    private(set) var repositories: [RepositoryRecord] = []
    private(set) var selectedAccountIDByRepositoryPath: [String: UUID] = [:]

    func setAccounts(_ accounts: [Account]) {
        self.accounts = accounts
    }

    func setRepositories(_ repositories: [RepositoryRecord]) {
        self.repositories = repositories
    }

    func bind(repositoryPath: String, accountID: UUID) {
        selectedAccountIDByRepositoryPath[repositoryPath] = accountID
    }
}
