import Foundation
import GRDB

struct SSHKeyGuidanceStore {
    private let databaseWriter: any DatabaseWriter

    init(databaseWriter: any DatabaseWriter) {
        self.databaseWriter = databaseWriter
    }

    func save(_ guidance: SSHKeyGuidance) throws {
        try databaseWriter.write { db in
            try db.execute(
                sql: """
                INSERT INTO ssh_key_guidance (
                    account_id,
                    private_key_path,
                    public_key_path,
                    public_key,
                    github_ssh_keys_url,
                    status_text,
                    deploy_key_warning,
                    is_ready
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(account_id) DO UPDATE SET
                    private_key_path = excluded.private_key_path,
                    public_key_path = excluded.public_key_path,
                    public_key = excluded.public_key,
                    github_ssh_keys_url = excluded.github_ssh_keys_url,
                    status_text = excluded.status_text,
                    deploy_key_warning = excluded.deploy_key_warning,
                    is_ready = excluded.is_ready
                """,
                arguments: [
                    guidance.accountID.uuidString,
                    guidance.privateKeyPath,
                    guidance.publicKeyPath,
                    guidance.publicKey,
                    guidance.githubSSHKeysURL.absoluteString,
                    guidance.statusText,
                    guidance.deployKeyWarning,
                    guidance.isReady
                ]
            )
        }
    }

    func fetchAll() throws -> [UUID: SSHKeyGuidance] {
        try databaseWriter.read { db in
            let rows = try Row.fetchAll(
                db,
                sql: """
                SELECT
                    account_id,
                    private_key_path,
                    public_key_path,
                    public_key,
                    github_ssh_keys_url,
                    status_text,
                    deploy_key_warning,
                    is_ready
                FROM ssh_key_guidance
                """
            )

            var result: [UUID: SSHKeyGuidance] = [:]
            for row in rows {
                guard
                    let accountID = UUID(uuidString: row["account_id"]),
                    let githubSSHKeysURL = URL(string: row["github_ssh_keys_url"])
                else {
                    throw DatabaseError(message: "Failed to decode SSH key guidance row")
                }

                result[accountID] = SSHKeyGuidance(
                    accountID: accountID,
                    privateKeyPath: row["private_key_path"],
                    publicKeyPath: row["public_key_path"],
                    publicKey: row["public_key"],
                    githubSSHKeysURL: githubSSHKeysURL,
                    statusText: row["status_text"],
                    deployKeyWarning: row["deploy_key_warning"],
                    isReady: row["is_ready"]
                )
            }

            return result
        }
    }

    func delete(accountID: UUID) throws {
        try databaseWriter.write { db in
            try db.execute(
                sql: "DELETE FROM ssh_key_guidance WHERE account_id = ?",
                arguments: [accountID.uuidString]
            )
        }
    }
}
