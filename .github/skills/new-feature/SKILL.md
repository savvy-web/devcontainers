---
name: new-feature
allowed-tools: read_file, write_file, list_files, fetch
description: >-
  Use when asked to create a new devcontainer feature in this repository.
  Triggers for prompts like "add a feature for X", "create a new feature",
  "scaffold a feature", or "add X to the devcontainer features".
---

# New Devcontainer Feature Scaffold

Creates all required files for a new devcontainer feature in one guided
session. Every feature must have exactly these files — missing any one of them
will cause CI or publishing to fail.

## Required Files

| File | Purpose |
| :--- | :------ |
| `src/<id>/devcontainer-feature.json` | Feature metadata and options |
| `src/<id>/install.sh` | Installation script |
| `src/<id>/README.md` | Generated-style documentation (canonical docs) |
| `test/<id>/test.sh` | Post-install assertions |
| `test/<id>/scenarios.json` | Human-readable scenario descriptions |

An optional `src/<id>/NOTES.md` may be added for extra content (extended
examples, OS support notes, integration guides) that the auto-generated README
template does not cover.

## Workflow

### Step 1 — Gather information

Ask the user for these values before generating any file:

| Field | Description | Example |
| :---- | :---------- | :------ |
| `id` | Kebab-case unique identifier | `biome`, `package-manager`, `act` |
| `name` | Human-readable display name | `Biome (global linter)` |
| `description` | One-sentence description of what the feature installs | `Installs Biome globally for all runtimes.` |
| `options` | Map of option key → `{type, default, description}` objects | see below |
| `installsAfter` | Other features this must run after (usually `[]`) | `["ghcr.io/devcontainers/features/common-utils"]` |
| `platforms` | `["linux", "darwin"]` unless Linux-only | `["linux"]` for firewall features |

If the user does not provide options, ask whether the feature has any
configurable parameters (version strings, flags, paths). Version-pinned tools
always get a `*Version` option with an absolute default.

### Step 2 — Check for conflicts

Before writing files:

1. Verify `src/<id>/` does not already exist
2. Check `containers.dev/features` to see if a community feature already
   exists for this tool — prefer referencing an upstream feature over
   duplicating it

If the feature depends on another feature being installed first (for example,
`package-manager` depends on Node.js), declare the dependency in `installsAfter`:
rather than via a directory scope:

```json
"installsAfter": ["ghcr.io/savvy-web/node"]
```

### Step 3 — Generate all required files

Generate every file in sequence, following the conventions below. Do not skip
any file.

---

## File-by-File Conventions

### `devcontainer-feature.json`

```json
{
  "id": "<id>",
  "version": "0.1.0",
  "name": "<name>",
  "description": "<description>",
  "documentationURL": "https://github.com/savvy-web/devcontainers/blob/main/src/<id>/README.md",
  "options": {
    "<optionKey>": {
      "type": "string",
      "default": "<absolute-version>",
      "description": "<description>"
    }
  },
  "installsAfter": [],
  "platforms": ["linux", "darwin"],
  "keywords": ["<keyword1>", "<keyword2>"],
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
}
```

Rules:

- Always start at `"version": "0.1.0"`
- `documentationURL` must point to `src/<id>/README.md` (not `docs/features/<id>.md`)
- `options` — omit the field entirely if the feature has no options
- `installsAfter` — omit or set to `[]` when empty; never set to `null`
- `platforms` — use `["linux"]` for features that use Linux-specific
  kernel interfaces (iptables, nftables, systemd services)
- `keywords` — 3–6 lowercase, space-free strings
- `customizations.vscode.settings.github.copilot.chat.codeGeneration.instructions`
  — always include; describe what the feature installs and how to use it

### `install.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

# <Feature name> installer
# Docs: <upstream tool docs URL>

VERSION="${<OPTION_KEY>:-<default>}"

# Detect architecture
ARCH=$(uname -m)
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

if [[ "$ARCH" == "x86_64" ]]; then
  ARCH="x64"
