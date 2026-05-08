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
            let existingIDMatch = try String.fetchOne(
                db,
                sql: "SELECT id FROM workspace_rules WHERE id = ?",
                arguments: [rule.id.uuidString]
            )
            let existingWorkspaceRootPathMatch = try String.fetchOne(
                db,
                sql: "SELECT id FROM workspace_rules WHERE workspace_root_path = ?",
                arguments: [rule.workspaceRootPath]
            )

            if let existingIDMatch, let existingWorkspaceRootPathMatch, existingIDMatch != existingWorkspaceRootPathMatch {
                throw DatabaseError(
                    message: "Ambiguous workspace rule save conflict for id \(rule.id.uuidString) and workspace root path \(rule.workspaceRootPath)"
                )
            }

            let existingID = existingIDMatch ?? existingWorkspaceRootPathMatch

            if let existingID {
                try db.execute(
                    sql: """
                    UPDATE workspace_rules
                    SET workspace_root_path = ?,
                        default_account_id = ?,
                        include_patterns = ?,
                        exclude_patterns = ?,
                        updated_at = ?
                    WHERE id = ?
                    """,
                    arguments: [
                        rule.workspaceRootPath,
                        rule.defaultAccountID?.uuidString,
                        includePatterns,
                        excludePatterns,
                        rule.updatedAt,
                        existingID
                    ]
                )
            } else {
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
