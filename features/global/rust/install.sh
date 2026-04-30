#!/usr/bin/env bash
set -euo pipefail
RUST_VERSION=${RUST_VERSION:-stable}
COMPONENTS=${COMPONENTS:-clippy,rustfmt}

# Install rustup if not present
if ! command -v rustup >/dev/null 2>&1; then
  echo "[INFO] Installing rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  export PATH="$HOME/.cargo/bin:$PATH"
fi

# Install toolchain
rustup toolchain install "$RUST_VERSION"
rustup default "$RUST_VERSION"

# Install components
IFS="," read -ra COMPS <<< "$COMPONENTS"
for comp in "${COMPS[@]}"; do
  rustup component add "$comp" || true
  echo "[INFO] Installed component: $comp"
done

# Validate install
rustc --version
cargo --version

echo "[SUCCESS] Rust toolchain ($RUST_VERSION) and components installed."