elif [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
  ARCH="arm64"
else
  echo "[ERROR] Unsupported architecture: $ARCH" >&2
  exit 1
fi

# Download and install
# ... (tool-specific install commands here)

# Validate install
if ! command -v <binary> &>/dev/null; then
  echo "[ERROR] <binary> not found in PATH after install." >&2
  exit 1
fi

<binary> --version
```

Rules:

- `#!/usr/bin/env bash` + `set -euo pipefail` on lines 1–2 — no exceptions
- Env var name = option key uppercased + underscores: `biomeVersion` → `$BIOME_VERSION`
- Always provide a defensive default: `VERSION="${BIOME_VERSION:-latest}"`
- Detect arch with `uname -m`; normalize to `x64` / `arm64`
- Detect OS with `uname -s | tr '[:upper:]' '[:lower:]'`
- Log progress with `[INFO]`, errors with `[ERROR]`, success with `[SUCCESS]`
- All error messages go to stderr (`>&2`)
- End with `command -v <binary>` guard + version print
- Idempotency: guard re-installs with `if ! command -v <tool>` when overwriting would break state

### `src/<id>/README.md`

The README is the canonical documentation for the feature. Follow the format
generated by `devcontainers/action` — it will be regenerated on publish with
this same structure:

````markdown
# <name> (<id>)

<description>

## Example Usage

```json
"features": {
    "ghcr.io/savvy-web/features/<id>:0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| <optionKey> | <description> | <type> | <default> |

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/savvy-web/devcontainers/blob/main/src/<id>/devcontainer-feature.json). Add additional notes to a `NOTES.md`._
````

Rules:

- Heading is `# <name> (<id>)` — name followed by id in parentheses
- Version in usage snippet uses only the major number (e.g. `0` from `0.1.0`)
- Omit `## Options` entirely if the feature has no options
- If `customizations.vscode.extensions` is set, include a `## Customizations` section
- Place any extra content (examples, OS notes) before the `---` separator,
  or move it to `src/<id>/NOTES.md`
- Omit the table separator row if the feature has no options

### `test/<id>/test.sh`

```bash
#!/usr/bin/env bash
set -e
source dev-container-features-test-lib

check "<binary> is installed" <binary> --version
check "<binary> default version is <default>" bash -c "<binary> --version | grep '<default-version>'"

reportResults
```

Rules:

- `#!/usr/bin/env bash` + `set -e` (NOT `set -euo pipefail` — the test lib uses unset vars)
- `source dev-container-features-test-lib` before any `check` calls
- `check "<LABEL>" <cmd> [args...]` — records pass/fail based on exit code
- For output-content checks, wrap in `bash -c "cmd | grep 'pattern'"`
- `reportResults` at the end
- No network calls, no compilation, no side effects

### `test/<id>/scenarios.json`

```json
{
  "<scenario_name>": {
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
      "<id>": { "<option>": "<value>" }
    }
  }
}
```

Rules:

- Must be a JSON **object** (not array) — keys are scenario names
- Each key must have a matching `test/<id>/<scenario_name>.sh` assertion script
- Use `mcr.microsoft.com/devcontainers/base:ubuntu` as the default base image
- Empty object `{}` means "no scenario variants" — still required as a file

---

## Completion Checklist

Before finishing, confirm every item:

- [ ] `src/<id>/devcontainer-feature.json` created with `documentationURL` → `src/<id>/README.md`
- [ ] `src/<id>/install.sh` created (executable bit is **not** committed; Husky/CI handles it)
- [ ] `src/<id>/README.md` created
- [ ] `test/<id>/test.sh` created
- [ ] `test/<id>/scenarios.json` created
- [ ] `customizations.vscode.settings.github.copilot.chat.codeGeneration.instructions` included
- [ ] `install.sh` starts with `#!/usr/bin/env bash` and `set -euo pipefail`
- [ ] Version in `test.sh` assertion matches the default in `devcontainer-feature.json`
- [ ] All option env var names match the uppercased option key

After all files are created, remind the user to run the validation script:

```bash
pnpm run feature:validate <id>
```

And optionally test locally if `act` is installed:

```bash
pnpm run feature:test <id>
```

## Reference Files

The following references in the `devcontainer` skill directory contain
additional detail:

- `references/feature-anatomy.md` — every `devcontainer-feature.json` field
  and `install.sh` convention with repo examples
- `references/test-patterns.md` — test file structure and CI integration
