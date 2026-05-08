# Git Account Binder Design

- Date: 2026-05-08
- Platform: macOS
- Default UI Language: Simplified Chinese
- Status: Draft for review

## 1. Goal

Build a macOS desktop app that lets users manage multiple Git identities, bind repositories to the correct identity, and safely apply those settings to local Git and SSH configuration with full versioned rollback.

The product goal is to make Git identity management feel simple:

1. Create one or more Git accounts.
2. Bind repositories to the correct account.
3. Optionally set a default account for a whole directory.
4. Apply changes safely and restore any previous version if something goes wrong.

This is explicitly not a "manual account switcher". The app should make the correct identity apply automatically based on saved bindings and defaults.

## 2. Product Principles

1. Keep the primary mental model simple: accounts and repositories.
2. Treat directory-level defaults as an optional batch feature, not the main workflow.
3. Use Git and SSH native mechanisms where possible so behavior stays transparent and stable.
4. Make every write reversible through snapshots and restore.
5. Do not require the app to be running for bindings to keep working after they are applied.
6. Default the interface language to Simplified Chinese for the initial release.

## 3. MVP Scope

The first version will support:

1. Managing multiple Git accounts.
2. Generating a dedicated SSH key pair per account.
3. Showing the public key and guiding the user to add it to GitHub.
4. Scanning local folders for Git repositories.
5. Binding individual repositories to specific accounts.
6. Setting one global default account.
7. Setting optional directory-level default accounts.
8. Applying configuration changes to Git and SSH.
9. Creating a snapshot before every apply.
10. Viewing configuration history and restoring any previous snapshot.
11. Showing diagnostics for why a repository resolves to a given account.
12. Using Simplified Chinese as the default interface language.

The first version will not support:

1. Automatically uploading SSH keys to GitHub via API.
2. Deep platform integrations beyond GitHub-first guidance.
3. Cloud sync.
4. Team policy management or shared org-wide configuration.
5. Credential helper replacement or HTTPS token management.
6. Full commit-signing lifecycle management beyond optional signing key fields.
7. Menu bar background automation or daemon-first architecture.
8. Full multi-language localization management in MVP.

## 4. Information Architecture

The app will have five primary pages.

### 4.1 Home

The main screen shows:

1. A Git account list.
2. A repository list.
3. Simple controls to assign or reassign repositories to accounts.

This page is the primary workflow surface and should stay focused on account and repository binding.

### 4.2 Account Detail

This page shows:

1. Git name and email.
2. SSH key status.
3. Public key reveal and copy actions.
4. GitHub guidance link for SSH key setup.
5. Whether the account is the global default.

### 4.3 Workspace Defaults

This page manages optional directory-level defaults such as:

- `~/work -> Work Account`
- `~/clients -> Client A`

This page exists to speed up bulk management, but it is intentionally not the product home.

### 4.4 History

This page lists every applied version with:

1. Timestamp.
2. Human-readable summary of changes.
3. Affected accounts, repositories, workspace defaults, and files.
4. Restore action.

### 4.5 Diagnostics

This page is read-only and answers:

1. Which account a repository resolves to.
2. Why that result was selected.
3. Which Git config values are active.
4. Which SSH identity would be used.
5. Whether local files appear to have drifted from app-managed state.

## 5. Core Data Model

The app stores four primary object types.

### 5.1 Account

Represents one Git identity.

Fields:

1. `id`
2. `displayName`
3. `gitUserName`
4. `gitUserEmail`
5. `platformType`
6. `sshKeyId`
7. `signingKey` (optional)
8. `isGlobalDefault`
9. `createdAt`
10. `updatedAt`

GitHub is the first optimized platform, but the model must remain generic enough for GitLab, Gitee, and self-hosted Git systems later.

### 5.2 Repository Binding

Represents a repository explicitly bound to an account.

Fields:

1. `id`
2. `repoPath`
3. `remoteUrl`
4. `accountId`
5. `createdAt`
6. `updatedAt`

This is the highest-priority matching rule.

### 5.3 Workspace Rule

Represents a directory-level default.

Fields:

1. `id`
2. `rootPath`
3. `accountId`
4. `createdAt`
5. `updatedAt`

This applies only when no repository-specific binding exists.

