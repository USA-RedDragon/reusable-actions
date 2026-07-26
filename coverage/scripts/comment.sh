#!/usr/bin/env bash
# Renders the Markdown coverage report, comparing a normalize.sh summary
# against the baseline committed on the default branch.
#
# Purely informational: this never gates the build and always exits 0.
#
# Usage: comment.sh <current.tsv> [baseline.tsv] [changed-files.txt|-] [marker]
#
# A missing or empty baseline is fine — deltas are simply omitted. Passing `-`
# for the changed-files list means there is no pull request to scope the table
# to, as on the job summary, and every file is listed instead.

set -euo pipefail

cur=${1:?usage: comment.sh <current.tsv> [baseline.tsv] [changed-files.txt|-] [marker]}
base=${2:-/dev/null}
changed=${3:--}
marker=${4:-coverage-comment}

[[ -s $base ]] || base=/dev/null
[[ $changed == - ]] && scoped=0 || scoped=1
[[ -s $changed ]] || changed=/dev/null

awk -F'\t' -v cur="$cur" -v base="$base" -v changed="$changed" -v marker="$marker" -v scoped="$scoped" '
  function pct(hit, found) { return found ? hit * 100 / found : 0 }
  function fmt(hit, found)  { return found ? sprintf("%.1f%%", pct(hit, found)) : "n/a" }
  function delta(d) {
    if (d > -0.05 && d < 0.05) return "±0.0%"
    return sprintf("%+.1f%%", d)
  }

  # order[] preserves the sorted input order; mawk has no asort and a bare
  # `for (f in arr)` would reshuffle the table on every run.
  FILENAME == cur     { clf[$1] = $2; clh[$1] = $3; cf += $2; ch += $3; order[++n] = $1; next }
  FILENAME == base    { blf[$1] = $2; blh[$1] = $3; bf += $2; bh += $3; seen_base = 1; next }
  FILENAME == changed { touched[$0] = 1; next }

  END {
    print "### Coverage"
    print ""

    total = fmt(ch, cf)
    if (seen_base && bf > 0) {
      printf "Total: **%s** %s — %d of %d covered\n", total, delta(pct(ch, cf) - pct(bh, bf)), ch, cf
    } else {
      printf "Total: **%s** — %d of %d covered\n", total, ch, cf
      no_base = 1
    }
    print ""

    # Scoped to what the pull request touched, or every file when there is no
    # pull request to scope to.
    rows = 0
    for (i = 1; i <= n; i++) {
      f = order[i]
      if (scoped && !(f in touched)) continue
      rows++
      if (seen_base && (f in blf) && blf[f] > 0)
        body = body sprintf("| `%s` | %s | %s |\n", f, fmt(clh[f], clf[f]), delta(pct(clh[f], clf[f]) - pct(blh[f], blf[f])))
      else
        body = body sprintf("| `%s` | %s | new |\n", f, fmt(clh[f], clf[f]))
    }

    # Files the pull request did not touch but whose coverage moved anyway.
    indirect = 0
    if (scoped && seen_base) {
      for (i = 1; i <= n; i++) {
        f = order[i]
        if (f in touched) continue
        if (!(f in blf)) continue
        if (pct(clh[f], clf[f]) != pct(blh[f], blf[f])) indirect++
      }
    }

    if (rows > 0) {
      if (scoped) printf "<details open><summary>%d changed file%s with coverage</summary>\n\n", rows, (rows == 1 ? "" : "s")
      else        printf "<details><summary>%d instrumented file%s</summary>\n\n", rows, (rows == 1 ? "" : "s")
      print "| File | Coverage | Δ |"
      print "| --- | --- | --- |"
      printf "%s", body
      print ""
      print "</details>"
    } else if (scoped) {
      print "_No instrumented files were changed._"
    }

    if (indirect > 0) {
      print ""
      printf "%d other file%s changed coverage indirectly.\n", indirect, (indirect == 1 ? "" : "s")
    }
    if (no_base) {
      print ""
      print "_No baseline on the default branch yet, so deltas are unavailable for this run._"
    }

    print ""
    print "<!-- " marker " -->"
  }
' "$cur" "$base" "$changed"
