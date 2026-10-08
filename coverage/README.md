# Coverage

Coverage badge, per-file baseline and pull request comment from an LCOV or Go
coverage report, with no third-party service involved.

It reduces whatever your toolchain produced to one `path<TAB>total<TAB>covered`
row per file, and everything after that — badge, baseline, comment — works the
same regardless of language.

| Format | Produced by | Counts |
| --- | --- | --- |
| `lcov` | `cargo llvm-cov`, `grcov`, `lcov` | lines |
| `go` | `go test -coverprofile` | statements, matching `go tool cover -func` exactly |

The format is detected from the file, so `format` normally needs no setting.

## Usage

Drop it into the job that produced the report:

```yaml
- name: Unit tests
  run: go test ./... -coverprofile coverage.out -coverpkg=./... -covermode atomic

- uses: USA-RedDragon/reusable-actions/coverage@v2
  with:
    file: coverage.out
```

```yaml
- run: cargo llvm-cov --lcov --output-path lcov.info

- uses: USA-RedDragon/reusable-actions/coverage@v2
  with:
    file: lcov.info
```

The job needs `contents: write` to commit the badge and baseline, and
`pull-requests: write` to comment:

```yaml
permissions:
  contents: write
  pull-requests: write
```

Then reference the badge from your README:

```markdown
![Coverage](https://raw.githubusercontent.com/OWNER/REPO/main/.github/badges/coverage.svg)
```

`raw.githubusercontent.com` rather than a relative path, so the badge also
renders on places that mirror the README, and always reflects the default
branch rather than whatever ref the reader is on.

## What it does

On a **pull request** it posts a comment with the total, its delta against the
baseline committed on the default branch, and a per-file table scoped to the
files that pull request touched. The comment is found by its hidden marker and
updated in place, so a pushed branch does not accumulate a stack of them.

On a **push to the default branch** it rewrites the badge and the baseline and
commits them back, so the next pull request has something to compare against.
That commit carries `[skip ci]`.

Either way, the summary is written to the job summary too.

Coverage reporting is informational: a failure to comment logs a warning rather
than failing the job. Use `fail-under` if you want a gate.

## Inputs

| Input | Default | Description |
| --- | --- | --- |
| `file` | — | **Required.** Path to the coverage report. |
| `format` | `auto` | `auto`, `lcov` or `go`. |
| `strip-prefix` | `''` | Prefix to strip from report paths. See [Paths](#paths). |
| `working-directory` | `.` | Directory the report paths, badge and baseline are relative to. |
| `badge` | `.github/badges/coverage.svg` | Where to write the badge. Empty disables it. |
| `baseline` | `.github/coverage-baseline.tsv` | Committed per-file summary that comments diff against. Empty disables deltas. |
| `label` | `coverage` | Left-hand text on the badge. |
| `thresholds` | `80,60` | `green,yellow` percentages. |
| `comment` | `true` | Post the pull request comment. |
| `marker` | `coverage-comment` | Hidden marker identifying the comment. Give each report its own if a repo publishes more than one. |
| `job-summary` | `true` | Also write the summary to the job summary. |
| `commit` | `auto` | Commit badge and baseline. `auto` means pushes to the default branch only. `write` only writes them, no git. |
| `git-user-name` | `github-actions[bot]` | Author of that commit. |
| `git-user-email` | `41898282+github-actions[bot]@users.noreply.github.com` | Author of that commit. |
| `fail-under` | `''` | Fail below this percentage. Empty never fails. |
| `if-no-file` | `error` | `warn` to skip quietly when the report is missing. |
| `token` | `github.token` | Token used to comment and push. |

## Outputs

| Output | Description |
| --- | --- |
| `percent` | Total coverage to one decimal place. |
| `covered` | Covered lines, or statements for Go. |
| `total` | Instrumented lines, or statements for Go. |
| `summary` | Path to the normalised summary, for further processing. |

## Paths

Neither format emits repository-relative paths: llvm-cov writes absolute ones
and Go writes import paths. Both are rewritten by dropping leading segments
until what remains names a file present in the checkout, which needs no
configuration and keeps working for modules and crates nested below the
repository root.

Set `strip-prefix` explicitly if that guesses wrong — it can, if a leading
segment of the original path happens to also name a real directory in your
checkout. Paths that never resolve are passed through untouched, so a baseline
full of absolute paths is the symptom to look for.

## Notes

- **Protected default branch.** The default `GITHUB_TOKEN` cannot push to a
  branch protected against it. Don't hand this action a token that may
  bypass the protection in a job that runs your tests: test code and its
  dependencies could read it. Use the
  [coverage reusable workflow](../README.md#coverage-workflow) instead, which
  commits from a separate job that runs no repository code.
- **`cancel-in-progress`.** Do not cancel in-progress runs on the default
  branch if another workflow requires this check to conclude `success` on the
  deployed commit — a superseded run concludes `cancelled`. The push retries,
  so two concurrent runs reaching the commit step are handled.
- **Running under `if: always()`.** Set `if-no-file: warn` so that a test run
  which never produced a report skips reporting instead of adding a second
  failure.
- **Shallow checkouts** are fine, so `actions/checkout` needs no `fetch-depth`.
  The changed-file list comes from the API and only falls back to a local diff
  if that is unavailable, and the commit step deepens the clone first, since a
  push from a shallow one is rejected.