### 5.4 Config Snapshot

Represents a restore point created before an apply operation.

Fields:

1. `id`
2. `createdAt`
3. `summary`
4. `changedFiles`
5. `changedRepositories`
6. `storagePath`
7. `restoreStatus`

## 6. Resolution Rules

Effective account resolution always follows this order:

1. Repository binding.
2. Workspace default.
3. Global default account.

If no match is found and no global default exists, the app should block apply for unresolved repositories and clearly mark them as unassigned.

The product should always explain the winning rule in plain language.

Example:

- "This repository uses Work because it is explicitly bound to that account."
- "This repository uses Personal because it is inside `~/personal` and no repo-specific binding exists."

## 7. Primary User Flows

### 7.1 Add Account

1. User creates a new account.
2. User enters Git name and email.
3. App generates an SSH key pair for that account.
4. App shows the public key and offers copy and open-GitHub actions.
5. User adds the public key on GitHub manually.
6. App records account readiness status.

### 7.2 Scan Repositories

1. User selects one or more folders to scan.
2. App finds Git repositories under those folders.
3. App lists detected repositories and current binding state.
4. Unassigned repositories are highlighted.

### 7.3 Bind Repository

1. User chooses a repository.
2. User selects an account.
3. App records the binding.
4. The repository now resolves to that account regardless of directory defaults.

### 7.4 Set Workspace Default

1. User chooses a root folder.
2. User selects a default account.
3. App records a workspace rule.
4. Unbound repositories under that folder resolve to that account.

### 7.5 Apply Changes

1. App computes the full set of pending file changes.
2. App shows a preview of what will change.
3. App creates a snapshot.
4. App writes configuration updates.
5. App verifies the resulting state.
6. App reports success or restores the previous snapshot on failure.

### 7.6 Restore Version

1. User opens History.
2. User selects a snapshot.
3. App previews the restore impact.
4. User confirms restore.
5. App restores the target snapshot files and internal state.
6. App verifies the restored state and reports the result.

## 8. Configuration Strategy

The app will use a hybrid strategy: app-managed data for UX plus native Git and SSH configuration for actual runtime behavior.

### 8.1 Git Configuration

The app should avoid rewriting the user's whole `~/.gitconfig`.

Instead:

1. Add or maintain a small app-managed include entry in `~/.gitconfig`.
2. Store generated app-owned Git config in an app-managed file such as:
   `~/.config/git-account-binder/generated/gitconfig`
3. Write per-repository identity values directly into `.git/config` for explicit repository bindings.
4. Use `includeIf "gitdir:..."` rules in generated config for workspace defaults.

This preserves native Git behavior and keeps the app's write surface narrow and recoverable.

### 8.2 SSH Configuration

The app should:

1. Generate a dedicated SSH key pair per account.
2. Store keys in an app-managed directory.
3. Maintain an app-managed SSH config fragment such as:
   `~/.config/git-account-binder/generated/ssh_config`
4. Integrate that fragment into the user's `~/.ssh/config` through an app-managed include or bounded managed block.

### 8.3 Repository Remote Strategy

The app will support two strategies.

#### Recommended Later Strategy

Normalize remotes to host aliases like:

- `git@github-work:org/repo.git`
- `git@github-personal:user/repo.git`

This is more explicit and stable long-term.

#### MVP Strategy

Keep existing remote URLs unchanged where possible and prefer per-repository identity control.

This reduces migration friction for first-time users and avoids forcing remote rewrites during setup.

## 9. Snapshot and Restore Design

Versioning is required in MVP because the app edits live Git and SSH configuration.

### 9.1 Snapshot Trigger

A snapshot must be created before every apply operation.

### 9.2 Snapshot Contents

Each snapshot must preserve enough material for direct restore, not just logical diffs.

At minimum it includes:

1. `~/.gitconfig`
2. `~/.ssh/config`
3. App-managed generated Git config
4. App-managed generated SSH config
5. App database
6. All affected repository `.git/config` files

### 9.3 Restore Model

Restore should work by replacing managed files with the exact contents stored in the selected snapshot, then verifying the result.

The app should not rely on reverse-diff logic to recover state.

### 9.4 External Modification Handling

If the app detects user changes outside app-managed sections or files, it should warn clearly and limit overwrites to its managed scope where possible.

