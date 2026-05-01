# Common Failure Modes

Diagnostic patterns and canonical fixes for devcontainer feature failures.
Each section covers one failure category: how to detect it, why it happens,
and the exact fix.

---

## 1. Env Var Not Injected

### Detection

- Script exits with a message like `"invalid version string"` or
  `"file not found"` that points to an empty value
- Running `bash -x install.sh` shows `VERSION=` with an empty right-hand side
- The option key in `devcontainer-feature.json` does not match the env var
  name read in `install.sh`

### Why it happens

The devcontainer CLI uppercases the option key and injects it as an env var.
A camelCase key like `biomeVersion` becomes `BIOME_VERSION`. If `install.sh`
reads `$BIOMEVERSION` (no underscore) or `$biomeVersion` (lowercase), the
value is never set.

The CLI may also inject an empty string (`""`) rather than leaving the var
unset. Scripts that test with `[[ -z "$VAR" ]]` will catch this, but scripts
that rely on bash's `${VAR:?}` unset-error will not fail correctly.

### Fix

1. Verify the env var name in `install.sh` matches the option key uppercased:

   | Option key | Correct env var | Wrong |
   | :--------- | :-------------- | :---- |
   | `biomeVersion` | `$BIOME_VERSION` | `$BIOMEVERSION` |
   | `nodeVersion` | `$NODE_VERSION` | `$node_version` |
   | `blockAll` | `$BLOCK_ALL` | `$BLOCKALL` |

2. Always use a defensive default that handles both unset and empty-string:

   ```bash
   # Wrong — fails if CLI injects ""
   VERSION="${BIOME_VERSION:?BIOME_VERSION is required}"

   # Correct — handles both unset and ""
   VERSION="${BIOME_VERSION:-latest}"
   ```

---

## 2. Architecture Mismatch

### Detection

- Error like `"cannot execute binary file"` or `"Exec format error"`
- Download URL contains `x86_64` when running on `arm64` (or vice versa)
- `bash -x install.sh` shows `ARCH=aarch64` but URL contains `x64`

### Why it happens

`uname -m` returns different strings on different platforms:

| Platform | `uname -m` output |
| :------- | :---------------- |
| Intel/AMD 64-bit | `x86_64` |
| Apple Silicon / ARM 64-bit | `arm64` (macOS) or `aarch64` (Linux) |

Upstream tools use inconsistent naming. Some use `x64`/`arm64`, others use
`amd64`/`aarch64`, and others use `x86_64`/`aarch64`.

### Fix

Normalize `uname -m` output early in the script and match the format the
upstream URL expects:

```bash
ARCH=$(uname -m)

# For tools that use "x64" / "arm64":
if [[ "$ARCH" == "x86_64" ]]; then
  ARCH="x64"
elif [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
  ARCH="arm64"
else
  echo "[ERROR] Unsupported architecture: $ARCH" >&2
  exit 1
fi

# For tools that use "amd64" / "arm64":
if [[ "$ARCH" == "x86_64" ]]; then
  ARCH="amd64"
elif [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
  ARCH="arm64"
fi
```

Always include an `else` branch that errors on unsupported architectures.

---

## 3. Broken Download URL

### Detection

- `curl: (22) The requested URL returned error: 404`
- `curl: (22) The requested URL returned error: 403`
- `gunzip: stdin: not in gzip format` (got HTML error page instead of binary)

### Why it happens

- The upstream release naming convention changed (e.g. they started using `v`
  prefix in the tarball filename)
- The version string passed to the URL includes a `v` prefix when the URL
  expects a bare version (or vice versa)
- The GitHub API returns a `tag_name` like `@biomejs/biome/2.4.12` — the
  script must strip the package prefix

### Fix

1. Test the URL manually:

   ```bash
   curl -fI "https://example.com/releases/v1.0.0/tool-linux-x64.tar.gz"
   ```

2. Check the upstream release page for the exact filename pattern.

3. Strip `v` prefixes consistently:

   ```bash
   # Strip leading "v" from tag name (e.g. "v2.4.12" -> "2.4.12"):
   VERSION=$(echo "$TAG" | sed 's/^v//')

   # For Biome, the tag uses @scope/package@version format:
   VERSION=$(curl -fsSL https://api.github.com/repos/biomejs/biome/releases/latest \
     | grep '"tag_name"' \
     | sed -E 's/.*"([^"]+)".*/\1/' \
     | sed 's/^@biomejs\/biome\///' \
     | sed 's/^v//')
   ```

4. Verify the constructed URL before downloading:

   ```bash
   echo "[INFO] Downloading from: $URL"
   curl -fsSL "$URL" | ...
   ```

---

## 4. Execute Permission on Installed Binaries

### Detection

