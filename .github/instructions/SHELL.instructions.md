---
applyTo: "**/*.sh"
excludeAgent: "code-review"
---

# Copilot Agent Instructions for Shell Scripts

When the Copilot cloud agent creates or edits any shell script (`*.sh`), it
must follow these conventions without being asked.

## Required Header

Every shell script must start with exactly these two lines:

```bash
#!/usr/bin/env bash
set -euo pipefail
```

No exceptions. `set -euo pipefail` ensures the script exits immediately on
errors, treats unset variables as errors, and propagates pipe failures.

## Env Var Defaults

Always use a defensive default that handles both unset variables and empty
strings injected by the devcontainer CLI:

```bash
# Correct — handles unset and empty string
VERSION="${BIOME_VERSION:-latest}"

# Wrong — only handles unset, not empty string
VERSION="${BIOME_VERSION:?must be set}"
```

## Logging Conventions

Use these prefixes consistently. Error messages must go to stderr.

| Prefix | Destination | When to use |
| :----- | :---------- | :---------- |
| `[INFO]` | stdout | Normal progress steps |
| `[ERROR]` | stderr (`>&2`) | Fatal errors — always followed by `exit 1` |
| `[SUCCESS]` | stdout | Final confirmation of a successful install |
| `[FAIL]` | stderr (`>&2`) | Test assertion failures in `test.sh` |
| `[PASS]` | stdout | Test assertion success in `test.sh` |

## Architecture Detection

Normalize `uname -m` output early. Match the naming convention used by the
upstream download URL:

```bash
ARCH=$(uname -m)
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

# For tools that use "x64" / "arm64":
if [[ "$ARCH" == "x86_64" ]]; then
  ARCH="x64"
elif [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
  ARCH="arm64"
else
  echo "[ERROR] Unsupported architecture: $ARCH" >&2
  exit 1
fi
```

Always include an `else` branch that errors on unsupported architectures.

## Install Validation

Every `install.sh` must end with a validation step that verifies the tool is
on `$PATH` and prints its version:

```bash
if ! command -v <binary> &>/dev/null; then
  echo "[ERROR] <binary> not found in PATH after install." >&2
  exit 1
fi
<binary> --version
```

## Idempotency

Guard installs that would fail or corrupt state on a re-run:

```bash
if ! command -v <tool> >/dev/null 2>&1; then
  echo "[INFO] Installing <tool>..."
  # ... install commands ...
fi
```

For tools installed to a fixed path where overwriting is safe, no guard is
needed.

## Executable Bits

Shell scripts are stored in git **without** the executable bit. Do **not**
run `chmod +x` on any `.sh` file, and do **not** use
`git update-index --chmod=+x`.

Executable bits are managed outside of git:

- **Local dev** — Husky `post-checkout`/`post-merge` hooks apply
  `chmod +x` on all tracked `*.sh` files automatically.
- **CI** — the test and publish workflows set the bits before invoking scripts.

Agents must never treat a missing executable bit as a bug to fix.

## Linting

After editing a shell script, run shellcheck if it is available:

```bash
shellcheck <file>
```

If shellcheck is not installed, note any remaining issues in a comment.
