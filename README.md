# Git Account Binder

[简体中文](README.zh-CN.md)

Git Account Binder is a native macOS utility for people who use multiple Git identities on the same machine. It keeps the workflow simple: create Git accounts, bind repositories to the right account, and apply local Git configuration safely.

## Why This Exists

Git's native configuration is powerful, but managing multiple accounts across personal, work, and client repositories can become fragile. This app provides a visual layer over the local Git and SSH settings while keeping the actual behavior transparent and compatible with standard Git commands.

## Current Features

- Manage multiple Git accounts with Git name and email.
- Generate a dedicated SSH key pair when a GitHub account is added.
- Copy the generated public key and open GitHub SSH key settings.
- Add and remove local repositories from the managed list.
- Bind each repository to a specific Git account.
- Apply bindings to each repository's local `.git/config`.
- Write `user.name`, `user.email`, and `core.sshCommand` for bound repositories.
- Create a snapshot before applying changes.
- View history and restore a previous snapshot if a configuration change goes wrong.
- Persist app state locally with SQLite.
- Use Simplified Chinese as the default UI language.

## Safety Model

The app stores runtime state under:

```text
~/Library/Application Support/GitAccountBinder
```

Generated SSH private keys, public keys, SQLite databases, snapshots, build products, and local tool configuration are intentionally ignored by Git. Do not commit real keys, local databases, logs, or environment files.

Before applying Git configuration, the app creates a snapshot of the affected repository config files. The app then writes repository-local settings only, so existing global Git defaults remain available as fallback behavior.

## GitHub SSH Key Guidance

Generated keys are intended to be added to a GitHub account under:

```text
GitHub Settings -> SSH and GPG keys
```

Do not add these account keys as repository deploy keys. Deploy keys are repository-scoped and are not part of the current MVP.

## Requirements

- macOS 14 or later
- Swift 6.3 toolchain
- Git
- SSH and `ssh-keygen`

## Build And Run

Run tests:

```bash
swift test
```

Build and launch the macOS app bundle:

```bash
./script/build_and_run.sh
```

Build and verify that the app launches:

```bash
./script/build_and_run.sh --verify
```

## Project Structure

- `GitAccountBinder/`: macOS app source.
- `GitAccountBinderTests/`: Swift Testing test suite.
- `docs/superpowers/specs/`: product and architecture notes.
- `docs/superpowers/plans/`: implementation plans.
- `script/`: local developer scripts.

## Status

This is an early MVP. The app is useful for local Git identity binding, but several areas are intentionally still conservative:

- GitHub key upload is manual.
- Directory-level default account rules are still a product surface for later expansion.
- Commit signing lifecycle is not implemented.
- Cloud sync and team policy management are out of scope.

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening issues or pull requests.

## Security

Please do not open public issues for sensitive security problems. See [SECURITY.md](SECURITY.md).

## License

No open-source license has been selected yet. Until a license is added, all rights are reserved by the repository owner.
