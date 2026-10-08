# Reusable GitHub Actions Workflows

This repo contains some reusable workflows that I utilize around my repos.

## Reusable workflows

Called with `uses:` at the job level. These live in `.github/workflows/`.

- `docker-ci.yaml` - Docker Build and optional push to GHCR
- `goreleaser.yaml` - Release a new version of a Go project using [goreleaser](https://goreleaser.com/)

```yaml
jobs:
  release:
    uses: USA-RedDragon/reusable-actions/.github/workflows/goreleaser.yaml@v2
```

### configulator-docs workflow

`configulator-docs.yaml` keeps the
[configulator](https://github.com/USA-RedDragon/configulator) config table
and example config up to date, and commits the update with a GitHub App
token on pushes to the default branch and on pull requests from branches in
the same repository, such as Renovate's.

It runs as two jobs:

- `generate` checks out with a read-only token and no stored credentials,
  runs the [`configulator-docs`](configulator-docs) or
  [`configulator-rs-docs`](configulator-rs-docs) action in `write` mode, and
  uploads the regenerated files. It fails when the docs are stale and can't
  be committed, such as on a pull request from a fork.
- `commit` runs only when `generate` found stale docs and committing is
  allowed. It never runs repository code. It checks that the artifact holds
  only the declared Markdown and example files, as regular files, mints the
  app token, writes the files to the pull request branch or the default
  branch and pushes. Default branch commits carry `[skip ci]`. Pull request
  commits don't, so checks run on the new head.

```yaml
name: Config docs

on:
  pull_request:
  push:
    branches:
      - main

permissions: {}

jobs:
  config-docs:
    permissions:
      contents: read
    uses: USA-RedDragon/reusable-actions/.github/workflows/configulator-docs.yaml@v2
    with:
      dir: internal/config
      type: Config
      env-prefix: MYAPP_
      env-separator: _
      app-id: ${{ vars.AUTO_COMMIT_APP_ID }}
    secrets:
      app-key: ${{ secrets.AUTO_COMMIT_APP_KEY }}
```

For configulator-rs set `language: rust`. The other inputs match the
composite actions: `type`, `dir`, `file`, `sample-file`, `sample-format`,
`env-prefix`, `env-separator`, `flag-separator`, `working-directory`, plus
`go-version-file` for Go and `version` for Rust. The app needs contents
write access and must be allowed to push to the target branches.

## Composite actions

Called with `uses:` at the step level, so they run inside a job you already
have and can see the files it produced.

- [`coverage`](coverage) - Coverage badge, baseline and pull request comment
  from an LCOV or Go coverage report, without a third-party service
- [`configulator-docs`](configulator-docs) - Keep the configulator config
  reference table in a Markdown file, and the example config, up to date
- [`configulator-rs-docs`](configulator-rs-docs) - The same for
  configulator-rs

```yaml
steps:
  - uses: USA-RedDragon/reusable-actions/coverage@v2
    with:
      file: coverage.out
```
