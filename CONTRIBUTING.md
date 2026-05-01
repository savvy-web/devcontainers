<!-- markdownlint-disable MD041 -->
# Contributing

Thank you for your interest in contributing to `savvy-web/devcontainers`!

This repository publishes composable devcontainer features to
`ghcr.io/savvy-web/<id>`. Each feature is a self-contained directory with an
install script, tests, and documentation.

## Prerequisites

- Node.js 24+
- pnpm 10+
- Docker (for local feature testing with `act`)
- `act` — install via the [`act` devcontainer feature](src/act/)
  or from [nektosact.com](https://nektosact.com/installation/index.html)

## Development Setup

```bash
git clone https://github.com/savvy-web/devcontainers.git
cd devcontainers
pnpm install
```

## Project Structure

Features and tests use a flat layout — one directory per feature id. Inter-
feature ordering is expressed via `installsAfter` in `devcontainer-feature.json`,
not via directory scopes.

```text
src/
  <id>/     # One directory per feature, named by feature id

test/
  <id>/     # Mirrors src/<id> — test.sh + scenarios.json

docs/
  features/ # One .md doc per feature, named by feature id

scripts/
  test-feature.sh     # Run a single feature's install + test locally
  validate-feature.sh # Validate a feature's five-file completeness

.github/
  scripts/
    collect-and-filter-features.js  # Builds publish matrix (skips already-published versions)
  workflows/
    test.yml            # PR CI — auto-discovers and runs all feature tests
    publish.yml         # Publish features to ghcr.io (manual trigger)
    test-feature.yml    # Single-feature test via act (local use)
    copilot-setup-steps.yml  # Copilot cloud agent environment setup
  skills/
    devcontainer/   # Devcontainer spec and repo conventions skill
    github-actions/ # GitHub Actions workflow skill
    new-feature/    # Scaffold a new feature (all five files)
    bump-feature/   # Bump a feature version atomically
    debug-feature/  # Diagnose failing install.sh or test.sh
```

## Creating a New Feature

Every feature requires exactly five files:

```text
src/<id>/devcontainer-feature.json
src/<id>/install.sh
test/<id>/test.sh
test/<id>/scenarios.json
docs/features/<id>.md
```

Use the `new-feature` Copilot skill for guided scaffolding, or create the
files manually following the conventions in
`.github/skills/devcontainer/references/feature-anatomy.md`.

After creating the files, run the validation script:

```bash
pnpm run validate-feature my-feature
```

And optionally run the full install + test cycle locally (requires Docker and
`act`):

```bash
pnpm run test:feature my-feature
```

## Bumping a Feature Version

The publish workflow skips features whose `id:version` OCI image already
exists in the registry. You must bump the version whenever the feature's
behavior changes.

Always update all version references together:

1. `"version"` in `devcontainer-feature.json`
2. `grep "<version>"` assertions in `test.sh` (if tool default changed)
3. Version string in `docs/features/<id>.md` usage snippet
4. Option default in `devcontainer-feature.json` (if pinned tool version
   changed)

Use the `bump-feature` Copilot skill for a guided checklist.

## Available Scripts

| Script | Description |
| :----- | :---------- |
| `pnpm run test:feature <id>` | Run install + test for one feature locally via act |
| `pnpm run validate-feature <id>` | Check five-file completeness and structural correctness |
| `pnpm run lint` | Lint JS/TS/JSON files with Biome |
| `pnpm run lint:fix` | Auto-fix lint issues |
| `pnpm run lint:md` | Lint Markdown files with markdownlint |

## Commit Format

All commits must follow [Conventional Commits](https://conventionalcommits.org)
and include a DCO signoff:

```text
feat(biome): bump default version to 2.5.0

Signed-off-by: Your Name <your.email@example.com>
```

Valid commit types: `feat`, `fix`, `chore`, `docs`, `ci`, `build`,
`test`, `refactor`, `perf`, `style`, `revert`, `ai`, `release`.

## Submitting Changes

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Run `pnpm run validate-feature <id>` to check your files
4. Commit with conventional format and DCO signoff
5. Push and open a pull request

## License

By contributing, you agree that your contributions will be licensed under the
MIT License.
