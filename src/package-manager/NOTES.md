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