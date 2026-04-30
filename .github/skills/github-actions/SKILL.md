---
name: github-actions
description: >-
  Use when asked to write, explain, customize, debug, migrate, or secure GitHub
  Actions workflows — including workflow syntax, triggers, matrices, runners,
  reusable workflows, artifacts, caching, secrets, OIDC, deployments, custom
  actions, or Actions Runner Controller. Also use for questions about this
  repository's devcontainer feature testing and publishing workflow in
  .github/workflows/publish.yml.
---

# GitHub Actions Expert

GitHub Actions questions are easy to answer from stale memory. Always ground
answers in official GitHub documentation. Return the closest authoritative page
rather than generic CI/CD advice.

## When to Use

Use this skill when the request is about:

- GitHub Actions concepts, terminology, or product boundaries
- Workflow YAML — triggers, jobs, steps, matrices, concurrency, variables, contexts, or expressions
- GitHub-hosted runners, larger runners, self-hosted runners, or Actions Runner Controller
- Artifacts, caches, reusable workflows, workflow templates, or custom actions
- Secrets, `GITHUB_TOKEN`, OpenID Connect, artifact attestations, or secure workflow patterns
- Environments, deployment protection rules, deployment history, or deployment examples
- Migrating from Jenkins, CircleCI, GitLab CI/CD, Travis CI, or Azure Pipelines
- This repository's `.github/workflows/publish.yml` — the devcontainer feature collect / test / summarize / publish pipeline
- Troubleshooting workflow behavior when the user needs documentation, syntax guidance, or official references

Do **not** use this skill for:

- Debugging a specific failing PR check or CI failure — use GitHub MCP Server tools (`list_workflow_runs`, `get_job_logs`) directly
- General GitHub pull request, branch, or repository operations

## Workflow

### 1. Classify the request

Decide which bucket the question belongs to before searching:

- Getting started or tutorials
- Workflow authoring and syntax
- Runners and execution environment
- Security and supply chain
- Deployments and environments
- Custom actions and publishing
- Monitoring, logs, and troubleshooting
- Migration
- This repo's publish pipeline

If you need a quick starting point, load `references/topic-map.md` and jump to the closest section.

### 2. Search official GitHub docs first

- Treat `docs.github.com` as the source of truth.
- Prefer pages under <https://docs.github.com/en/actions>.
- Search with the user's exact terms plus a focused Actions phrase such as `workflow syntax`, `OIDC`, `reusable workflows`, or `self-hosted runners`.
- When multiple pages are plausible, compare 2–3 candidate pages and pick the one that most directly answers the question.

### 3. Open the best page before answering

- Read the most relevant page, and the exact section when practical.
- Use the topic map only to narrow the search space or surface likely starting pages.
- If a page appears renamed, moved, or incomplete, say so explicitly and return the nearest authoritative pages instead of guessing.

### 4. Answer with docs-grounded guidance

- Start with a direct answer in plain language.
- Include exact GitHub docs links, not just the docs homepage.
- Only provide YAML or step-by-step examples when the user asks for them or when the docs page makes an example necessary.
- Make any inference explicit:
  - `According to GitHub docs, …`
  - `Inference: this likely means …`

## Repo-Specific Context: The Publish Workflow

`.github/workflows/publish.yml` follows a four-job pattern:

1. **`collect`** — runs `collect-and-filter-features.js` to build a JSON matrix of unpublished devcontainer features and passes it as a job output
2. **`test`** — fan-out matrix job (`fail-fast: false`) that runs each feature's `test/<scope>/<id>/test.sh`, captures the outcome as an artifact, and fails the individual job if the test failed
3. **`summarize`** — runs `if: always()` after all test jobs, downloads the per-feature result artifacts, writes a Markdown table to `$GITHUB_STEP_SUMMARY`, and fails if any test failed — this is the publish gate
4. **`publish`** — depends on `summarize`; skipped when `dry_run` is `true` or `summarize` did not succeed

When helping with this workflow:

- Check `.github/scripts/collect-and-filter-features.js` and `filter-unpublished-features.js` for the matrix-building logic
- Feature test scripts live at `test/<scope>/<feature-id>/test.sh`
- Feature definitions live under `features/<scope>/<feature-id>/`

## Answer Shape

Use a compact structure unless the user asks for depth:

1. Direct answer
2. Relevant docs (exact links)
3. Example YAML or steps — only if needed
4. Explicit inference callout — only if you had to connect multiple docs pages

Keep citations close to the claim they support.

## Search and Routing Tips

- For concept questions, prefer overview or concept pages before deep reference pages.
- For syntax questions, prefer workflow syntax, events, contexts, variables, or expressions reference pages.
- For security questions, prefer `Secure use`, `Secrets`, `GITHUB_TOKEN`, `OpenID Connect`, and artifact attestation docs.
- For deployment questions, prefer environments and deployment protection docs before cloud-specific examples.
- For migration questions, prefer the migration hub page first, then a platform-specific migration guide.
- For beginner walkthroughs, start with a tutorial or quickstart instead of a raw reference page.

## Common Mistakes

- Answering from memory without verifying the current docs
- Linking the GitHub Actions docs landing page when a narrower page exists
- Mixing up reusable workflows and composite actions
- Suggesting long-lived cloud credentials when OIDC is the better documented path
- Treating repo-specific CI debugging as a documentation question — use GitHub MCP Server tools instead

## Bundled Reference

Load `references/topic-map.md` as a compact index of likely documentation entry points. It is intentionally selective and should never replace the live GitHub docs as the final authority.