If exact restore cannot be guaranteed safely, the app must explain the risk and require confirmation.

## 10. Apply Safety Model

Every apply operation must follow this sequence:

1. Validate pending account and repository assignments.
2. Show a preview of impacted repositories and files.
3. Create a snapshot.
4. Write updates.
5. Verify resulting config resolution.
6. Roll back automatically if verification fails.

The app must prefer a known-good previous state over a partial or ambiguous successful write.

## 11. Diagnostics Behavior

Diagnostics is read-only and exists to build user trust.

For a given repository it should show:

1. Selected account.
2. Winning rule.
3. Effective `user.name`.
4. Effective `user.email`.
5. Relevant local and included config sources.
6. Expected SSH identity.
7. Drift warnings if app state and on-disk state differ.

The explanation should stay human-readable rather than surfacing raw config internals first.

## 12. Platform Integration

GitHub is first-class in the initial UX:

1. Show where to add SSH keys on GitHub.
2. Offer copy-public-key action.
3. Offer open-settings-page action.

Direct GitHub API key upload is intentionally out of scope for MVP.

The underlying model remains generic so more platforms can be supported later without changing core app concepts.

## 13. Error Handling

The app must explicitly handle:

1. Invalid repository paths.
2. Missing `.git` directories.
3. Failed SSH key generation.
4. Permission errors when writing config files.
5. Conflicting user-managed Git or SSH content.
6. Partial apply failures.
7. Snapshot creation failures.
8. Restore verification failures.

Safety rules:

1. Never silently continue after a failed write that may leave state inconsistent.
2. Never destroy the user's broader config outside the app-managed scope.
3. Always provide a recoverable path, preferably by restoring the previous snapshot.

## 14. Technical Architecture

Recommended implementation stack:

1. SwiftUI for the macOS user interface.
2. Swift services for configuration orchestration.
3. `Process`-based invocation of system tools such as `git`, `ssh`, and `ssh-keygen`.
4. SQLite for accounts, bindings, workspace rules, and snapshot metadata.
5. File-based snapshot storage under:
   `~/Library/Application Support/<AppName>/Snapshots/`

This approach keeps the app native on macOS while relying on stable system tooling for actual Git and SSH behavior.

## 15. Language and Localization

The initial release should default to Simplified Chinese across the product UI, including:

1. Navigation labels.
2. Account and repository management flows.
3. Apply previews and restore prompts.
4. Error messages and diagnostics explanations.

Internal data models, file paths, and generated config file names may remain English for technical clarity and compatibility.

The UI copy should be written in clear, concise Simplified Chinese and avoid exposing Git internals unless the user enters diagnostics or advanced settings.

The architecture should leave room for future localization, but multi-language switching is not required in MVP.

## 16. Explicit Non-Goals

The app will not attempt to be:

1. A full Git client.
2. A credential vault for every auth method.
3. A cloud-synced developer profile manager.
4. An enterprise policy distribution platform.
5. A background agent that must stay running for config to work.

## 17. Success Criteria

The MVP is successful if a user can:

1. Add multiple Git accounts.
2. Generate a separate SSH key for each account.
3. Bind repositories to accounts from a simple UI.
4. Optionally assign a whole directory to one account.
5. Apply changes safely without manual Git config editing.
6. Understand why a repository resolves to a given account.
7. Restore any previous applied version if needed.
8. Use the product comfortably in Simplified Chinese without needing English-first Git knowledge.

## 18. Open Decisions Resolved In This Spec

The following decisions are fixed for MVP:

1. Product mental model: accounts plus repositories first.
2. Workspace defaults are secondary, not primary.
3. Resolution priority: repository binding over workspace default over global default.
4. GitHub-first guidance, but generic internal model.
5. Hybrid implementation: app-owned state plus native Git and SSH behavior.
6. Snapshot and restore are included in MVP.
7. The default product language is Simplified Chinese.

## 19. Summary

This product is a macOS-native Git account binder that simplifies multi-identity Git workflows into a small number of understandable actions:

1. Create accounts.
2. Bind repositories.
3. Apply changes safely.
4. Restore any previous version if necessary.

Its core value is not manual switching. Its core value is safe, automatic identity resolution with trustworthy rollback.
