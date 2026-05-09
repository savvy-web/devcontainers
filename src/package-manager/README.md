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
