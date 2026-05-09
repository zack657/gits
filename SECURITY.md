# Security Policy

## Supported Versions

This project is in early MVP development. Security fixes are handled on the `main` branch unless a release process is introduced later.

## Reporting A Vulnerability

Please do not open a public GitHub issue for sensitive security problems.

For now, contact the repository owner privately through GitHub. Include:

- a concise description of the issue
- reproduction steps
- affected files or flows
- whether private keys, local Git config, or repository data may be exposed

## Sensitive Data Policy

Never commit:

- SSH private keys
- generated public keys that identify real accounts
- SQLite app state
- config snapshots
- `.env` files
- access tokens
- local logs containing repository paths or identities

The app is designed to store runtime data under `~/Library/Application Support/GitAccountBinder`, outside of the repository.
