import Foundation
import GRDB

struct DatabaseManager {
    let writer: DatabaseQueue

    init(path: String) throws {
        let configuration = DatabaseManager.makeConfiguration()
        writer = try DatabaseQueue(path: path, configuration: configuration)
        try Migrations.migrator.migrate(writer)
    }

    init(url: URL) throws {
        try self.init(path: url.path(percentEncoded: false))
    }

    static func inMemory() throws -> DatabaseManager {
        try DatabaseManager(path: ":memory:")
    }

    private static func makeConfiguration() -> Configuration {
        var configuration = Configuration()
        configuration.foreignKeysEnabled = true
        configuration.label = "GitAccountBinder.Database"
        return configuration
    }
}
