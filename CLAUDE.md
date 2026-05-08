<!-- markdownlint-disable MD041 -->
<coding_guidelines>

# CLAUDE.md

Guidance for Claude Code and Copilot cloud agents working in this repository.

## What This Repo Is

`savvy-web/devcontainers` publishes composable devcontainer features to
`ghcr.io/savvy-web/<id>`. Features are self-contained directories with an
install script, tests, and documentation. They are consumed in
`devcontainer.json` files across Savvy Web repositories.

This is **not** a Node.js library. The `package.json` at the root provides
tooling scripts only — it does not publish an npm package.

## Copilot Skills

Specialized skills are available in `.github/skills/`. Invoke them by
name when the task matches:

| Skill | When to use |
| :---- | :---------- |
| `devcontainer` | Create/edit feature files, understand spec fields, write tests or docs |
| `new-feature` | Scaffold all five required files for a new feature in one session |
| `bump-feature` | Bump a feature version and update all related files atomically |
| `debug-feature` | Diagnose a failing `install.sh` or `test.sh` |
| `github-actions` | Work on workflow files in `.github/workflows/` |

## Directory Layout

Features and tests use a flat layout — one directory per feature id.
Inter-feature ordering is expressed via `installsAfter` in
`devcontainer-feature.json`, not via directory scopes.

```text
src/
  <id>/                    # one directory per feature, named by feature id
    devcontainer-feature.json
    install.sh
    README.md              # canonical docs — auto-generated format
    NOTES.md               # optional extra content appended to README

test/
  <id>/                    # mirrors src/<id> — test.sh + scenarios.json per feature
    test.sh
    scenarios.json
lib/                       # config files and repo-level helpers
    scripts/
      test-feature.sh          # Run one feature's install + test locally via act
      validate-feature.sh      # Check five-file completeness and structural rules

docs/
  features/                # legacy doc files (no longer canonical; see src/<id>/README.md)
    <id>.md

.github/
  scripts/
    collect-and-filter-features.js  # Builds publish matrix (skips existing versions)
  workflows/
    test.yml                  # PR CI — auto-discovers all features and tests them
    publish.yml               # Publish to ghcr.io via devcontainers/action (manual trigger)
    test-feature.yml          # Single-feature test used by lib/scripts/test-feature.sh
    copilot-setup-steps.yml   # Copilot agent environment (Node, pnpm, devcontainer CLI)
  skills/
    devcontainer/             # Devcontainer spec + repo conventions
    github-actions/           # GitHub Actions workflows
    new-feature/              # New feature scaffolding
    bump-feature/             # Version bump guidance
    debug-feature/            # Install/test failure diagnosis
  instructions/
    BIOME.instructions.md     # Auto-lint JS/TS/JSON with Biome after edits
    YAML.instructions.md      # Auto-lint YAML with prettier + yaml-lint after edits
    MARKDOWN.instructions.md  # Auto-lint Markdown with markdownlint-cli2 after edits
    SHELL.instructions.md     # Shell script conventions (auto-applied to *.sh)
    FEATURE.instructions.md   # Feature version-bump and completeness rules (auto-applied to features/**)
```

## Five-File Rule

Every feature must have exactly these files:

```text
src/<id>/devcontainer-feature.json
src/<id>/install.sh
src/<id>/README.md
test/<id>/test.sh
test/<id>/scenarios.json
```

An optional `src/<id>/NOTES.md` may be added for extra content (extended
examples, OS notes) that the auto-generated README template does not cover.

Run `pnpm run feature:validate <id>` to verify all five exist and pass
structural checks before committing.

## Executable Bits

Shell scripts are stored in git **without** the executable bit (`100644`, not
`100755`). Do **not** run `chmod +x` on scripts or use
`git update-index --chmod=+x`. The bits are managed automatically:

- **Local dev** — a Husky `post-checkout`/`post-merge` hook runs
  `git ls-files -z '*.sh' | xargs -0 chmod +x` after every checkout and
  merge, and `core.fileMode` is set to `false` so git ignores the local
  mode change.
- **CI** — the test and publish workflows set the bits before invoking any
  script.

Agents running `validate-feature` may see an informational note about
executable bits; this is expected and safe to ignore.

## Version Bump Rule

**Before bumping a version, check whether the current version is already
published** — if the registry doesn't have the version yet, a previous bump
is pending and no new bump is needed:

```bash
docker manifest inspect ghcr.io/savvy-web/<id>:<version> 2>/dev/null \
  && echo "published" || echo "not published"
```

The publish workflow skips any feature whose `id:version` OCI image already
exists in the registry. **Always bump `"version"` in
`devcontainer-feature.json` when the feature behavior changes.** Update
`test.sh` assertions, `src/<id>/README.md` defaults, and option defaults
atomically in the same commit.

## Local Testing

```bash
# Validate structure (no Docker needed)
pnpm run validate-feature biome

# Full install + test via act (requires Docker)
pnpm run feature:test biome
```

`scripts/test-feature.sh` calls `act workflow_dispatch` targeting
`.github/workflows/test-feature.yml`, which runs `install.sh` then `test.sh`
inside a fresh `catthehacker/ubuntu:act-latest` container.

## Linting

```bash
pnpm run lint        # Biome — JS/TS/JSON
pnpm run lint:fix    # Biome with auto-fix
pnpm run lint:md     # markdownlint — Markdown files
shellcheck <file>    # Shell scripts (if shellcheck is installed)
```

## Commit Format

Conventional Commits with DCO signoff:

```text
feat(biome): bump default version to 2.5.0

Signed-off-by: Name <email>
```

Valid types: `feat`, `fix`, `chore`, `docs`, `ci`, `build`, `test`,
`refactor`, `perf`, `style`, `revert`, `ai`, `release`.

## Publish Pipeline

The `publish.yml` workflow:

1. **collect** — `collect-and-filter-features.js` builds a JSON matrix of
   features not yet published at their current version (checks OCI registry)
2. **test** — fan-out matrix job installs each feature and runs its `test.sh`
3. **summarize** — writes a Markdown table to `$GITHUB_STEP_SUMMARY`; blocks
   publish if any test failed
4. **publish** — uses `devcontainers/action@v1` to publish all features in
   `./src` to `ghcr.io/savvy-web/<id>:<version>`; the action installs the
   devcontainer CLI and handles version-skipping internally

The test matrix in `test.yml` (PR CI) is built dynamically from all
`test/<id>/test.sh` files via inline discovery — no manual matrix
updates are needed when a new feature is added.
</coding_guidelines>
