import Foundation
import GRDB

struct SnapshotStore {
    private let databaseWriter: any DatabaseWriter

    init(databaseWriter: any DatabaseWriter) {
        self.databaseWriter = databaseWriter
    }

    func save(_ snapshot: ConfigSnapshot) throws {
        try databaseWriter.write { db in
            let existingID = try String.fetchOne(
                db,
                sql: "SELECT id FROM config_snapshots WHERE id = ?",
                arguments: [snapshot.id.uuidString]
            )

            if let existingID {
                try db.execute(
                    sql: """
                    UPDATE config_snapshots
                    SET scope = ?,
                        target_path = ?,
                        git_config_content = ?,
                        ssh_config_content = ?,
                        known_hosts_content = ?,
                        note = ?
                    WHERE id = ?
                    """,
                    arguments: [
                        snapshot.scope.rawValue,
                        snapshot.targetPath,
                        snapshot.gitConfigContent,
                        snapshot.sshConfigContent,
                        snapshot.knownHostsContent,
                        snapshot.note,
                        existingID
                    ]
                )
            } else {
                try db.execute(
                    sql: """
                    INSERT INTO config_snapshots (
                        id,
                        scope,
                        target_path,
                        git_config_content,
                        ssh_config_content,
                        known_hosts_content,
                        note,
                        created_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    arguments: [
                        snapshot.id.uuidString,
                        snapshot.scope.rawValue,
                        snapshot.targetPath,
                        snapshot.gitConfigContent,
                        snapshot.sshConfigContent,
                        snapshot.knownHostsContent,
                        snapshot.note,
                        snapshot.createdAt
                    ]
                )
            }
        }
    }

    func fetchAll() throws -> [ConfigSnapshot] {
        try databaseWriter.read { db in
            let rows = try Row.fetchAll(
                db,
                sql: """
                SELECT
                    id,
                    scope,
                    target_path,
                    git_config_content,
                    ssh_config_content,
                    known_hosts_content,
                    note,
                    created_at
                FROM config_snapshots
                ORDER BY created_at DESC
                """
            )

            return try rows.map(Self.makeSnapshot)
        }
    }

    private static func makeSnapshot(from row: Row) throws -> ConfigSnapshot {
        guard
            let id = UUID(uuidString: row["id"]),
            let scope = ConfigSnapshot.Scope(rawValue: row["scope"])
        else {
            throw DatabaseError(message: "Failed to decode config snapshot row")
        }

        return ConfigSnapshot(
            id: id,
            scope: scope,
            targetPath: row["target_path"],
            gitConfigContent: row["git_config_content"],
            sshConfigContent: row["ssh_config_content"],
            knownHostsContent: row["known_hosts_content"],
            note: row["note"],
            createdAt: row["created_at"]
        )
    }
}