- Error: `"Permission denied"` when running a binary the feature installed
  (e.g. `/usr/local/bin/biome`)
- `ls -la /usr/local/bin/<binary>` shows `-rw-r--r--` (no `x` bit)

### Why it happens

The feature's `install.sh` downloaded or copied a binary but did not mark it
executable with `chmod +x`.

### Fix

Add `chmod +x` or use `install -m 0755` in `install.sh` when placing the
binary:

```bash
chmod +x "$BINARY_PATH"
# or
install -m 0755 "$TMP/binary" /usr/local/bin/binary
```

**Note:** this is about the *installed binary*, not `install.sh` itself.
`install.sh` and all other `*.sh` files in the repository are stored **without**
the executable bit in git (`100644`). The Husky `post-checkout`/`post-merge`
hooks set the bit locally; CI workflows set it before running the scripts.
Never run `chmod +x src/<id>/install.sh` or
`git update-index --chmod=+x src/<id>/install.sh`.

---

## 5. Silent Failure from Missing `set -euo pipefail`

### Detection

- Script exits `0` but the tool is not installed
- Script output shows an error message but continues running
- A step after the failing step also fails, with a confusing error

### Why it happens

Without `set -euo pipefail`:

- `set -e` — commands that fail do not abort the script
- `set -u` — references to unset variables are silently treated as empty
- `set -o pipefail` — the exit code of a pipeline is the last command's exit
  code, so a failing `curl | gunzip` reports the exit code of `gunzip`, not
  the `curl` failure

### Fix

Add to the first two lines after the shebang:

```bash
#!/usr/bin/env bash
set -euo pipefail
```

---

## 6. Idempotency Failure

### Detection

- Running `install.sh` a second time exits non-zero
- Error like `"cannot open shared object file"` or `"already exists"`
- The second run leaves the tool in a broken state

### Why it happens

Some installers (e.g. `rustup init`) refuse to run if a previous install
exists. Others overwrite a running binary that is locked. Others append to
PATH files, causing duplicates.

### Fix

Guard installs that would fail or break on a re-run:

```bash
if ! command -v rustup >/dev/null 2>&1; then
  echo "[INFO] Installing rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
else
  echo "[INFO] rustup already installed, skipping."
fi
```

For directory-based installs, remove and recreate:

```bash
# Safe to overwrite — remove old dir first
sudo rm -rf "$ZIG_ROOT"
sudo mkdir -p "$ZIG_ROOT"
sudo cp -r "$ZIG_EXTRACTED"/* "$ZIG_ROOT"/
```

---

## 7. Version Assertion Mismatch in `test.sh`

### Detection

- Test output: `[FAIL] <binary> version mismatch`
- `bash -x test/<id>/test.sh` shows the grep pattern does not match
  the binary's actual version output

### Why it happens

The most common causes:

1. The feature's option default was updated in `devcontainer-feature.json` but
   the `grep` pattern in `test.sh` was not updated
2. The binary's `--version` output format changed (e.g. `biome 2.4.12` vs
   `biome/2.4.12`)
3. The version string in `test.sh` has a typo or extra space

### Fix

1. Verify the binary's actual version output format:

   ```bash
   <binary> --version
   ```

2. Check the default in `devcontainer-feature.json`:

   ```json
   "default": "2.4.12"
   ```

3. Update `test.sh` to match:

   ```bash
   biome --version | grep "2.4.12" \
     || { echo "[FAIL] Biome version mismatch" >&2; exit 1; }
   ```

If you changed the default version, use the `bump-feature` skill to update
all version references atomically.

---

## 8. Missing `installsAfter`

### Detection

- A feature's `install.sh` fails because a binary it depends on (e.g. `node`
  or `npm`) is not on `$PATH`
- The failure happens consistently when consumed alongside a dependency
  feature, but the script runs fine in isolation

### Why it happens

Devcontainer features are installed in arbitrary order unless the dependent
feature declares `installsAfter`. If a feature shells out to another
feature's binaries during install, it must declare that ordering dependency
explicitly — directory layout no longer encodes scope.

### Fix

Add the dependency feature to `installsAfter` in
`src/<id>/devcontainer-feature.json`:

```json
"installsAfter": ["ghcr.io/savvy-web/node"]
```

Then bump the feature version using the `bump-feature` skill, since
`installsAfter` changes count as a behavior change.

---

## 9. Docker / act Not Available Locally

### Detection

- `pnpm run test:feature` exits with `"act is not installed"`
- `docker: command not found`

### Fix

Install act using the devcontainer feature:

```jsonc
// .devcontainer/devcontainer.json
{
  "features": {
    "ghcr.io/savvy-web/act:0.1.0": {}
  }
}
```

Or install Docker Desktop / Rancher Desktop locally and install act via the
[act installation guide](https://nektosact.com/installation/index.html).
