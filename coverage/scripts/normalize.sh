#!/usr/bin/env bash
# Reduces a coverage report to one `path<TAB>found<TAB>hit` row per file, so
# that everything downstream — badge, baseline, pull request comment — is
# language- and toolchain-agnostic.
#
# Two input formats are understood, auto-detected by default:
#
#   lcov  Produced by cargo-llvm-cov, grcov, lcov and friends.
#   go    Produced by `go test -coverprofile`.
#
# The parsers live in lcov.awk and gocover.awk, over the shared path rewriting
# in relpath.awk.
#
# Usage: normalize.sh <coverage-file> [auto|lcov|go] [strip-prefix]

set -euo pipefail

report=${1:?usage: normalize.sh <coverage-file> [format] [strip-prefix]}
format=${2:-auto}
strip=${3:-}

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

if [[ $format == auto ]]; then
  if head -n 1 "$report" | grep -Eq '^mode: (set|count|atomic)'; then
    format=go
  elif grep -qm1 '^SF:' "$report"; then
    format=lcov
  else
    echo "normalize.sh: cannot tell whether ${report} is lcov or go coverage; pass the format explicitly" >&2
    exit 1
  fi
fi

case $format in
  lcov) parser=lcov.awk ;;
  go)   parser=gocover.awk ;;
  *)
    echo "normalize.sh: unknown format '${format}', expected auto, lcov or go" >&2
    exit 1
    ;;
esac

awk -v strip="${strip%/}" -f "${here}/relpath.awk" -f "${here}/${parser}" "$report" |
  LC_ALL=C sort
