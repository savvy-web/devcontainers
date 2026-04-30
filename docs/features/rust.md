# Rust Toolchain (Global)

Installs the Rust toolchain globally using rustup. Supports toolchain selection, component install, and validation.

## Options

- `toolchain`: Rust toolchain to install (e.g. stable, nightly, 1.77.2). Default: `stable`
- `components`: Space-separated list of rustup components to install. Default: `clippy rustfmt`

## Usage

Add this feature to your `devcontainer.json` to install the Rust toolchain globally.
