#!/usr/bin/env bash
set -euo pipefail

TOOLCHAIN="${TOOLCHAIN:-stable}"
COMPONENTS="${COMPONENTS:-clippy rustfmt}"

export RUSTUP_HOME=/usr/local/rustup
export CARGO_HOME=/usr/local/cargo
export PATH="$CARGO_HOME/bin:$PATH"

# Install rustup if not present
if ! command -v rustup >/dev/null 2>&1; then
  echo "[INFO] Installing rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
fi

# Install toolchain
rustup toolchain install "$TOOLCHAIN"
rustup default "$TOOLCHAIN"

# Install components (support both space- and comma-separated for compatibility)
COMPONENTS_NORMALIZED="${COMPONENTS//,/ }"
IFS=" " read -ra COMPS <<< "$COMPONENTS_NORMALIZED"
for comp in "${COMPS[@]}"; do
  [[ -z "$comp" ]] && continue
  rustup component add "$comp" || true
  echo "[INFO] Installed component: $comp"
done

# Symlink binaries to /usr/local/bin for system-wide availability
for bin in rustc cargo rustup; do
  if [[ -f "$CARGO_HOME/bin/$bin" ]]; then
    ln -sf "$CARGO_HOME/bin/$bin" "/usr/local/bin/$bin"
  fi
done

# Persist environment variables for interactive shells
cat > /etc/profile.d/rust.sh <<'EOF'
export RUSTUP_HOME=/usr/local/rustup
export CARGO_HOME=/usr/local/cargo
export PATH=/usr/local/cargo/bin:${PATH}
EOF

# Validate install
if ! command -v rustc &>/dev/null; then
  echo "[ERROR] rustc not found in PATH after install." >&2
  exit 1
fi
rustc --version
cargo --version

# Transfer ownership of toolchain directories to the remote user so they can
# run `cargo install` and `rustup` without elevated privileges in Codespaces
# and VS Code Dev Containers.
REMOTE_USER="${_REMOTE_USER:-}"
if [[ -n "$REMOTE_USER" && "$REMOTE_USER" != "root" ]] && id -u "$REMOTE_USER" &>/dev/null; then
  chown -R "${REMOTE_USER}" "${RUSTUP_HOME}" "${CARGO_HOME}"
  echo "[INFO] Transferred toolchain ownership to ${REMOTE_USER}."
fi

echo "[SUCCESS] Rust toolchain ($TOOLCHAIN) and components installed."
