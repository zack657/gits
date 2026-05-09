# Contributing

Thank you for helping improve Git Account Binder.

## Development Setup

1. Install a recent Xcode or Swift toolchain that supports Swift 6.3.
2. Clone the repository.
3. Run the test suite:

```bash
swift test
```

4. Build and launch the app:

```bash
./script/build_and_run.sh
```

## Pull Request Guidelines

- Keep changes focused and easy to review.
- Include tests for behavior changes.
- Run `swift test` before opening a pull request.
- Do not commit generated SSH keys, SQLite files, logs, build products, environment files, or local app data.
- Prefer clear Chinese UI copy for user-facing MVP screens because Simplified Chinese is the default interface language.

## Reporting Issues

When reporting a bug, include:

- macOS version
- Swift toolchain version
- steps to reproduce
- expected behavior
- actual behavior
- relevant logs with secrets removed

Please avoid sharing private repository paths, real public keys, private keys, tokens, or email addresses unless they are already public and safe to disclose.
