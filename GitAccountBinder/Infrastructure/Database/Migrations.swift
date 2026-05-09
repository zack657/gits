import Foundation
import GRDB

enum Migrations {
    static let migrator: DatabaseMigrator = {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_create_core_tables") { db in
            try db.create(table: "accounts") { table in
                table.column("id", .text).notNull().primaryKey()
                table.column("display_name", .text).notNull()
                table.column("git_user_name", .text).notNull()
                table.column("git_user_email", .text).notNull()
                table.column("platform_type", .text).notNull()
                table.column("ssh_key_id", .text)
                table.column("signing_key", .text)
                table.column("is_global_default", .boolean).notNull().defaults(to: false)
                table.column("created_at", .datetime).notNull()
                table.column("updated_at", .datetime).notNull()
            }

            try db.create(table: "repository_bindings") { table in
                table.column("id", .text).notNull().primaryKey()
                table.column("repository_path", .text).notNull().unique()
                table.column("account_id", .text)
                    .notNull()
                    .indexed()
                    .references("accounts", onDelete: .cascade)
                table.column("remote_url", .text)
                table.column("branch_pattern", .text)
                table.column("priority", .integer).notNull().defaults(to: 0)
                table.column("created_at", .datetime).notNull()
                table.column("updated_at", .datetime).notNull()
            }

            try db.create(table: "workspace_rules") { table in
                table.column("id", .text).notNull().primaryKey()
                table.column("workspace_root_path", .text).notNull().unique()
                table.column("default_account_id", .text)
                    .indexed()
                    .references("accounts", onDelete: .setNull)
                table.column("include_patterns", .text).notNull()
                table.column("exclude_patterns", .text).notNull()
                table.column("created_at", .datetime).notNull()
                table.column("updated_at", .datetime).notNull()
            }

            try db.create(table: "config_snapshots") { table in
                table.column("id", .text).notNull().primaryKey()
                table.column("scope", .text).notNull()
                table.column("target_path", .text).notNull()
                table.column("git_config_content", .text).notNull()
                table.column("ssh_config_content", .text).notNull()
                table.column("known_hosts_content", .text)
                table.column("note", .text)
                table.column("created_at", .datetime).notNull()
            }
        }

        migrator.registerMigration("v2_create_ssh_key_guidance") { db in
            try db.create(table: "ssh_key_guidance") { table in
                table.column("account_id", .text)
                    .notNull()
                    .primaryKey()
                    .references("accounts", onDelete: .cascade)
                table.column("private_key_path", .text).notNull()
                table.column("public_key_path", .text).notNull()
                table.column("public_key", .text).notNull()
                table.column("github_ssh_keys_url", .text).notNull()
                table.column("status_text", .text).notNull()
                table.column("deploy_key_warning", .text).notNull()
                table.column("is_ready", .boolean).notNull().defaults(to: false)
            }
        }

        migrator.registerMigration("v3_normalize_application_support_paths") { db in
            try db.execute(
                sql: """
                UPDATE ssh_key_guidance
                SET private_key_path = REPLACE(private_key_path, 'Application%20Support', 'Application Support'),
                    public_key_path = REPLACE(public_key_path, 'Application%20Support', 'Application Support')
                WHERE private_key_path LIKE '%Application%20Support%'
                   OR public_key_path LIKE '%Application%20Support%'
                """
            )
        }

        return migrator
    }()
}
