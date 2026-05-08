import Foundation
import GRDB

struct AccountStore {
    private let databaseWriter: any DatabaseWriter

    init(databaseWriter: any DatabaseWriter) {
        self.databaseWriter = databaseWriter
    }

    func save(_ account: Account) throws {
        try databaseWriter.write { db in
            if account.isGlobalDefault {
                try db.execute(
                    sql: """
                    UPDATE accounts
                    SET is_global_default = 0,
                        updated_at = ?
                    WHERE id <> ?
                    """,
                    arguments: [account.updatedAt, account.id.uuidString]
                )
            }

            let existingID = try String.fetchOne(
                db,
                sql: "SELECT id FROM accounts WHERE id = ?",
                arguments: [account.id.uuidString]
            )

            if let existingID {
                try db.execute(
                    sql: """
                    UPDATE accounts
                    SET display_name = ?,
                        git_user_name = ?,
                        git_user_email = ?,
                        platform_type = ?,
                        ssh_key_id = ?,
                        signing_key = ?,
                        is_global_default = ?,
                        updated_at = ?
                    WHERE id = ?
                    """,
                    arguments: [
                        account.displayName,
                        account.gitUserName,
                        account.gitUserEmail,
                        account.platformType.rawValue,
                        account.sshKeyID?.uuidString,
                        account.signingKey,
                        account.isGlobalDefault,
                        account.updatedAt,
                        existingID
                    ]
                )
            } else {
                try db.execute(
                    sql: """
                    INSERT INTO accounts (
                        id,
                        display_name,
                        git_user_name,
                        git_user_email,
                        platform_type,
                        ssh_key_id,
                        signing_key,
                        is_global_default,
                        created_at,
                        updated_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    arguments: [
                        account.id.uuidString,
                        account.displayName,
                        account.gitUserName,
                        account.gitUserEmail,
                        account.platformType.rawValue,
                        account.sshKeyID?.uuidString,
                        account.signingKey,
                        account.isGlobalDefault,
                        account.createdAt,
                        account.updatedAt
                    ]
                )
            }
        }
    }

    func fetchAll() throws -> [Account] {
        try databaseWriter.read { db in
            let rows = try Row.fetchAll(
                db,
                sql: """
                SELECT
                    id,
                    display_name,
                    git_user_name,
                    git_user_email,
                    platform_type,
                    ssh_key_id,
                    signing_key,
                    is_global_default,
                    created_at,
                    updated_at
                FROM accounts
                ORDER BY display_name COLLATE NOCASE, created_at
                """
            )

            return try rows.map(Self.makeAccount)
        }
    }

    private static func makeAccount(from row: Row) throws -> Account {
        guard
            let id = UUID(uuidString: row["id"]),
            let platformType = Account.PlatformType(rawValue: row["platform_type"])
        else {
            throw DatabaseError(message: "Failed to decode account row")
        }

        let sshKeyID: UUID?
        if let rawSSHKeyID: String = row["ssh_key_id"] {
            sshKeyID = UUID(uuidString: rawSSHKeyID)
        } else {
            sshKeyID = nil
        }

        return Account(
            id: id,
            displayName: row["display_name"],
            gitUserName: row["git_user_name"],
            gitUserEmail: row["git_user_email"],
            platformType: platformType,
            sshKeyID: sshKeyID,
            signingKey: row["signing_key"],
            isGlobalDefault: row["is_global_default"],
            createdAt: row["created_at"],
            updatedAt: row["updated_at"]
        )
    }
}
