#!/bin/bash
# render.sh <pdf> <page> [dpi] [outdir]  -> prints PNG path of the rendered page
pdf="$1"; p="$2"; dpi="${3:-90}"; out="${4:-/tmp/claude-0/w/renders}"
mkdir -p "$out"
tag=$(basename "$pdf" .pdf | tr -c 'A-Za-z0-9\n' '_' | cut -c1-30)
h=$(echo -n "$pdf" | md5sum | cut -c1-6)
base="$out/${tag}-${h}-p${p}-${dpi}"
[ -f "$base.png" ] || pdftoppm -r "$dpi" -png -singlefile -f "$p" -l "$p" "$pdf" "$base"
echo "$base.png"
