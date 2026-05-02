# Bun Runtime

Installs the Bun JavaScript runtime globally.

## Options

- `bunVersion`: Bun version to install (e.g., 1.3.13). Default: `1.3.13`

## Usage

Add this feature to your `devcontainer.json`:

```jsonc
{
  "features": {
    "ghcr.io/savvy-web/bun:0.1.0": {}
  }
}
```

## Example

Pin a specific version:

```jsonc
{
  "features": {
    "ghcr.io/savvy-web/bun:0.1.0": {
      "bunVersion": "1.2.0"
    }
  }
}
```
