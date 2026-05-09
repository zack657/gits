# GitHub Publishing Notes

Use this document when GitHub repository metadata or releases must be updated manually.

## Repository About

GitHub's About field has one short description field. Use the bilingual text below:

```text
macOS Git identity manager for binding repositories to accounts safely. macOS Git 多账号绑定工具，安全管理仓库身份配置。
```

Suggested topics:

```text
macos, swiftui, git, ssh, github, developer-tools, identity-management
```

Suggested website:

```text
https://github.com/zack657/gits
```

## Release v0.1.0

Title:

```text
Git Account Binder v0.1.0
```

Tag:

```text
v0.1.0
```

Release notes:

```markdown
## Git Account Binder v0.1.0

This is the first MVP release of Git Account Binder, a native macOS utility for managing multiple Git identities and binding local repositories to the right account.

### Highlights

- Manage multiple Git accounts with Git name and email.
- Generate a dedicated SSH key pair for GitHub accounts.
- Copy the generated public key and open GitHub SSH key settings.
- Test the generated SSH key against GitHub before marking an account ready.
- Detect mismatched SSH keys when GitHub authenticates as a different login.
- Add local repositories and bind each repository to a specific account.
- Apply repository-local `user.name`, `user.email`, and `core.sshCommand`.
- Create a snapshot before applying Git configuration changes.
- Restore previous configuration snapshots from the history view.
- Use a simplified Workbench-first UI with Chinese as the default app language.

### Safety Notes

- Generated SSH keys, SQLite state, local snapshots, build outputs, logs, and environment files are not committed to the repository.
- Account readiness is based on a real GitHub SSH connection test, not manual confirmation.
- Repository-local Git configuration is used so global Git defaults remain available as fallback behavior.

### Validation

- `swift test`
- `./script/build_and_run.sh --verify`
```
