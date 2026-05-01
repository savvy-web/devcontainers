# Node.js

Installs and configures the Node.js runtime globally. Includes npm, npx, and corepack.

## Options

- `nodeVersion`: The version of Node.js to install. Must be an absolute version (e.g. `24.11.0`); semver ranges are not supported. Default: `24.11.0`

## Usage

Add this feature to your `devcontainer.json`:

```jsonc
{
  "features": {
    "ghcr.io/savvy-web/node:0.1.0": {}
  }
}
```
