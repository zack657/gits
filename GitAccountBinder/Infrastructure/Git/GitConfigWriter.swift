import Foundation

struct GitConfigWriter {
    func generatedIncludeBlock(configPath: String) -> String {
        """
        [include]
            path = \(configPath)
        """
    }

    func repositoryOverrideBlock(account: Account) -> String {
        """
        [user]
            name = \(account.gitUserName)
            email = \(account.gitUserEmail)
        """
    }
}
