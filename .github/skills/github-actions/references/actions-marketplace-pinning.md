# Third-Party Actions: Pinning and Dependabot

Using a third-party action at a mutable tag (`@v3`, `@latest`) means a
compromised tag can execute arbitrary code in your workflow. Pin to an immutable
commit SHA instead, and let Dependabot rotate the pin automatically.

Docs:
[Security hardening — using SHA pinning](https://docs.github.com/en/actions/concepts/security/supply-chain-security#using-sha-pinning)

---

## How to find the SHA for a tag

1. Open the action's repository on GitHub (e.g. `github.com/actions/checkout`).
2. Click the **Tags** tab and find the tag you want (e.g. `v4.1.1`).
3. Click the tag → copy the full 40-character commit SHA from the URL or the
   commit header.
4. Use that SHA in your workflow with the tag as a human-readable comment:

```yaml
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.1.1
```

---

## `permissions` block to pair with third-party actions

Grant the minimum permissions required and nothing more. For actions that only
read code:

```yaml
permissions:
  contents: read
```

For actions that publish packages, create releases, or write to the repo:

```yaml
permissions:
  contents: write
  packages: write
```

For actions that need OIDC (cloud deployments):

```yaml
permissions:
  id-token: write
  contents: read
```

Always set `permissions` at the top-level workflow to `read-all` as a default,
then override per job.

Docs:
[Permissions for the GITHUB\_TOKEN](https://docs.github.com/en/actions/reference/security/automatic-token-authentication#permissions-for-the-github_token)

---

## Dependabot configuration to auto-update pinned SHAs

Add or update `.github/dependabot.yml` so Dependabot opens PRs that advance
pinned SHAs whenever a new version is released:

```yaml
version: 2
updates:
  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
    groups:
      actions:
        patterns:
          - "*"
```

With this config Dependabot opens one grouped PR per week containing all
out-of-date action pins. Review the PR, check the release notes, and merge.

Docs:
[Keeping your actions up to date with Dependabot](https://docs.github.com/en/code-security/dependabot/working-with-dependabot/keeping-your-actions-up-to-date-with-dependabot)

---

## First-party actions (`actions/*`, `github/*`)

GitHub-owned actions are generally safe to reference by tag because GitHub
controls the namespace. Pinning is still a best practice, but the risk is lower
than for third-party actions.

---

## Verification checklist before adding any third-party action

- [ ] Action repository is actively maintained (recent commits, open issues
  addressed)
- [ ] Action is pinned to a full commit SHA, not a tag
- [ ] Dependabot is configured to keep the pin current
- [ ] The `permissions` block grants only what the action actually needs
- [ ] The action's `action.yml` source has been reviewed for unexpected network
  calls or secret access
