# Outbound Firewall

Configures outbound firewall rules for Codespaces and devcontainers.

## Options

- `blockAll`: Block all outbound traffic except allowlist. Default: `false`
- `allowlist`: Comma-separated list of allowed domains or IPs. Default: `""`

## Usage

Add this feature to your `devcontainer.json` to configure outbound firewall rules.
