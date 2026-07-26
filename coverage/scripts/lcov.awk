# LCOV to `path<TAB>found<TAB>hit`. Load after relpath.awk.
#
# DA records are preferred wherever a file has them, because they survive the
# merging below; the LF/LH summary is only consulted for files that carry none.

/^SF:/ { file = relpath(substr($0, 4)); files[file] = 1; next }

/^DA:/ {
  split(substr($0, 4), a, ",")
  k = file SUBSEP (a[1] + 0)
  # Merge repeated records for a single line, as a file instrumented into
  # several test binaries produces. Hit beats not-hit.
  if (!(k in da) || a[2] + 0 > da[k]) da[k] = a[2] + 0
  hasda[file] = 1
  next
}

# Max rather than sum: a repeated SF block describes the same file twice, so
# adding the totals would count every line of it again.
/^LF:/ { if (substr($0, 4) + 0 > lf[file]) lf[file] = substr($0, 4) + 0; next }
/^LH:/ { if (substr($0, 4) + 0 > lh[file]) lh[file] = substr($0, 4) + 0; next }

/^end_of_record/ { file = ""; next }

END {
  for (k in da) {
    split(k, p, SUBSEP)
    found[p[1]]++
    if (da[k] > 0) hit[p[1]]++
  }
  for (f in files)
    if (f in hasda) print f "\t" found[f] "\t" (hit[f] + 0)
    else            print f "\t" (lf[f] + 0) "\t" (lh[f] + 0)
}
