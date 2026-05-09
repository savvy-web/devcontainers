# Rust Toolchain (Global) (rust)

Installs the Rust toolchain globally using rustup. Supports toolchain selection, component install, and validation.

## Example Usage

```json
"features": {
    "ghcr.io/savvy-web/features/rust:0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| toolchain | Rust toolchain to install (e.g. stable, nightly, 1.77.2) | string | stable |
| components | Space-separated list of rustup components to install | string | clippy rustfmt |
