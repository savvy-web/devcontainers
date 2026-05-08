# kcov (kcov)

Builds and installs kcov from source for shell script and binary code coverage.

## Example Usage

```json
"features": {
    "ghcr.io/savvy-web/kcov:0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| kcovVersion | kcov version to install. Accepts with or without a leading 'v' (e.g. '43' or 'v43'). Use 'latest' to auto-detect the latest stable release. | string | 43 |

## Pinning a Version

To pin to a specific stable release, pass the version number explicitly:

```json
"features": {
    "ghcr.io/savvy-web/kcov:0": {
        "kcovVersion": "42"
    }
}
```

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/savvy-web/devcontainers/blob/main/src/kcov/devcontainer-feature.json). Add additional notes to a `NOTES.md`._
