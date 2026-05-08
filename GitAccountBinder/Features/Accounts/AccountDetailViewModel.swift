import Foundation
import Observation

@Observable
final class AccountDetailViewModel {
    let account: Account
    let publicKeyPath: String?

    init(account: Account, publicKeyPath: String? = nil) {
        self.account = account
        self.publicKeyPath = publicKeyPath
    }
}
