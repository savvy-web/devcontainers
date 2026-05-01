---
name: devcontainer
allowed-tools: fetch
description: >-
  Use when asked to create, modify, test, or document devcontainer features
  in this repository. Also covers devcontainer.json authoring, feature
  distribution, and writing docs/features/*.md documentation.
---

# Devcontainer Features Expert

Devcontainer spec details evolve. Always ground answers in the official
`containers.dev` documentation when the question involves spec behavior, JSON
schema fields, or distribution. Return the closest authoritative page rather
than recalling stale details.

## When to Use

Use this skill when the request is about:

- Creating a new devcontainer feature in this repository
- Editing an existing feature's `devcontainer-feature.json` or `install.sh`
- Writing or updating feature tests (`test.sh`, `scenarios.json`)
- Writing or updating feature documentation (`docs/features/<id>.md`)
- Debugging a feature install script
- Understanding `devcontainer-feature.json` field semantics or option types
- Questions about the devcontainer spec, JSON schema, or feature distribution
- Authoring or validating a `devcontainer.json` that references these features

Do **not** use this skill for:

- Debugging a failing CI run or publish workflow — use the `github-actions`
  skill and GitHub MCP Server tools (`list_workflow_runs`, `get_job_logs`)
- General Docker, container image, or Dockerfile questions unrelated to features

## Workflow

### 1. Classify the request

Decide which bucket the question belongs to before searching:

- Feature creation (new feature from scratch)
- Feature editing (modifying an existing feature)
- Test authoring (`test.sh` / `scenarios.json`)
- Documentation authoring (`docs/features/*.md`)
- Spec or schema question (field semantics, option types, distribution)
- `devcontainer.json` authoring (consuming features in a project)

Load the nearest reference file to avoid unnecessary fetches:

- Feature creation or editing → `references/feature-anatomy.md`
- Test authoring → `references/test-patterns.md`
- Documentation → `references/doc-template.md`
- Spec or schema questions → `references/topic-map.md` then fetch live docs

### 2. Search official containers.dev docs for spec questions

- Treat `containers.dev/implementors/` as the source of truth for spec behavior.
- Prefer the Features spec page for option types, env var injection, and
  lifecycle hooks.
- Search with the user's exact terms plus a focused phrase such as
  `devcontainer feature option`, `installsAfter`, or `devcontainer.json schema`.

### 3. Open the best page before answering

- Read the most relevant section of the spec page, not just the homepage.
- If a page appears renamed or incomplete, say so and return the nearest
  authoritative page instead of guessing.

### 4. Answer with docs-grounded guidance

- Start with a direct answer in plain language.
- Include exact `containers.dev` links, not just the homepage.
- Only provide shell script or JSON examples when the user asks for them or
  when they are necessary to illustrate the answer.
- Make any inference explicit:
  - `According to the containers.dev spec, …`
  - `Inference: this likely means …`

## Repo-Specific Context

### Directory Layout

Features and tests use a flat layout — one directory per feature id. Inter-
feature ordering is expressed via `installsAfter` in
`devcontainer-feature.json`, not via directory scopes.

```text
src/
  <id>/                    # one directory per feature, named by feature id
    devcontainer-feature.json
    install.sh

test/
  <id>/
    test.sh
    scenarios.json

docs/
  features/
    <id>.md                # one file per feature, named by feature id
```

### `devcontainer-feature.json` Conventions

- `id` — kebab-case, unique within the repo (e.g. `biome`, `package-manager`)
- `version` — start at `0.1.0`; the publish workflow uses this to skip
  already-published versions
- `documentationURL` — always set to
  `https://github.com/savvy-web/devcontainers/blob/main/docs/features/<id>.md`
- `installsAfter` — use to declare ordering dependencies on other features
  (e.g. `["ghcr.io/devcontainers/features/common-utils"]`)
- `platforms` — always an array; use `["linux", "darwin"]` unless the feature
  is Linux-only (e.g. `["linux"]` for kernel-dependent features)
- Absolute version pinning — never use semver ranges in option defaults; pin
  to an exact version like `"24.11.0"`, not `">=24"`

### `install.sh` Conventions

- Always start with `#!/usr/bin/env bash` and `set -euo pipefail`
- Read options from env vars injected by the devcontainer CLI. The env var name
  is the option key uppercased: `biomeVersion` → `$BIOME_VERSION`
- Always provide a defensive default: `VERSION="${BIOME_VERSION:-latest}"`
- Detect architecture with `uname -m` and normalize to `x64` / `arm64`
- Detect OS with `uname -s | tr '[:upper:]' '[:lower:]'`
- End with a validation step: `command -v <binary>` or `<binary> --version`
- Print `[ERROR]` to stderr and `exit 1` on unrecoverable failures
- Print `[INFO]` for progress steps
- Use `_REMOTE_USER` (not `_CONTAINER_USER`) to transfer directory ownership to
  the devcontainer user after installing to user-writable paths. Always guard
  for the unset and root cases — see `references/feature-anatomy.md` §User
  Environment Variables for the canonical pattern

### Feature Bootstrap Checklist

When creating a new feature, create all five files:

1. `src/<id>/devcontainer-feature.json`
2. `src/<id>/install.sh`
3. `test/<id>/test.sh`
4. `test/<id>/scenarios.json`
5. `docs/features/<id>.md`

The publish workflow discovers features by scanning for
`devcontainer-feature.json` files. The test workflow discovers tests by
looking for `test/<id>/test.sh` matching the feature's directory name.

## Design Principles

- **Idempotent** — running `install.sh` twice must not fail or produce a
  broken state. Guard installs with `if ! command -v <binary>` where
  re-installation would be harmful.
- **Reproducible** — pin to absolute versions in defaults. Accept `latest` only
  when the feature explicitly documents that behavior.
- **Minimal** — install only what the feature declares; avoid bundling
  unrelated tools.
- **Validated** — always verify the install succeeded before the script exits.
- **Ordered** — use `installsAfter` when the feature depends on another feature
  or base image capability being present first.

## Documentation Rules

- One `#` heading equal to the feature name — no subtitles on the same line
- `## Options` section: one bullet per option in the format
  `` - `optionName`: Description. Default: `value` ``
- `## Usage` section: a fenced `jsonc` block showing the minimum
  `devcontainer.json` snippet needed to activate the feature
- Optional `## Example` section: a realistic `devcontainer.json` with
  non-default options, only when it adds clarity
- Keep docs short — match the brevity of `docs/features/biome.md` (~12 lines)
- Direct imperative voice — "Installs Biome globally" not "This feature will
  install Biome globally for you"
- No filler phrases, no marketing language

## Common Mistakes

- **Env var not set** — the devcontainer CLI injects option values as env vars
  but they may be empty strings, not unset. Always use
  `VAR="${OPTION_VAR:-default}"` to handle both the unset and empty-string case.
- **Executable bits not committed** — shell scripts are stored in git without
  the executable bit (`100644`). Do **not** run `chmod +x` or
  `git update-index --chmod=+x`. Husky hooks set the bits on checkout/merge
  locally; CI workflows set them before running scripts. The
  `validate-feature` script may note missing bits — this is expected and safe
  to ignore.
- **Semver ranges** — option defaults like `">=20"` or `"^24"` are not
  reproducible. Always use an exact version string.
- **Missing `documentationURL`** — all features must link to their doc page.
- **`version` not bumped** — the `collect-and-filter-features.js` script skips
  a feature if its `id:version` image already exists in the registry. Bump
  `version` whenever the feature behavior changes.
- **Test version mismatch** — `test.sh` assertions must match the default
  version in `devcontainer-feature.json`. When bumping the default, update
  both files.

## Answer Shape

Use a compact structure unless the user asks for depth:

1. Direct answer
2. File contents or diffs — only if the user asked to create or edit files
3. Relevant containers.dev links — only for spec questions
4. Explicit inference callout — only when connecting multiple sources

Keep citations close to the claim they support.

## Bundled Reference Files

The following reference files are pre-loaded in this skill directory. Load
them to avoid unnecessary fetches for the most common questions:

- `references/topic-map.md` — compact index of containers.dev documentation
  entry points; intentionally selective, never replaces live docs
- `references/feature-anatomy.md` — dense reference for every
  `devcontainer-feature.json` field and `install.sh` convention, with examples
  drawn from this repo
- `references/test-patterns.md` — the two-file test convention (`test.sh` +
  `scenarios.json`), assertion patterns, and CI integration details
- `references/doc-template.md` — fill-in-the-blanks template for
  `docs/features/<id>.md` plus writing rules
