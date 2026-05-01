---
applyTo: "features/**"
excludeAgent: "code-review"
---

# Copilot Agent Instructions for Devcontainer Features

When the Copilot cloud agent creates or edits any file under `features/`,
it must follow these rules automatically.

## Version Bump Rule

**Any change to a feature's behavior requires a version bump in
`devcontainer-feature.json`.**

The publish workflow (`.github/workflows/publish.yml`) skips features whose
`id:version` OCI image already exists in the registry. If the version is not
bumped after a behavior change, the change will never be published.

Changes that require a version bump:
- New option added or option removed
- Option default value changed (e.g. `biomeVersion` `2.4.12` → `2.5.0`)
- `install.sh` behavior changed or bug fixed
- `platforms` or `installsAfter` array changed

Changes that do not require a version bump:
- Comment-only edits to `install.sh`
- Formatting changes
- Changes to `test.sh` or `docs/` that do not affect install behavior

## Atomic Update Rule

When bumping a version or changing an option default, always update all
affected files together in the same commit:

1. `features/<id>/devcontainer-feature.json` — `"version"` field and
   option `"default"` value
2. `test/<id>/test.sh` — `grep "<version>"` assertions
3. `test/<id>/scenarios.json` — step descriptions mentioning the version
4. `docs/features/<id>.md` — usage snippet and options default listing

Use the `bump-feature` skill for guided step-by-step assistance.

## Five-File Completeness Rule

Every feature must have exactly five files. Before committing, verify all are
present:

```text
features/<id>/devcontainer-feature.json
features/<id>/install.sh
test/<id>/test.sh
test/<id>/scenarios.json
docs/features/<id>.md
```

Run `pnpm run validate-feature <id>` to check completeness.

## `documentationURL` Must Match Actual Doc File

The `documentationURL` field in `devcontainer-feature.json` must always point
to an existing file in `docs/features/`. The filename must match the feature
`id` exactly (e.g. `claude-code.md` for `id: "claude-code"`).

```json
"documentationURL": "https://github.com/savvy-web/devcontainers/blob/main/docs/features/<id>.md"
```

Rules:
- The URL must use the `https://github.com/savvy-web/devcontainers/blob/main/` prefix
- The URL must resolve to an actual file in `docs/features/`
- Never use a generic URL or the repository homepage
- Run `pnpm run validate-feature <id>` to verify the URL resolves

## Layout

Features and tests use a flat layout — one directory per feature id under
`features/<id>/` and `test/<id>/`. Inter-feature ordering is expressed via
`installsAfter` in `devcontainer-feature.json`, not via directory scopes.

When a feature depends on another feature being installed first (for example,
`package-manager` depends on Node.js), declare it in `installsAfter`:

```json
"installsAfter": ["ghcr.io/savvy-web/node"]
```
