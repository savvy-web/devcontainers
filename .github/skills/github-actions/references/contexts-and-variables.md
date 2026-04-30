# Contexts and Default Environment Variables

A compact reference for the most-used context properties and default environment
variables. Always verify the full schema against the live docs:

- [Contexts reference](https://docs.github.com/en/actions/reference/accessing-contextual-information-about-workflow-runs)
- [Default environment variables](https://docs.github.com/en/actions/concepts/workflows-and-actions/variables#default-environment-variables)

---

## `github` context (most-used properties)

| Property | Type | Description |
| :--- | :--- | :--- |
| `github.sha` | string | Commit SHA that triggered the run |
| `github.ref` | string | Branch or tag ref (`refs/heads/main`) |
| `github.ref_name` | string | Short branch or tag name (`main`) |
| `github.event_name` | string | Name of the triggering event (`push`, `pull_request`, …) |
| `github.event` | object | Full webhook payload for the triggering event |
| `github.workflow` | string | Workflow name |
| `github.run_id` | string | Unique run ID (numeric string) |
| `github.run_number` | string | Sequential run number for this workflow |
| `github.actor` | string | Username of the user or app that triggered the run |
| `github.repository` | string | `owner/repo` |
| `github.repository_owner` | string | Organization or user name |
| `github.token` | string | Equivalent to `secrets.GITHUB_TOKEN` |
| `github.workspace` | string | Absolute path of the checked-out workspace |
| `github.action` | string | Unique action ID when running inside a custom action |
| `github.head_ref` | string | PR head branch (only on `pull_request` events) |
| `github.base_ref` | string | PR base branch (only on `pull_request` events) |
| `github.server_url` | string | `https://github.com` |
| `github.api_url` | string | `https://api.github.com` |

---

## `env` context

Holds all environment variables set via workflow-level, job-level, or step-level
`env:` blocks **and** values written to `$GITHUB_ENV`. Access as
`${{ env.MY_VAR }}`.

---

## `vars` context

Holds repository, organization, or environment **configuration variables** (not
secrets). Set in repository → Settings → Secrets and variables → Actions →
Variables. Access as `${{ vars.MY_VAR }}`.

---

## `secrets` context

| Property | Description |
| :--- | :--- |
| `secrets.GITHUB_TOKEN` | Auto-generated token scoped to the current repo |
| `secrets.<NAME>` | Any secret defined at repository, environment, or organization level |

---

## `job` context

| Property | Description |
| :--- | :--- |
| `job.status` | Current status: `success`, `failure`, `cancelled` |
| `job.container.id` | Container ID when running inside a service container |

---

## `steps` context

Access outputs and conclusions from earlier steps in the same job:

```yaml
steps:
  - id: build
    run: echo "result=ok" >> "$GITHUB_OUTPUT"
  - run: |
      echo "${{ steps.build.outputs.result }}"
      echo "${{ steps.build.conclusion }}" # success | failure | cancelled | skipped
```

---

## `needs` context

Access outputs and results from upstream jobs:

```yaml
jobs:
  deploy:
    needs: [build, test]
    if: ${{ needs.build.result == 'success' }}
    steps:
      - run: echo "${{ needs.build.outputs.version }}"
```

`needs.<job>.result` values: `success`, `failure`, `cancelled`, `skipped`.

---

## `matrix` context

Available only inside a matrix job. Properties mirror the matrix keys:

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, windows-latest]
    node: [18, 20]
steps:
  - run: echo "${{ matrix.os }} / ${{ matrix.node }}"
```

---

## `runner` context

| Property | Description |
| :--- | :--- |
| `runner.os` | `Linux`, `Windows`, `macOS` |
| `runner.arch` | `X86`, `X64`, `ARM`, `ARM64` |
| `runner.name` | Runner name |
| `runner.temp` | Temp directory path |
| `runner.tool_cache` | Tool cache directory |

---

## `inputs` context

Available in `workflow_dispatch` and `workflow_call` workflows. Access as
`${{ inputs.my_input }}`.

---

## Default environment variables (set by GitHub on the runner)

These are always available inside `run:` steps. **Do not set them yourself** —
GitHub overwrites them.

| Variable | Description |
| :--- | :--- |
| `GITHUB_SHA` | Commit SHA |
| `GITHUB_REF` | Branch or tag ref (`refs/heads/main`) |
| `GITHUB_REF_NAME` | Short branch or tag name |
| `GITHUB_HEAD_REF` | PR head branch (pull_request events only) |
| `GITHUB_BASE_REF` | PR base branch (pull_request events only) |
| `GITHUB_EVENT_NAME` | Triggering event name |
| `GITHUB_REPOSITORY` | `owner/repo` |
| `GITHUB_REPOSITORY_OWNER` | Org or user name |
| `GITHUB_RUN_ID` | Unique run ID |
| `GITHUB_RUN_NUMBER` | Sequential run number |
| `GITHUB_ACTOR` | Username that triggered the run |
| `GITHUB_WORKFLOW` | Workflow name |
| `GITHUB_JOB` | Job ID |
| `GITHUB_ACTION` | Current action ID |
| `GITHUB_WORKSPACE` | Checked-out workspace path |
| `GITHUB_ENV` | Path to the file for setting env vars across steps |
| `GITHUB_OUTPUT` | Path to the file for setting step outputs |
| `GITHUB_STEP_SUMMARY` | Path to the file for writing job summaries |
| `GITHUB_PATH` | Path to the file for prepending entries to `PATH` |
| `RUNNER_OS` | `Linux`, `Windows`, `macOS` |
| `RUNNER_ARCH` | `X86`, `X64`, `ARM`, `ARM64` |
| `RUNNER_TEMP` | Runner temp directory |
| `RUNNER_TOOL_CACHE` | Hosted tool cache directory |
