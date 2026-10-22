#!/bin/bash
# crop.sh <pdf> <page> <x0> <top> <x1> <bottom> <out.png> [dpi]
# Coordinates in PDF points (origin top-left, as in pdfplumber / *.layout.json). Default 150 dpi.
pdf="$1"; p="$2"; x0="$3"; y0="$4"; x1="$5"; y1="$6"; out="$7"; dpi="${8:-150}"
s=$(python3 -c "print($dpi/72)")
X=$(python3 -c "print(int($x0*$s))"); Y=$(python3 -c "print(int($y0*$s))")
W=$(python3 -c "print(int(($x1-$x0)*$s))"); H=$(python3 -c "print(int(($y1-$y0)*$s))")
mkdir -p "$(dirname "$out")"
pdftoppm -r "$dpi" -png -singlefile -f "$p" -l "$p" -x "$X" -y "$Y" -W "$W" -H "$H" "$pdf" "${out%.png}"
echo "$out"
