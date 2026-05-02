# kcov

Builds and installs kcov from source for shell script and binary code coverage.

## Options

- `kcovVersion`: kcov version to install. Accepts with or without a leading `v` (e.g. `43` or `v43`).
  Use `latest` to auto-detect the latest stable release. Default: `43`

## Usage

Add this feature to your `devcontainer.json` to install kcov.

```jsonc
{
  "features": {
    "ghcr.io/savvy-web/kcov:0.1.0": {}
  }
}
```

## Example

Pin to a specific stable release:

```jsonc
{
  "features": {
    "ghcr.io/savvy-web/kcov:0.1.0": {
      "kcovVersion": "42"
    }
  }
}
```
