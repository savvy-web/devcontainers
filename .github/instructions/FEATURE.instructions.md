---
applyTo: "src/**"
excludeAgent: "code-review"
---

# Copilot Agent Instructions for Devcontainer Features

When the Copilot cloud agent creates or edits any file under `src/`,
it must follow these rules automatically.

## Version Bump Rule

**Any change to a feature's behavior requires a version bump in
`devcontainer-feature.json`.** — but only if the current version has already
been published to the registry.

**Before bumping, check the OCI registry** to see whether the current version
in `devcontainer-feature.json` already exists:

```bash
docker manifest inspect ghcr.io/savvy-web/features/<id>:<version> 2>/dev/null \
  && echo "published" || echo "not published"
```

- If **not published**: the feature already has a pending (unreleased) version.
  **Do not bump again.** Add your changes on top of the existing version.
- If **published**: the current version is live. Bump the version before
  making any behavior change.

Example: if `devcontainer-feature.json` says `"version": "0.2.0"` but
`ghcr.io/savvy-web/features/<id>:0.2.0` returns a 404, then `0.2.0` is a pending
release — do not bump to `0.3.0`.

The publish workflow (`.github/workflows/publish.yml`) skips features whose
`id:version` OCI image already exists in the registry. If the version is not
bumped after a behavior change, the change will never be published.

Changes that require a version bump (only when the current version is already published):

- New option added or option removed
- Option default value changed (e.g. `biomeVersion` `2.4.12` → `2.5.0`)
- `install.sh` behavior changed or bug fixed
- `platforms` or `installsAfter` array changed
- `customizations` changed

Changes that do not require a version bump:

- Comment-only edits to `install.sh`
- Formatting changes
- Changes to `test.sh` or `src/<id>/README.md` that do not affect install behavior

## Atomic Update Rule

When bumping a version or changing an option default, always update all
affected files together in the same commit:

1. `src/<id>/devcontainer-feature.json` — `"version"` field and
   option `"default"` value
2. `test/<id>/test.sh` — `grep "<version>"` assertions
3. `test/<id>/scenarios.json` — scenario option values mentioning the version
4. `test/<id>/<scenario_name>.sh` — `grep "<version>"` assertions in scenario scripts
5. `src/<id>/README.md` — options table default values and usage snippet version

Use the `bump-feature` skill for guided step-by-step assistance.

## Five-File Rule

Every feature must have at least these five files. Before committing, verify all are
present:

```text
src/<id>/devcontainer-feature.json
src/<id>/install.sh
src/<id>/README.md
test/<id>/test.sh
test/<id>/scenarios.json
```

An optional `src/<id>/NOTES.md` may be added for extra content that the
auto-generated README template does not cover (extended examples, OS support
notes, integration guides).

If `scenarios.json` is non-empty (contains scenario keys), each key also
requires a matching `test/<id>/<scenario_name>.sh` assertion script.

Run `pnpm run feature:validate <id>` to check completeness.

**Note on executable bits:** scripts are stored as `100644` (non-executable)
in git. The Husky `post-checkout`/`post-merge` hooks set the bits locally and
CI workflows set them before running. Do **not** run `chmod +x` or
`git update-index --chmod=+x` — the bits are intentionally absent in git.

## `documentationURL` Must Match `src/<id>/README.md`

The `documentationURL` field in `devcontainer-feature.json` must always point
to `src/<id>/README.md` in the repository.

```json
"documentationURL": "https://github.com/savvy-web/devcontainers/blob/main/src/<id>/README.md"
```

Rules:

- The URL must use the `https://github.com/savvy-web/devcontainers/blob/main/` prefix
- The URL must resolve to `src/<id>/README.md` (not `docs/features/<id>.md`)
- Never use a generic URL or the repository homepage
- Run `pnpm run feature:validate <id>` to verify the URL resolves

## Copilot Customizations

Every feature must include a `customizations.vscode.settings.github.copilot.chat.codeGeneration.instructions`
entry so Copilot knows what tools are available in the container:

```json
"customizations": {
  "vscode": {
    "settings": {
      "github.copilot.chat.codeGeneration.instructions": [
        {
          "text": "This dev container has <tool> pre-installed and available on the PATH. <Usage guidance.>"
        }
      ]
    }
  }
}
```

If the feature also recommends VS Code extensions, include both `extensions` and
`settings` under `customizations.vscode`:

```json
"customizations": {
  "vscode": {
    "extensions": ["rust-lang.rust-analyzer"],
    "settings": {
      "github.copilot.chat.codeGeneration.instructions": [
        { "text": "..." }
      ]
    }
  }
}
```

## Layout

Features and tests use a flat layout — one directory per feature id under
`src/<id>/` and `test/<id>/`. Inter-feature ordering is expressed via
`installsAfter` in `devcontainer-feature.json`, not via directory scopes.

When a feature depends on another feature being installed first (for example,
`package-manager` depends on Node.js), declare it in `installsAfter`:

```json
"installsAfter": ["ghcr.io/savvy-web/features/node"]
```
