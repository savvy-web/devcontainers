# Package Manager (corepack)

Installs and configures a Node.js package manager (pnpm, yarn, or npm) via corepack. Supports auto-detection from workspace `package.json`.

## Options

- `packageManager`: Either `'auto'` (read from workspace `package.json`) or a corepack spec like `'pnpm@10.33.2'` or `'pnpm@10.33.2+sha512.<hash>'`. Supported PMs: pnpm, yarn, npm. Default: `auto`

## Usage

Add this feature to your `devcontainer.json`:

```jsonc
{
  "features": {
    "ghcr.io/savvy-web/package-manager:0.1.0": {}
  }
}
```

Requires the `node` feature to be installed first (declared via `installsAfter`).

## Auto-detection

When `packageManager` is `"auto"` (the default), the feature searches the workspace for `package.json` and resolves the package manager spec in this order:

1. `devEngines.packageManager.name` + `devEngines.packageManager.version` — only if `version` is an exact pin (ranges are stripped and, if still ambiguous, skipped)
2. Top-level `packageManager` field — preserves any `+sha512.<hash>` integrity suffix for corepack verification
3. If neither is found, corepack shims are enabled but no specific package manager is activated (soft no-op)
