#!/usr/bin/env python3
"""words.py <pdf> <page> [x0 top x1 bottom] -> words with coordinates/font (pdfplumber), for locating
figures/tables precisely or checking characters. Coordinates in PDF points, origin top-left."""
import sys, pdfplumber
pdf = pdfplumber.open(sys.argv[1]); pg = pdf.pages[int(sys.argv[2]) - 1]
print(f"page size: {pg.width:.1f} x {pg.height:.1f} pt; images: {[(round(i['x0']),round(i['top']),round(i['x1']),round(i['bottom'])) for i in pg.images]}")
if len(sys.argv) >= 7:
    pg = pg.crop(tuple(float(v) for v in sys.argv[3:7]))
for w in pg.extract_words(extra_attrs=["size", "fontname"], x_tolerance_ratio=0.09):
    print(f"{w['x0']:7.1f} {w['top']:7.1f} {w['x1']:7.1f} {w['bottom']:7.1f} {w['size']:5.1f} {w['fontname'][-22:]:>22} {w['text']}")
