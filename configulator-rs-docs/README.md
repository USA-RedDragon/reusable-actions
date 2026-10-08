# Configulator docs (Rust)

Keeps the [configulator-rs](https://github.com/USA-RedDragon/configulator-rs)
config reference table in a Markdown file, and a sample config file such as
`config.example.yaml`, up to date. On pull requests it fails if either is
stale. On pushes to the default branch it commits the update.

This is the Rust version of [`configulator-docs`](../configulator-docs).

## Usage

Put the markers where the table should go:

```markdown
## Configuration

<!-- configulator:begin -->
<!-- configulator:end -->
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
      - uses: USA-RedDragon/reusable-actions/configulator-rs-docs@v2
        with:
          type: AppConfig
          env-prefix: MYAPP__
```

The action installs `configulator-cli` at the configulator-rs version in your
`Cargo.lock` (0.2.2 or later), so the table matches the
library you build with. Set `version` to pin something else.

`contents: write` is only needed for the commit. With `commit: 'false'` the
action only checks.

The commit is pushed with the credentials `actions/checkout` left behind. If
the default branch is protected, check out with a token that may bypass the
protection, such as a GitHub App's:

```yaml
steps:
  - id: app-token
    uses: actions/create-github-app-token@v3
    with:
      client-id: ${{ vars.AUTO_COMMIT_APP_ID }}
      private-key: ${{ secrets.AUTO_COMMIT_APP_KEY }}
  - uses: actions/checkout@v4
    with:
      token: ${{ steps.app-token.outputs.token }}
  - uses: USA-RedDragon/reusable-actions/configulator-rs-docs@v2
    with:
      type: AppConfig
      git-user-name: my-app[bot]
      git-user-email: my-app[bot]@users.noreply.github.com
```

## Inputs

| Input | Default | Description |
| --- | --- | --- |
| `type` | (required) | Config root type, as passed to `configulator --type` |
| `dir` | `.` | Directory scanned for the type's source |
| `file` | `README.md` | Markdown file holding the markers. Empty skips it |
| `sample-file` | `config.example.yaml` | Sample config file to generate. Empty skips it |
| `sample-format` | `yaml` | `yaml`, `json` or `toml` |
| `env-prefix` | `''` | Environment variable prefix shown in the table |
| `env-separator` | `__` | Environment variable separator shown in the table |
| `flag-separator` | `.` | Flag separator shown in the table |
| `working-directory` | `.` | Directory with the Cargo.lock that pins configulator-rs |
| `version` | from `Cargo.lock` | configulator-cli version to install |
| `commit` | `auto` | `true`, `false`, or `auto` (commit only on pushes to the default branch) |
| `git-user-name` | `github-actions[bot]` | Commit author name |
| `git-user-email` | the GitHub Actions bot address | Commit author email |

## Outputs

| Output | Description |
| --- | --- |
| `stale` | `true` if a file was out of date when the action started |
