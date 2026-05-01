---
name: debug-feature
allowed-tools: read_file, write_file, list_files, fetch
description: >-
  Use when a devcontainer feature's install.sh is failing, a test is failing,
  or a feature is not behaving as expected. Triggers for prompts like "my
  feature install fails", "the test is failing for X", "install.sh exits
  with an error", or "why is my feature not working".
---

# Debug Devcontainer Feature

Systematic triage guide for diagnosing failing `install.sh` scripts,
`test.sh` assertions, and publish workflow errors.

## When to Use

Use this skill when:

- `install.sh` exits with a non-zero code during `pnpm run test:feature`
- A `test.sh` assertion fails (`[FAIL]` in output or non-zero exit)
- The publish workflow's `test` job fails
- A feature installs successfully locally but fails in CI
- A feature behaves differently across architectures or OS versions

## Triage Workflow

### Step 1 — Read the full error output

Ask the user for the full error log if not provided. The most useful output
comes from running the feature with verbose logging:

```bash
act workflow_dispatch \
  --input id=<id> \
  -W .github/workflows/test-feature.yml \
  --verbose
```

Or, to see the raw install script output:

```bash
bash -x src/<id>/install.sh
```

`-x` traces every command and its expanded arguments — essential for
diagnosing variable substitution bugs.

### Step 2 — Classify the failure

Read `references/common-failure-modes.md` and match the error to a category.

The most common failure categories, in order of frequency:

1. **Env var not injected** — option value is empty or unset
2. **Architecture mismatch** — wrong binary for the platform
3. **Broken download URL** — upstream URL pattern changed or version not found
4. **Missing `set -euo pipefail`** — silent failures masked by `|| true`
5. **Idempotency failure** — re-running the script breaks an existing install
6. **Version assertion mismatch** — `test.sh` checks a different version than
   the default in `devcontainer-feature.json`
7. **Missing `installsAfter`** — the feature depends on another feature
   (e.g. Node.js) being installed first but does not declare it

### Step 3 — Apply the fix

For each category, the `references/common-failure-modes.md` file contains
the exact diagnostic check and the canonical fix pattern.

### Step 4 — Verify

After applying a fix:

1. Run the feature locally with act:

   ```bash
   pnpm run test:feature <id>
   ```

2. Run the validation script to catch any remaining structural issues:

   ```bash
   pnpm run validate-feature <id>
   ```

3. If the failure was a version mismatch, bump the feature version using the
   `bump-feature` skill.

---

## Diagnostic Questions

If the error is not immediately obvious, work through these questions:

**Env var injection:**

- Does every option in `devcontainer-feature.json` have a matching env var
  default in `install.sh`? (`BIOME_VERSION="${BIOME_VERSION:-latest}"`)
- Is the env var name exactly the option key uppercased
  (`biomeVersion` → `$BIOME_VERSION`, not `$BIOMEVERSION`)?

**Download URL:**

- Does the URL exist? Run `curl -fI "<url>"` to check.
- Has the upstream release naming convention changed? Check the latest
  release on the upstream GitHub repo.
- Is the version string included literally in the URL, or does the script
  strip a leading `v`?

**Architecture:**

- Does the script handle both `x86_64` (→ `x64`) and `aarch64`/`arm64`
  (→ `arm64`) correctly?
- Does the download URL use `x64`/`arm64`, `x86_64`/`aarch64`, or
  `amd64`/`arm64`? Match the URL format exactly.

**Install validation:**

- Does the script end with `command -v <binary>` or `<binary> --version`?
- If the binary is installed to a non-standard path, is that path on `$PATH`?
- Is the binary installed with execute permission (`chmod +x` on the installed binary in `/usr/local/bin`, not the `install.sh` source file)?

**Idempotency:**

- Does running `install.sh` a second time exit cleanly?
- Does the idempotency guard check the right condition? (`command -v`,
  directory existence, or file existence depending on the tool)

**Test assertions:**

- Does the version string in `grep "<version>"` exactly match the `default`
  in the corresponding option in `devcontainer-feature.json`?
- Does the binary's `--version` output include the version string in the
  format being grepped?

## Bundled Reference Files

- `references/common-failure-modes.md` — failure patterns, diagnostic
  commands, and canonical fixes for each failure category
