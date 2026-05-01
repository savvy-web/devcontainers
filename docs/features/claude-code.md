# Claude Code Agent (Global)

Installs the Claude Code CLI agent globally using the official native installer
(`curl -fsSL https://claude.ai/install.sh | bash`). Does not require Node.js or
npm — the pre-built binary is downloaded and placed on `PATH` for all users.

## Usage

Add this feature to your `devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/savvy-web/claude-code:0": {}
  }
}
```

After the container starts, run `claude` to launch the agent.
