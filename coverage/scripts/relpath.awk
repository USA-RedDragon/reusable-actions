# Rewrites the paths a coverage tool emits into repository-relative ones.
# Loaded alongside lcov.awk or gocover.awk via a second `-f`.
#
# Neither supported format gives us what we want on its own: llvm-cov writes
# absolute paths and Go writes import paths. Both need to become relative to
# the checkout so that a baseline recorded on one runner compares against a
# report produced on another.
#
# Expects `-v strip=<prefix>`, which may be empty.

# Whether a path names a file below the current directory. The leading-slash
# test is not redundant: an absolute path from the report usually *does* open,
# which without it would end the search below before a single segment had been
# removed. getline returns -1 when the file cannot be opened, 0 at immediate
# EOF and 1 otherwise, so an empty source file still counts as present.
function here(p,   r) {
  if (substr(p, 1, 1) == "/") return 0
  if (p in _ex) return _ex[p]
  r = (getline _junk < p)
  close(p)
  return _ex[p] = (r >= 0)
}

function relpath(p,   c) {
  if (p in _rel) return _rel[p]
  c = p

  # An explicit prefix wins, and is compared with index() rather than sub() so
  # that regex metacharacters in a workspace path cannot corrupt the result.
  if (strip != "" && index(c, strip) == 1) {
    c = substr(c, length(strip) + 1)
    sub(/^\//, "", c)
    if (c != "") return _rel[p] = c
    c = p
  }

  # Otherwise drop leading segments until what remains names a file that is
  # actually here. One rule covers both formats, and unlike a fixed prefix it
  # keeps working for modules and crates nested below the repository root.
  #
  # A path that never resolves is handed back untouched. That is visible in the
  # output rather than silently wrong, and is what `strip` is there to fix.
  while (!here(c) && index(c, "/") > 0) c = substr(c, index(c, "/") + 1)
  return _rel[p] = (here(c) ? c : p)
}
