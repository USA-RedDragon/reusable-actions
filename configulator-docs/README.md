# Configulator docs

Keeps the [configulator](https://github.com/USA-RedDragon/configulator)
config reference table in a Markdown file, and the example config file, up
to date. On pull requests it fails if either is stale. On pushes to the
default branch it commits the update.

## Usage

Put the markers where the table should go:

```markdown
## Configuration

<!-- configulator:begin -->
<!-- configulator:end -->
```

The repository must pin the generator as a tool, configulator v2.2.0 or
later (older versions fail with a clear error):

```sh
go get -tool github.com/USA-RedDragon/configulator/v2/cmd/configulator@latest
```

Then add a job:

```yaml
jobs:
  config-docs:
    runs-on: ubuntu-24.04
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
      - uses: USA-RedDragon/reusable-actions/configulator-docs@v2
        with:
          dir: internal/config
          type: Config
          env-prefix: MYAPP_
```

`contents: write` is only needed for the commit. With `commit: 'false'` the
action only checks.

The commit is pushed with the credentials `actions/checkout` left behind,
in the same job that runs the generator at the version your lockfile pins.
Don't give that job a token that may bypass branch protection: a
compromised dependency could use it. To commit with such a token, or to
commit to pull request branches such as Renovate's, use the
[configulator-docs reusable workflow](../README.md#configulator-docs-workflow)
instead. It generates in a read-only job and commits from a separate job
that runs no repository code.

## Inputs

| Input | Default | Description |
| --- | --- | --- |
| `type` | (required) | Config root type, as passed to `configulator -type` |
| `dir` | `.` | Package directory that declares the type |
| `file` | `README.md` | Markdown file holding the markers. Empty skips it |
| `sample-file` | `config.example.yaml` | Example config file to generate. Empty skips it |
| `sample-format` | `yaml` | `yaml`, `json` or `toml` |
| `env-prefix` | `''` | Environment variable prefix shown in the table |
| `env-separator` | `_` | Environment variable separator shown in the table |
| `flag-separator` | `.` | Flag separator shown in the table |
| `working-directory` | `.` | Directory with the go.mod that pins configulator |
| `setup-go` | `true` | Install Go from `go-version-file` |
| `go-version-file` | `go.mod` | Passed to actions/setup-go |
| `commit` | `auto` | `true`, `false`, `auto` (commit only on pushes to the default branch), or `write` (write the files and set `stale`, no git) |
| `git-user-name` | `github-actions[bot]` | Commit author name |
| `git-user-email` | the GitHub Actions bot address | Commit author email |

## Outputs

| Output | Description |
| --- | --- |
| `stale` | `true` if a file was out of date when the action started |
