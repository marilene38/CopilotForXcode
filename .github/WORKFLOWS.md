# GitHub Actions Workflows

This document describes every workflow in `.github/workflows/`, the conditions
under which each runs, and the design decisions behind them.

---

## `auto-close-pr.yml` — Auto-close PR

### Purpose

Automatically closes pull requests opened from **forks** with a polite message
explaining that external contributions are not accepted at this time, and
directs contributors to the GitHub Copilot community discussion forum.

### Trigger

```yaml
on:
  pull_request_target:
    types: [opened, reopened, synchronize]
```

`pull_request_target` is used (rather than `pull_request`) because it runs
with write permissions in the context of the *base* repository, which is
required to close the PR via the GitHub CLI.

`synchronize` is included so that fork PRs are caught even when a contributor
force-pushes new commits after the initial `opened` event.

### Concurrency

```yaml
concurrency:
  group: auto-close-pr-${{ github.event.pull_request.number }}
  cancel-in-progress: true
```

Each PR gets its own group so rapid successive events (e.g. force-push
followed by synchronize) cancel the earlier run; only the latest execution
proceeds.

### Permissions

Only `pull-requests: write` is requested — the minimum needed to close a PR.

### Job: `close`

| Step | Condition | What it does |
|---|---|---|
| Validate required environment variables | always | Fails fast if `PR_NUMBER` or `PR_HEAD_REPO` context values are missing, preventing silent no-ops. |
| Log PR details | always | Emits a `::group::` block with PR number, author, head repo, state, and event action for easy log inspection. |
| Close PR from fork with message | fork PR + state == open | Closes the PR with a `not_planned` reason and a guidance comment. Uses a retry loop (3 attempts, exponential back-off) to handle transient GitHub API failures. Logs execution time. |
| Log skip reason | same-repo PR **or** not open | Emits a `::notice::` explaining why no action was taken, keeping the log transparent. |

### Close conditions

A PR is closed only when **both** of the following are true:

1. `github.event.pull_request.head.repo.full_name != github.repository`
   — the head repo is different from the base repo, meaning this is a fork.
2. `github.event.pull_request.state == 'open'`
   — the PR has not already been closed by another run or manually.

### Skip conditions

The skip-reason step runs when **either** condition above is false:

- Same-repo PRs are skipped (internal branches are not affected).
- Already-closed PRs are skipped (idempotent behaviour).

---

## `codeql.yml` — CodeQL Advanced

### Purpose

Runs GitHub's CodeQL static-analysis engine against all supported languages
to surface security vulnerabilities and code-quality issues.

### Triggers

| Event | Branch / schedule | Reason |
|---|---|---|
| `push` | `main` | Ensures the default branch is always analysed after each merge. |
| `pull_request` | `main` | Provides per-PR security feedback before merge. |
| `schedule` | weekly (Mon 23:24 UTC) | Catches newly published CodeQL queries against existing code. |

### Concurrency

```yaml
concurrency:
  group: codeql-${{ github.ref }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}
```

- **`pull_request`**: cancels earlier in-progress runs on the same ref so
  redundant analysis jobs do not pile up during active development.
- **`push` / `schedule`**: `cancel-in-progress` is `false`, so analysis on
  the default branch is never silently dropped.

### Matrix

| Language | Build mode | Runner |
|---|---|---|
| `python` | `none` | `ubuntu-latest` |
| `swift` | `manual` | `macos-latest` |

`fail-fast: false` ensures that a failure in one language matrix cell does
not cancel the other, so all languages are always analysed.

### Job: `analyze`

| Step | Condition | What it does |
|---|---|---|
| Checkout repository | always | Fetches source at the triggering ref using `actions/checkout@v4`. |
| Log analysis start | always | Emits a `::group::` block with language, build mode, ref, and event for easy log navigation. |
| Initialize CodeQL | always | Configures CodeQL for the target language and build mode. |
| Set Xcode version | `build-mode == 'manual'` | Selects the correct Xcode toolchain for Swift builds. |
| Build (xcodebuild) | `build-mode == 'manual'` | Archives the Copilot for Xcode scheme so CodeQL can trace the Swift compilation. Output is wrapped in `::group::Build` and execution time is logged. |
| Perform CodeQL Analysis | always | Uploads results to GitHub code scanning. |

### Action versions

| Action | Version | Notes |
|---|---|---|
| `actions/checkout` | `v4` | Latest major version. |
| `github/codeql-action/init` | `v3` | Latest major version. |
| `github/codeql-action/analyze` | `v3` | Latest major version. |
