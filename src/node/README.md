# Node.js (node)

Installs and configures the Node.js runtime globally.

## Example Usage

```json
"features": {
    "ghcr.io/savvy-web/features/node:0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| nodeVersion | The version of Node.js to install. Must be an absolute version (e.g. 24.11.0); semver ranges are not supported. | string | 24.11.0 |
