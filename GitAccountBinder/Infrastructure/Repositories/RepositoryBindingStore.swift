import Foundation
import GRDB

struct RepositoryBindingStore {
    private let databaseWriter: any DatabaseWriter

    init(databaseWriter: any DatabaseWriter) {
        self.databaseWriter = databaseWriter
    }

    func save(_ binding: RepositoryBinding) throws {
        let normalizedRepositoryPath = PersistencePathNormalizer.normalizedStoredPath(binding.repositoryPath)
        let repositoryPathKey = PersistencePathNormalizer.logicalLookupKey(for: normalizedRepositoryPath)

        try databaseWriter.write { db in
            let existingIDMatch = try String.fetchOne(
                db,
                sql: "SELECT id FROM repository_bindings WHERE id = ?",
                arguments: [binding.id.uuidString]
            )
            let existingRepositoryPathMatches = try Row.fetchAll(
                db,
                sql: "SELECT id, repository_path FROM repository_bindings"
            )
            .filter { row in
                let existingPath: String = row["repository_path"]
                return PersistencePathNormalizer.logicalLookupKey(for: existingPath) == repositoryPathKey
            }
            .compactMap { row -> String? in
                row["id"]
            }

            let distinctRepositoryPathMatches = Array(Set(existingRepositoryPathMatches))

            if distinctRepositoryPathMatches.count > 1 {
                throw DatabaseError(
                    message: "Ambiguous repository binding save conflict for repository path \(normalizedRepositoryPath): multiple logical path matches exist"
                )
            }

            let existingRepositoryPathMatch = distinctRepositoryPathMatches.first

            if let existingIDMatch, let existingRepositoryPathMatch, existingIDMatch != existingRepositoryPathMatch {
                throw DatabaseError(
                    message: "Ambiguous repository binding save conflict for id \(binding.id.uuidString) and repository path \(normalizedRepositoryPath)"
                )
            }

            let existingID = existingIDMatch ?? existingRepositoryPathMatch

            if let existingID {
                try db.execute(
                    sql: """
                    UPDATE repository_bindings
                    SET repository_path = ?,
                        account_id = ?,
                        remote_url = ?,
                        branch_pattern = ?,
                        priority = ?,
                        updated_at = ?
                    WHERE id = ?
                    """,
                    arguments: [
                        normalizedRepositoryPath,
                        binding.accountID.uuidString,
                        binding.remoteURL,
                        binding.branchPattern,
                        binding.priority,
                        binding.updatedAt,
                        existingID
                    ]
                )
            } else {
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
                    """,
                    arguments: [
                        binding.id.uuidString,
                        normalizedRepositoryPath,
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

    func delete(repositoryPath: String) throws {
        let normalizedRepositoryPath = PersistencePathNormalizer.normalizedStoredPath(repositoryPath)
        let repositoryPathKey = PersistencePathNormalizer.logicalLookupKey(for: normalizedRepositoryPath)

        try databaseWriter.write { db in
            let rows = try Row.fetchAll(
                db,
                sql: "SELECT id, repository_path FROM repository_bindings"
            )
            let matchingIDs = rows.compactMap { row -> String? in
                let existingPath: String = row["repository_path"]
                return PersistencePathNormalizer.logicalLookupKey(for: existingPath) == repositoryPathKey
                    ? row["id"]
                    : nil
            }

            for id in matchingIDs {
                try db.execute(
                    sql: "DELETE FROM repository_bindings WHERE id = ?",
                    arguments: [id]
                )
            }
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
