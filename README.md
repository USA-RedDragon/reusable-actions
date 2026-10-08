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
