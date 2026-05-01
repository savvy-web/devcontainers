# Test Patterns

Reference for the two-file test convention used in this repository:
`test.sh` and `scenarios.json`.

## File Locations

Tests live alongside the feature they cover, mirroring the flat `features/`
directory structure:

```text
test/
  <id>/
    test.sh        # executable shell assertions
    scenarios.json # human-readable scenario descriptions
```

Both files are required. The CI publish workflow discovers tests by resolving
`test/<id>/test.sh` from the feature id.

## `scenarios.json`

An array of scenario objects. Each object describes one logical test scenario.

### Schema

```json
[
  {
    "name": "Human-readable scenario name",
    "steps": [
      "Step one description",
      "Step two description"
    ]
  }
]
```

### Rules

- At least one scenario per feature
- `name` — short, title-case, describes what the scenario verifies
- `steps` — ordered list of what the test checks; mirrors the assertions in
  `test.sh`
- Not executed by CI — this file is documentation and a checklist for humans
  reviewing the test

### Example

```json
[
  {
    "name": "Biome global install",
    "steps": ["Install feature", "Check Biome version is 2.4.12"]
  }
]
```

## `test.sh`

An executable Bash script that runs assertions after the feature is installed
in the devcontainer.

### Structure

```bash
#!/usr/bin/env bash
set -euo pipefail

# Assertion 1: binary is in PATH
<binary> --version || { echo "[FAIL] <binary> not found" >&2; exit 1; }

# Assertion 2: version matches the pinned default
<binary> --version | grep "<expected-version>" \
  || { echo "[FAIL] <binary> version mismatch" >&2; exit 1; }

echo "[PASS] <Feature name> test passed."
```

### Rules

- `#!/usr/bin/env bash` + `set -euo pipefail` — same as `install.sh`
- One assertion per binary or property to verify
- Use `|| { echo "[FAIL] <message>" >&2; exit 1; }` to emit a clear failure
  message before exiting
- Print `[PASS]` at the end so CI logs show a clear success marker
- Version assertions must use `grep` against the exact default version string
  defined in `devcontainer-feature.json`
- Keep tests fast — no network calls, no compilation, no side effects

### What to Test

| Check | Example assertion |
| :---- | :---------------- |
| Binary exists in `$PATH` | `command -v biome` or `biome --version` |
| Version matches pinned default | `biome --version \| grep "2.4.12"` |
| Key subcommand available | `cargo --version`, `rustc --version` |

### What Not to Test

- Full functional behavior (e.g. linting a real file, compiling code)
- Network connectivity or registry access
- Side effects of options other than the default

Functional tests belong in integration test suites, not in feature tests.
Keep feature tests hermetic and fast.

### Example: Biome

```bash
#!/usr/bin/env bash
set -euo pipefail

# Test: Biome global install
biome --version | grep "2.3.14" || { echo "[FAIL] Biome version mismatch" >&2; exit 1; }
echo "[PASS] Biome global install test passed."
```

### Example: Rust (multiple binaries)

```bash
#!/usr/bin/env bash
set -euo pipefail

# Test: Rust toolchain install
rustc --version || { echo "[FAIL] rustc not found" >&2; exit 1; }
cargo --version || { echo "[FAIL] cargo not found" >&2; exit 1; }
echo "[PASS] Rust toolchain install test passed."
```

## CI Integration

The `.github/workflows/publish.yml` workflow runs tests as follows:

1. **`collect`** job — `collect-and-filter-features.js` builds a JSON matrix
   of features not yet published at their current version
2. **`test`** job — fan-out matrix job that runs
   `test/<id>/test.sh` for each feature in the matrix
3. Result is written to `/tmp/results/<id>.txt` as `success` or
   `failure` and uploaded as an artifact named `test-result-<id>`
4. **`summarize`** job — downloads all result artifacts, writes a Markdown
   table to `$GITHUB_STEP_SUMMARY`, and fails (blocking publish) if any test
   failed

### Implications for Test Authors

- A non-zero exit code from `test.sh` is treated as a test failure
- The test script runs inside the devcontainer that has the feature installed
- There is no test framework — plain Bash assertions with `exit 1` on failure
- The test must be self-contained; it cannot rely on files from the repo
  unless they are copied in as part of the feature install

## Local Testing with act

The repo provides a dedicated workflow and wrapper script for running a single
feature's install + test cycle locally using
[act](https://nektosact.com).

### Prerequisites

- Docker running locally
- `act` installed — add `ghcr.io/savvy-web/act:0.1.0` to your
  `devcontainer.json`, or install via the
  [act installation guide](https://nektosact.com/installation/index.html)

### Running a single feature test

```bash
pnpm run test:feature biome
pnpm run test:feature rust
pnpm run test:feature package-manager
```

Running without arguments prints available features.

### How it works

`scripts/test-feature.sh` calls `act workflow_dispatch` targeting
`.github/workflows/test-feature.yml` — a minimal workflow that:

1. Checks out the repo (using the local bind-mount from `.actrc`)
2. Runs `features/<id>/install.sh` inside a fresh ubuntu container
3. Runs `test/<id>/test.sh` in the same container

The `.actrc` at the repo root configures act to:

- Use `catthehacker/ubuntu:act-latest` as the ubuntu-latest runner image
- Bind-mount the local workspace (no network clone, much faster)
- Remove the container after each run (`--rm`)

### Debugging a failing test

If `test.sh` fails, re-run with act's verbose flag to see the full output:

```bash
act workflow_dispatch \
  --input id=biome \
  -W .github/workflows/test-feature.yml \
  --verbose
```
