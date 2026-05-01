# bats (Bash Automated Testing System)

Installs bats-core, bats-support, bats-assert, and bats-mock for shell script testing.

## Options

- `batsVersion`: bats-core version to install. Accepts with or without a leading `v`. Default: `1.13.0`
- `batsSupportVersion`: bats-support version to install. Accepts with or without a leading `v`. Default: `0.3.0`
- `batsAssertVersion`: bats-assert version to install. Accepts with or without a leading `v`. Default: `2.2.4`
- `batsMockVersion`: bats-mock version to install. Accepts with or without a leading `v`. Default: `1.2.5`

## Usage

Add this feature to your `devcontainer.json` to install bats and its support libraries.

```jsonc
{
  "features": {
    "ghcr.io/savvy-web/bats:0.1.0": {}
  }
}
```

## Example

Use with kcov for coverage collection:

```jsonc
{
  "features": {
    "ghcr.io/savvy-web/kcov:0.1.0": {},
    "ghcr.io/savvy-web/bats:0.1.0": {}
  }
}
```
