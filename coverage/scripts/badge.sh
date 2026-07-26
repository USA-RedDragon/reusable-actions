#!/usr/bin/env bash
# Renders a flat coverage badge SVG from a normalize.sh summary.
#
# Usage: badge.sh <summary.tsv> <output.svg> [label] [green,yellow]

set -euo pipefail

tsv=${1:?usage: badge.sh <summary.tsv> <output.svg> [label] [thresholds]}
out=${2:?usage: badge.sh <summary.tsv> <output.svg> [label] [thresholds]}
label=${3:-coverage}
thresholds=${4:-80,60}

green=${thresholds%%,*}
yellow=${thresholds##*,}

pct=$(awk -F'\t' '
  { found += $2; hit += $3 }
  END     { printf "%.1f", found ? hit * 100 / found : 0 }
' "$tsv")

color=$(awk -v p="$pct" -v g="$green" -v y="$yellow" 'BEGIN {
  print (p >= g) ? "#4c1" : (p >= y) ? "#dfb317" : "#e05d44"
}')

message="${pct}%"

# 7px per character at font-size 11 approximates DejaVu Sans closely enough.
label_w=$(( ${#label} * 7 + 10 ))
msg_w=$(( ${#message} * 7 + 10 ))
total_w=$(( label_w + msg_w ))
label_x=$(( label_w / 2 ))
msg_x=$(( label_w + msg_w / 2 ))

mkdir -p "$(dirname "$out")"
cat > "$out" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" width="${total_w}" height="20" role="img" aria-label="${label}: ${message}">
  <title>${label}: ${message}</title>
  <linearGradient id="s" x2="0" y2="100%">
    <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
    <stop offset="1" stop-opacity=".1"/>
  </linearGradient>
  <clipPath id="r">
    <rect width="${total_w}" height="20" rx="3" fill="#fff"/>
  </clipPath>
  <g clip-path="url(#r)">
    <rect width="${label_w}" height="20" fill="#555"/>
    <rect x="${label_w}" width="${msg_w}" height="20" fill="${color}"/>
    <rect width="${total_w}" height="20" fill="url(#s)"/>
  </g>
  <g fill="#fff" text-anchor="middle" font-family="Verdana,DejaVu Sans,Geneva,sans-serif" font-size="11">
    <text x="${label_x}" y="15" fill="#010101" fill-opacity=".3">${label}</text>
    <text x="${label_x}" y="14">${label}</text>
    <text x="${msg_x}" y="15" fill="#010101" fill-opacity=".3">${message}</text>
    <text x="${msg_x}" y="14">${message}</text>
  </g>
</svg>
SVG

echo "$pct"
