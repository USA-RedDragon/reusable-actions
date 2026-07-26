#!/usr/bin/env bash
# Posts, or updates in place, the coverage comment on the current pull request.
#
# Lives in its own process so that the action can tolerate it failing: coverage
# is informational and never gates, so a rate limit or a missing permission
# must not turn the pull request red. Composite action steps cannot set
# `continue-on-error`, and `set -e` is suppressed inside an `if` condition, so
# isolating it in a separate bash invocation is what actually works.
#
# Usage: pr-comment.sh <current.tsv> <baseline.tsv> <marker>
# Env:   GH_TOKEN, GITHUB_REPOSITORY, RUNNER_TEMP, PR_NUMBER, BASE_SHA

set -euo pipefail

cur=${1:?usage: pr-comment.sh <current.tsv> <baseline.tsv> <marker>}
base=${2:-}
marker=${3:-coverage-comment}

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
changed="${RUNNER_TEMP}/coverage-changed.txt"
body="${RUNNER_TEMP}/coverage-comment.md"

# Ask the API which files the pull request touches, rather than diffing
# locally, so that a shallow checkout works just as well as a full one.
if ! gh pr diff "$PR_NUMBER" --name-only > "${changed}.raw" 2>/dev/null; then
  git diff --name-only "${BASE_SHA}...HEAD" > "${changed}.raw" 2>/dev/null || : > "${changed}.raw"
fi

# Both of those name files from the repository root, while the summary names
# them from the working directory. Bring them into the same frame, or nothing
# matches when the action runs against a module below the root.
prefix=${PWD#"${GITHUB_WORKSPACE%/}/"}
[[ $prefix == "$PWD" ]] && prefix=''
awk -v pre="${prefix:+$prefix/}" '
  { print (pre != "" && index($0, pre) == 1) ? substr($0, length(pre) + 1) : $0 }
' "${changed}.raw" > "$changed"

bash "${here}/comment.sh" "$cur" "$base" "$changed" "$marker" > "$body"

# Find our own comment by its marker. `gh pr comment --edit-last` would target
# whatever the token last said on this pull request, which on a repository
# where another action also comments as github-actions[bot] is not us.
id=$(gh api --paginate "repos/${GITHUB_REPOSITORY}/issues/${PR_NUMBER}/comments" \
  --jq "map(select(.body // \"\" | contains(\"<!-- ${marker} -->\"))) | .[0].id // empty" \
  | head -n 1)

if [[ -n $id ]]; then
  gh api --method PATCH "repos/${GITHUB_REPOSITORY}/issues/comments/${id}" -F "body=@${body}" --silent
  echo "updated coverage comment ${id}"
else
  gh api --method POST "repos/${GITHUB_REPOSITORY}/issues/${PR_NUMBER}/comments" -F "body=@${body}" --silent
  echo "posted a new coverage comment"
fi
