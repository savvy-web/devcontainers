# Deno Runtime

Installs the Deno JavaScript and TypeScript runtime globally.

## Options

- `denoVersion`: Deno version to install (e.g., 2.7.14). Default: `2.7.14`

## Usage

Add this feature to your `devcontainer.json`:

```jsonc
{
  "features": {
    "ghcr.io/savvy-web/deno:0.1.0": {}
  }
}
```

## Example

Pin a specific version:

```jsonc
{
  "features": {
    "ghcr.io/savvy-web/deno:0.1.0": {
      "denoVersion": "2.6.0"
    }
  }
}
```
