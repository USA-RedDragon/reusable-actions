# Configulator docs

Keeps the [configulator](https://github.com/USA-RedDragon/configulator)
config reference table in a Markdown file up to date. On pull requests it
fails if the file is stale. On pushes to the default branch it commits the
update.

## Usage

Put the markers where the table should go:

```markdown
## Configuration

<!-- configulator:begin -->
<!-- configulator:end -->
```

The repository must pin the generator as a tool (configulator v2.1.0 or
later):

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

## Inputs

| Input | Default | Description |
| --- | --- | --- |
| `type` | (required) | Config root type, as passed to `configulator -type` |
| `dir` | `.` | Package directory that declares the type |
| `file` | `README.md` | Markdown file holding the markers |
| `env-prefix` | `''` | Environment variable prefix shown in the table |
| `env-separator` | `_` | Environment variable separator shown in the table |
| `flag-separator` | `.` | Flag separator shown in the table |
| `working-directory` | `.` | Directory with the go.mod that pins configulator |
| `setup-go` | `true` | Install Go from `go-version-file` |
| `go-version-file` | `go.mod` | Passed to actions/setup-go |
| `commit` | `auto` | `true`, `false`, or `auto` (commit only on pushes to the default branch) |
| `git-user-name` | `github-actions[bot]` | Commit author name |
| `git-user-email` | the GitHub Actions bot address | Commit author email |

## Outputs

| Output | Description |
| --- | --- |
| `stale` | `true` if the file was out of date when the action started |
