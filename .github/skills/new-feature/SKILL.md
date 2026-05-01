---
name: new-feature
allowed-tools: read_file, write_file, list_files, fetch
description: >-
  Use when asked to create a new devcontainer feature in this repository.
  Triggers for prompts like "add a feature for X", "create a new feature",
  "scaffold a feature", or "add X to the devcontainer features".
---

# New Devcontainer Feature Scaffold

Creates all five required files for a new devcontainer feature in one guided
session. Every feature must have exactly these files — missing any one of them
will cause CI or publishing to fail.

## Required Files

| File | Purpose |
| :--- | :------ |
| `src/<id>/devcontainer-feature.json` | Feature metadata and options |
| `src/<id>/install.sh` | Installation script |
| `test/<id>/test.sh` | Post-install assertions |
| `test/<id>/scenarios.json` | Human-readable scenario descriptions |
| `docs/features/<id>.md` | End-user documentation |

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

### Step 3 — Generate all five files

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
  "documentationURL": "https://github.com/savvy-web/devcontainers/blob/main/docs/features/<id>.md",
  "options": {
    "<optionKey>": {
      "type": "string",
      "default": "<absolute-version>",
      "description": "<description>"
    }
  },
  "installsAfter": [],
  "platforms": ["linux", "darwin"],
  "keywords": ["<keyword1>", "<keyword2>"]
}
```

Rules:

- Always start at `"version": "0.1.0"`
- `documentationURL` must match the `docs/features/<id>.md` path exactly
- `options` — omit the field entirely if the feature has no options
- `installsAfter` — omit or set to `[]` when empty; never set to `null`
- `platforms` — use `["linux"]` for features that use Linux-specific
  kernel interfaces (iptables, nftables, systemd services)
- `keywords` — 3–6 lowercase, space-free strings

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

### `test/\<id>/test.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

# Test: <Feature name>
<binary> --version | grep "<expected-version>" \
  || { echo "[FAIL] <binary> version mismatch" >&2; exit 1; }

echo "[PASS] <Feature name> test passed."
```

Rules:

- `#!/usr/bin/env bash` + `set -euo pipefail`
- Assert binary exists in `$PATH`
- Assert version output matches the exact default version from `devcontainer-feature.json`
- Use `grep "<version>"` not `== "<version>"` (version output formats vary)
- One assertion per binary or key property
- `[PASS]` at the end — CI logs scan for this marker
- No network calls, no compilation, no side effects

### `test/\<id>/scenarios.json`

```json
[
  {
    "name": "<Feature name> install",
    "steps": [
      "Install feature",
      "Check <binary> version is <default>"
    ]
  }
]
```

Rules:

- At least one scenario
- `name` — short, title-case
- `steps` — mirrors the assertions in `test.sh`
- This file is not executed; it is documentation for human reviewers

### `docs/features/\<id>.md`

The doc file must follow this structure:

```text
# <name>

<description>

## Options

- `<optionKey>`: <option description>. Default: `<default>`

## Usage

Add this feature to your `devcontainer.json`:

    ```jsonc
    {
      "features": {
        "ghcr.io/savvy-web/<id>:0.1.0": {}
      }
    }
    ```
```

Rules:

- One `#` heading equal to the `name` field — no subtitle
- `## Options` section — one bullet per option; omit entirely if no options
- `## Usage` section — always include; use `jsonc` fenced block
- `## Example` — optional; include only when a non-default option combination
  meaningfully changes behavior
- 12–18 lines total; match the brevity of `docs/features/biome.md`
- Direct imperative voice; no marketing language

---

## Completion Checklist

Before finishing, confirm every item:

- [ ] `src/<id>/devcontainer-feature.json` created
- [ ] `src/<id>/install.sh` created (executable bit is **not** committed; Husky/CI handles it)
- [ ] `test/<id>/test.sh` created
- [ ] `test/<id>/scenarios.json` created
- [ ] `docs/features/<id>.md` created
- [ ] `documentationURL` in JSON matches the doc path exactly
- [ ] `install.sh` starts with `#!/usr/bin/env bash` and `set -euo pipefail`
- [ ] Version in `test.sh` assertion matches the default in `devcontainer-feature.json`
- [ ] All option env var names match the uppercased option key

After all files are created, remind the user to run the validation script:

```bash
pnpm run validate-feature <id>
```

And optionally test locally if `act` is installed:

```bash
pnpm run test:feature <id>
```

## Reference Files

The following references in the `devcontainer` skill directory contain
additional detail:

- `references/feature-anatomy.md` — every `devcontainer-feature.json` field
  and `install.sh` convention with repo examples
- `references/test-patterns.md` — test file structure and CI integration
- `references/doc-template.md` — documentation template and writing rules
