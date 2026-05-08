import Foundation
import GRDB

struct WorkspaceRuleStore {
    private let databaseWriter: any DatabaseWriter
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(databaseWriter: any DatabaseWriter) {
        self.databaseWriter = databaseWriter
    }

    func save(_ rule: WorkspaceRule) throws {
        let includePatternsData = try encoder.encode(rule.includePatterns)
        let excludePatternsData = try encoder.encode(rule.excludePatterns)
        guard
            let includePatterns = String(data: includePatternsData, encoding: .utf8),
            let excludePatterns = String(data: excludePatternsData, encoding: .utf8)
        else {
            throw DatabaseError(message: "Failed to encode workspace rule patterns")
        }

        try databaseWriter.write { db in
            try db.execute(
                sql: """
                INSERT INTO workspace_rules (
                    id,
                    workspace_root_path,
                    default_account_id,
                    include_patterns,
                    exclude_patterns,
                    created_at,
                    updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    workspace_root_path = excluded.workspace_root_path,
                    default_account_id = excluded.default_account_id,
                    include_patterns = excluded.include_patterns,
                    exclude_patterns = excluded.exclude_patterns,
                    created_at = excluded.created_at,
                    updated_at = excluded.updated_at
                """,
                arguments: [
                    rule.id.uuidString,
                    rule.workspaceRootPath,
                    rule.defaultAccountID?.uuidString,
                    includePatterns,
                    excludePatterns,
                    rule.createdAt,
                    rule.updatedAt
                ]
            )
        }
    }

    func fetchAll() throws -> [WorkspaceRule] {
        try databaseWriter.read { db in
            let rows = try Row.fetchAll(
                db,
                sql: """
                SELECT
                    id,
                    workspace_root_path,
                    default_account_id,
                    include_patterns,
                    exclude_patterns,
                    created_at,
                    updated_at
                FROM workspace_rules
                ORDER BY workspace_root_path COLLATE NOCASE
                """
            )

            return try rows.map { row in
                try Self.makeRule(decoder: decoder, from: row)
            }
        }
    }

    private static func makeRule(decoder: JSONDecoder, from row: Row) throws -> WorkspaceRule {
        guard let id = UUID(uuidString: row["id"]) else {
            throw DatabaseError(message: "Failed to decode workspace rule identifier")
        }

        let defaultAccountID: UUID?
        if let rawDefaultAccountID: String = row["default_account_id"] {
            defaultAccountID = UUID(uuidString: rawDefaultAccountID)
        } else {
            defaultAccountID = nil
        }

        let includePatterns = try decodePatterns(from: row["include_patterns"], decoder: decoder)
        let excludePatterns = try decodePatterns(from: row["exclude_patterns"], decoder: decoder)

        return WorkspaceRule(
            id: id,
            workspaceRootPath: row["workspace_root_path"],
            defaultAccountID: defaultAccountID,
            includePatterns: includePatterns,
            excludePatterns: excludePatterns,
            createdAt: row["created_at"],
            updatedAt: row["updated_at"]
        )
    }

    private static func decodePatterns(from rawValue: String, decoder: JSONDecoder) throws -> [String] {
        guard let data = rawValue.data(using: .utf8) else {
            throw DatabaseError(message: "Failed to decode workspace rule patterns")
        }

        return try decoder.decode([String].self, from: data)
    }
}
