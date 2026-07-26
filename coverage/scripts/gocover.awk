# `go test -coverprofile` to `path<TAB>found<TAB>hit`. Load after relpath.awk.
#
# Go instruments statements, not lines, so the counts here are statement counts
# and the percentages that fall out match `go tool cover -func` exactly. Calling
# them lines downstream would be a lie of at most a rounding error, so the
# columns are simply left unnamed.

# `path/to/file.go:startLine.startCol,endLine.endCol numStatements count`.
# The last two fields are the counts; everything before them is the location,
# which is reassembled rather than indexed so a path containing a space
# survives.
NF >= 3 && $0 !~ /^mode:/ {
  loc = $1
  for (i = 2; i <= NF - 2; i++) loc = loc " " $i

  pos = 0
  for (i = length(loc); i > 0; i--) if (substr(loc, i, 1) == ":") { pos = i; break }
  if (pos == 0) next

  f = relpath(substr(loc, 1, pos - 1))
  files[f] = 1
  k = f SUBSEP substr(loc, pos + 1)

  # `-coverpkg` has every test binary report every block, so the same block
  # arrives once per package under test. Its statements are counted on first
  # sight only while the execution counts accumulate, which is how go tool
  # cover merges profiles, and is why a block exercised by any one binary
  # counts as covered.
  if (!(k in stmts)) { stmts[k] = $(NF - 1) + 0; found[f] += stmts[k] }
  count[k] += $NF + 0
}

END {
  for (k in stmts) if (count[k] > 0) { split(k, p, SUBSEP); hit[p[1]] += stmts[k] }
  for (f in files) print f "\t" found[f] "\t" (hit[f] + 0)
}
