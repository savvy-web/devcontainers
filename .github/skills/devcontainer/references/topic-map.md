# Devcontainer Topic Map

A compact routing aid for finding official containers.dev documentation quickly.
Intentionally selective — always verify against live docs on `containers.dev`.

## Features Spec

The primary reference for building and distributing features.

- [Features spec](https://containers.dev/implementors/features/) — feature
  metadata fields, lifecycle hooks, option types, env var injection, and OCI
  distribution
- [Features distribution](https://containers.dev/implementors/features-distribution/) —
  how features are packaged and published to OCI registries, semantic versioning,
  and the `devcontainer-collection.json` manifest

## devcontainer.json Schema and Reference

- [JSON schema](https://containers.dev/implementors/json_schema/) — the full
  machine-readable JSON Schema for `devcontainer.json`
- [JSON reference](https://containers.dev/implementors/json_reference/) — all
  `devcontainer.json` properties with human-readable descriptions, types, and
  examples

## Templates

- [Templates spec](https://containers.dev/implementors/templates/) — template
  metadata, option types, `devcontainer-template.json` fields
- [Templates distribution](https://containers.dev/implementors/templates-distribution/) —
  OCI-based template publishing and collection manifests

## Implementors Reference

- [Implementors reference](https://containers.dev/implementors/reference/) —
  tooling integration guide, mount paths, remote user handling, and lifecycle
  command execution order
- [Main spec](https://containers.dev/implementors/spec/) — full devcontainer
  spec including lifecycle, workspace mount, port forwarding, and remote user
  resolution

## Community Feature Collections

- [Available features](https://containers.dev/features) — community index of
  published features; useful for finding what already exists before building
  a new one
- [devcontainers/features](https://github.com/devcontainers/features) — the
  official Microsoft-maintained feature collection; good reference for
  install patterns

## Quick Lookup

| Question | Best starting page |
| :------- | :----------------- |
| What fields go in `devcontainer-feature.json`? | Features spec |
| What option types are supported? | Features spec → Options section |
| How does the CLI inject option values as env vars? | Features spec → Option Resolution |
| How do I declare that feature A runs after feature B? | Features spec → `installsAfter` |
| What is the full `devcontainer.json` property list? | JSON reference |
| How do I publish a feature to a registry? | Features distribution |
| What lifecycle commands run and in what order? | Implementors reference |
| How is the remote user resolved? | Main spec |
