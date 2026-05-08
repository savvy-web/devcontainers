# Node.js (node)

Installs and configures the Node.js runtime globally.

## Example Usage

```json
"features": {
    "ghcr.io/savvy-web/node:0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| nodeVersion | The version of Node.js to install. Must be an absolute version (e.g. 24.11.0); semver ranges are not supported. | string | 24.11.0 |

## Included Tools

Node.js is installed with npm, npx, and corepack available on the PATH.

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/savvy-web/devcontainers/blob/main/src/node/devcontainer-feature.json). Add additional notes to a `NOTES.md`._
