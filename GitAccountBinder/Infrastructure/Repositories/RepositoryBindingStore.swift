import Foundation
import GRDB

struct RepositoryBindingStore {
    private let databaseWriter: any DatabaseWriter

    init(databaseWriter: any DatabaseWriter) {
        self.databaseWriter = databaseWriter
    }

    func save(_ binding: RepositoryBinding) throws {
        try databaseWriter.write { db in
            try db.execute(
                sql: """
                INSERT INTO repository_bindings (
                    id,
                    repository_path,
                    account_id,
                    remote_url,
                    branch_pattern,
                    priority,
                    created_at,
                    updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    repository_path = excluded.repository_path,
                    account_id = excluded.account_id,
                    remote_url = excluded.remote_url,
                    branch_pattern = excluded.branch_pattern,
                    priority = excluded.priority,
                    created_at = excluded.created_at,
                    updated_at = excluded.updated_at
                """,
                arguments: [
                    binding.id.uuidString,
                    binding.repositoryPath,
                    binding.accountID.uuidString,
                    binding.remoteURL,
                    binding.branchPattern,
                    binding.priority,
                    binding.createdAt,
                    binding.updatedAt
                ]
            )
        }
    }

    func fetchAll() throws -> [RepositoryBinding] {
        try databaseWriter.read { db in
            let rows = try Row.fetchAll(
                db,
                sql: """
                SELECT
                    id,
                    repository_path,
                    account_id,
                    remote_url,
                    branch_pattern,
                    priority,
                    created_at,
                    updated_at
                FROM repository_bindings
                ORDER BY repository_path COLLATE NOCASE
                """
            )

            return try rows.map(Self.makeBinding)
        }
    }

    private static func makeBinding(from row: Row) throws -> RepositoryBinding {
        guard
            let id = UUID(uuidString: row["id"]),
            let accountID = UUID(uuidString: row["account_id"])
        else {
            throw DatabaseError(message: "Failed to decode repository binding row")
        }

        return RepositoryBinding(
            id: id,
            repositoryPath: row["repository_path"],
            accountID: accountID,
            remoteURL: row["remote_url"],
            branchPattern: row["branch_pattern"],
            priority: row["priority"],
            createdAt: row["created_at"],
            updatedAt: row["updated_at"]
        )
    }
}
