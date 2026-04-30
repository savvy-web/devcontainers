# Workflow Syntax Cheatsheet

The 10 most commonly needed YAML patterns. All examples are minimal and correct.
Always verify current syntax against
[Workflow syntax for GitHub Actions](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax).

---

## 1. Trigger shapes

```yaml
on:
  push:
    branches: [main, "releases/**"]
    paths-ignore: ["**.md"]
  pull_request:
    branches: [main]
    types: [opened, synchronize, reopened]
  schedule:
    - cron: "0 6 * * 1" # every Monday at 06:00 UTC
  workflow_dispatch:
    inputs:
      environment:
        description: Target environment
        required: true
        default: staging
        type: choice
        options: [staging, production]
      dry_run:
        description: Skip publishing
        type: boolean
        default: false
```

Docs:
[Events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows)

---

## 2. Concurrency — cancel in-progress runs on the same branch

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

Set at workflow level to cancel older runs on the same branch. Use
`cancel-in-progress: false` on release/main branches to queue rather than
cancel.

Docs:
[Controlling the concurrency of workflows and jobs](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-your-workflow-runs/control-the-concurrency-of-workflows-and-jobs)

---

## 3. Job outputs and `needs`

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      artifact-name: ${{ steps.set-name.outputs.artifact-name }}
    steps:
      - id: set-name
        run: echo "artifact-name=my-app-${{ github.sha }}" >> "$GITHUB_OUTPUT"

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying ${{ needs.build.outputs.artifact-name }}"
```

Docs:
[Passing information between jobs](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/pass-job-outputs)

---

## 4. Dynamic matrix from JSON (using `fromJSON`)

```yaml
jobs:
  generate:
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.set.outputs.matrix }}
    steps:
      - id: set
        run: |
          echo 'matrix={"include":[{"target":"a"},{"target":"b"}]}' >> "$GITHUB_OUTPUT"

  run:
    needs: generate
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix: ${{ fromJSON(needs.generate.outputs.matrix) }}
    steps:
      - run: echo "Running for ${{ matrix.target }}"
```

Docs:
[Running variations of jobs in a workflow](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/run-job-variations)

---

## 5. `permissions` block

```yaml
# Minimal top-level default — restrict everything, then opt in per job
permissions: read-all

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write # required for OIDC
      packages: write
```

Top-level `permissions` sets the default for every job. Per-job blocks override
the top-level default.

Docs:
[Permissions for the GITHUB\_TOKEN](https://docs.github.com/en/actions/reference/security/automatic-token-authentication#permissions-for-the-github_token)

---

## 6. Artifact upload / download pair (v4 API)

```yaml
- uses: actions/upload-artifact@v4
  with:
    name: test-results-${{ matrix.target }}
    path: results/
    retention-days: 7

# In a later job that needs: [test]
- uses: actions/download-artifact@v4
  with:
    name: test-results-${{ matrix.target }}
    path: downloaded/
```

v4 changed the default merge behavior. Use `merge-multiple: true` on download to
combine artifacts from a matrix.

Docs:
[Storing workflow data as artifacts](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/store-workflow-data-as-artifacts)

---

## 7. OIDC — minimal pattern for cloud auth

```yaml
permissions:
  id-token: write
  contents: read

steps:
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::123456789012:role/github-actions
      aws-region: us-east-1
```

Never store cloud credentials as secrets. Use OIDC for AWS, Azure, and GCP.

Docs:
[About security hardening with OpenID Connect](https://docs.github.com/en/actions/concepts/security/openid-connect)

---

## 8. `if:` conditions and status functions

```yaml
steps:
  - name: Always runs
    if: always()
    run: echo "always"

  - name: Runs on failure only
    if: failure()
    run: echo "something failed"

  - name: Runs when cancelled
    if: cancelled()
    run: echo "cancelled"

  - name: Conditional on a variable
    if: ${{ github.event_name == 'push' && github.ref == 'refs/heads/main' }}
    run: echo "main push"
```

`always()` overrides `if: success()` (the default). Combine status functions
with `&&` using the expression syntax.

Docs:
[Expressions](https://docs.github.com/en/actions/concepts/workflows-and-actions/expressions)

---

## 9. `env:` scope — workflow, job, and step

```yaml
env:
  GLOBAL_VAR: hello # available in all jobs

jobs:
  example:
    runs-on: ubuntu-latest
    env:
      JOB_VAR: world # available in all steps of this job
    steps:
      - env:
          STEP_VAR: "!" # available only in this step
        run: echo "$GLOBAL_VAR $JOB_VAR $STEP_VAR"
```

Step-level `env:` overrides job-level, which overrides workflow-level.

Docs:
[Variables](https://docs.github.com/en/actions/concepts/workflows-and-actions/variables)

---

## 10. `$GITHUB_OUTPUT`, `$GITHUB_ENV`, `$GITHUB_STEP_SUMMARY`

```bash
# Set a step output (readable as steps.<id>.outputs.<key>)
echo "version=1.2.3" >> "$GITHUB_OUTPUT"

# Set an environment variable for subsequent steps in the same job
echo "DEPLOY_ENV=production" >> "$GITHUB_ENV"

# Write a Markdown job summary (visible in the Actions run UI)
echo "## ✅ Build complete" >> "$GITHUB_STEP_SUMMARY"
echo "| Key | Value |" >> "$GITHUB_STEP_SUMMARY"
echo "| --- | ----- |" >> "$GITHUB_STEP_SUMMARY"
echo "| SHA | $GITHUB_SHA |" >> "$GITHUB_STEP_SUMMARY"
```

**Never use the deprecated `set-output` or `save-state` workflow commands** —
they were removed. Always write to the file path stored in the environment
variable instead.

Docs:
[Workflow commands for GitHub Actions](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands)
