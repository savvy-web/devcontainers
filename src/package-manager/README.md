# Package Manager (corepack) (package-manager)

Installs and configures a Node.js package manager (pnpm, yarn, or npm) via corepack. Supports auto-detection from workspace package.json.

## Example Usage

```json
"features": {
    "ghcr.io/savvy-web/package-manager:0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| packageManager | Either 'auto' (read from workspace package.json) or a corepack spec like 'pnpm@10.33.2' or 'pnpm@10.33.2+sha512.{hash}'. Supported PMs: pnpm, yarn, npm. | string | auto |

## Auto-Detection

When `packageManager` is `"auto"` (the default), the feature searches the workspace
for `package.json` and resolves the package manager spec in this order:

1. `devEngines.packageManager.name` + `devEngines.packageManager.version` — only
   if `version` is an exact pin (ranges are stripped and, if still ambiguous, skipped)
2. Top-level `packageManager` field — preserves any `+sha512.<hash>` integrity
   suffix for corepack verification
3. If neither is found, corepack shims are enabled but no specific package manager
   is activated (soft no-op)

Requires the `node` feature to be installed first (declared via `installsAfter`).

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/savvy-web/devcontainers/blob/main/src/package-manager/devcontainer-feature.json). Add additional notes to a `NOTES.md`._
