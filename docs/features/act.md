# act (local GitHub Actions runner)

Installs [act](https://nektosact.com) by nektos for running GitHub Actions workflows locally with Docker.

## Options

- `actVersion`: act version to install (absolute, no semver ranges). Default: `0.2.76`

## Usage

Add this feature to your `devcontainer.json` to install act globally.

```jsonc
{
  "features": {
    "ghcr.io/savvy-web/act:0.1.0": {}
  }
}
```
