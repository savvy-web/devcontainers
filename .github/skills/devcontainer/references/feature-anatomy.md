# Feature Anatomy

Dense reference for every `devcontainer-feature.json` field and `install.sh`
convention used in this repository. Examples are drawn from existing features.

## `devcontainer-feature.json` Fields

### Required Fields

| Field | Type | Description |
| :---- | :--- | :---------- |
| `id` | string | Kebab-case identifier, unique within the repo. Used in image names and test paths. |
| `version` | string | Semantic version string (`major.minor.patch`). Start at `0.1.0`. |
| `name` | string | Human-readable display name shown in UIs. |
| `description` | string | One-sentence description of what the feature installs or configures. |

Example:

```json
{
  "id": "biome",
  "version": "0.1.0",
  "name": "Biome (global linter)",
  "description": "Installs Biome globally for all runtimes. Strict version, reproducible, and idempotent."
}
```

### Common Optional Fields

#### `documentationURL`

Always set. Points to the feature's doc page in this repo.

```json
"documentationURL": "https://github.com/savvy-web/devcontainers/blob/main/docs/features/biome.md"
```

#### `options`

Map of option key → option descriptor. Each option becomes an env var in
`install.sh`. The env var name is the option key uppercased with camelCase
boundaries replaced by underscores.

```json
"options": {
  "biomeVersion": {
    "type": "string",
    "default": "2.4.12",
    "description": "Biome version (absolute, no semver ranges)"
  }
}
```

Option key → env var mapping examples:

| Option key | Env var |
| :--------- | :------ |
| `biomeVersion` | `$BIOME_VERSION` |
| `nodeVersion` | `$NODE_VERSION` |
| `blockAll` | `$BLOCK_ALL` |

#### Option Types

| Type | Values | Notes |
| :--- | :----- | :---- |
| `string` | Any string | Use for version strings, paths, comma-separated lists |
| `boolean` | `true` / `false` | Injected as the string `"true"` or `"false"` |
| `integer` | Any integer | Injected as a decimal string |

Always provide a `default`. For version strings, use an absolute version
(`"24.11.0"`), never a semver range (`">=24"` or `"^24"`).

#### `installsAfter`

Array of feature references this feature must run after. Use when your
`install.sh` depends on a binary or directory created by another feature.

```json
"installsAfter": ["ghcr.io/devcontainers/features/common-utils"]
```

Leave as `[]` when there are no ordering dependencies.

#### `platforms`

Array of OS strings. Use `["linux", "darwin"]` for cross-platform tools and
`["linux"]` for Linux-only tools (e.g. iptables-based firewall rules).

```json
"platforms": ["linux", "darwin"]
```

#### `keywords`

Array of lowercase strings for discoverability. Keep to 3–6 terms.

```json
"keywords": ["biome", "linter", "global", "formatter"]
```

#### `customizations.vscode.extensions`

Array of VS Code extension IDs to recommend when the feature is installed.

```json
"customizations": {
  "vscode": {
    "extensions": ["rust-lang.rust-analyzer"]
  }
}
```

Only include extensions that are meaningfully useful for the feature's purpose.

## `install.sh` Conventions

### Shebang and Error Handling

Every install script must start with:

```bash
#!/usr/bin/env bash
set -euo pipefail
```

`set -euo pipefail` ensures the script exits immediately on any error,
treats unset variables as errors, and propagates pipe failures.

### Reading Options

Read each option from its injected env var with a defensive default:

```bash
VERSION="${BIOME_VERSION:-latest}"
```

The devcontainer CLI injects the option value as the uppercased env var name.
The default handles both the case where the CLI does not inject the var and the
case where it injects an empty string.

### Architecture Detection

Use the following pattern to normalize architecture strings for download URLs:

```bash
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
```

### Validation Step

Always end the script by verifying the install succeeded:

```bash
# Verify binary is in PATH
if ! command -v biome &>/dev/null; then
  echo "[ERROR] biome not found in PATH after install." >&2
  exit 1
fi

# Print installed version
biome --version
```

### Logging Conventions

| Prefix | When to use |
| :----- | :---------- |
| `[INFO]` | Normal progress steps |
| `[ERROR]` | Fatal errors (always followed by `exit 1`) |
| `[SUCCESS]` | Final confirmation of a successful install |

Errors go to stderr (`>&2`). Info and success go to stdout.

### User Environment Variables

Feature scripts run as root. The devcontainer CLI injects these variables so
scripts can transfer ownership or run commands as the actual container user:

| Variable | Value |
| :------- | :---- |
| `_REMOTE_USER` | The `remoteUser` setting in `devcontainer.json`. If `remoteUser` is not set, this equals `_CONTAINER_USER`. This is the user VS Code / Codespaces will run as. |
| `_CONTAINER_USER` | The container's user (set via `USER` in the Dockerfile, `user:` in `docker-compose.yml`, or `containerUser` in `devcontainer.json`). |
| `_REMOTE_USER_HOME` | Home directory of `_REMOTE_USER`. |
| `_CONTAINER_USER_HOME` | Home directory of `_CONTAINER_USER`. |

**Use `_REMOTE_USER`** whenever you need to transfer ownership of a directory
so the devcontainer user can write to it (e.g. `RUSTUP_HOME`, `CARGO_HOME`).
Always guard for the unset and root cases:

```bash
REMOTE_USER="${_REMOTE_USER:-}"
if [[ -n "$REMOTE_USER" && "$REMOTE_USER" != "root" ]] && id -u "$REMOTE_USER" &>/dev/null; then
  chown -R "$REMOTE_USER" /some/dir
  echo "[INFO] Transferred ownership to $REMOTE_USER."
fi
```

This guard handles three edge cases:

- `_REMOTE_USER` is unset (container doesn't use feature user env vars)
- `_REMOTE_USER` is `root` (no chown needed; root already owns everything)
- The user account doesn't exist yet at install time (defensive `id -u` check)

For tools that install to system-wide paths owned by root (e.g.
`/usr/local/bin/biome`), no chown is needed — the binary is world-executable.

### Idempotency Guard

When re-running the installer would break an existing installation, guard it:

```bash
if ! command -v rustup >/dev/null 2>&1; then
  echo "[INFO] Installing rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
```

For tools installed to a fixed path (e.g. `/usr/local/bin/biome`), overwriting
is safe; no guard is needed.

## Full Example: `devcontainer-feature.json`

The `package-manager` feature demonstrates all common fields:

```json
{
  "id": "package-manager",
  "version": "0.1.0",
  "name": "Package Manager (corepack)",
  "description": "Installs and configures a Node.js package manager (pnpm, yarn, or npm) via corepack.",
  "documentationURL": "https://github.com/savvy-web/devcontainers/blob/main/docs/features/package-manager.md",
  "options": {
    "packageManager": {
      "type": "string",
      "default": "auto",
      "description": "Either 'auto' or a corepack spec like 'pnpm@10.33.2'"
    }
  },
  "installsAfter": ["ghcr.io/savvy-web/node"],
  "platforms": ["linux"],
  "keywords": ["corepack", "pnpm", "yarn", "npm", "package-manager"]
}
```
