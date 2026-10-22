#!/usr/bin/env python3
"""Structural QA for a final Markdown conversion. Usage: qa.py <md> <pdf_pages>"""
import sys, re, os
md_path, npages = sys.argv[1], int(sys.argv[2])
s = open(md_path, encoding="utf-8").read()
d = os.path.dirname(md_path)
issues = []
# footnotes
refs = re.findall(r"\[\^([^\]]+)\](?!:)", s)
defs = re.findall(r"^\[\^([^\]]+)\]:", s, flags=re.M)
from collections import Counter
cd = Counter(defs)
for k, v in cd.items():
    if v > 1: issues.append(f"duplicate footnote definition {k}")
for k in set(refs) - set(defs): issues.append(f"marker without definition {k}")
for k in set(defs) - set(refs): issues.append(f"definition without marker {k}")
# tables
lines = s.split("\n")
i = 0; ntables = 0
while i < len(lines):
    if lines[i].startswith("|") and i + 1 < len(lines) and re.match(r"^\|\s*:?-{2,}", lines[i + 1]):
        ntables += 1
        def ncol(l): return len(re.findall(r"(?<!\\)\|", l.strip())) - 1
        n = ncol(lines[i]); j = i
        while j < len(lines) and lines[j].startswith("|"):
            if ncol(lines[j]) != n: issues.append(f"table col mismatch line {j+1}")
            j += 1
        i = j
    else:
        i += 1
ntables += len(re.findall(r"<table", s))
# figures
figs = re.findall(r"!\[[^\]]*\]\(([^)]+)\)", s)
for f in figs:
    if not os.path.exists(os.path.join(d, f)): issues.append(f"missing figure file {f}")
# page markers
pm = [int(x) for x in re.findall(r"<!-- page (\d+)", s)]
missing = sorted(set(range(1, npages + 1)) - set(pm))
if pm != sorted(pm): issues.append("page markers out of order")
# artefacts
for pat, name in [(r"\(cid:\d+\)", "cid"), ("�", "U+FFFD"), ("\x00", "NUL"), (r"```text", "text-block")]:
    c = len(re.findall(pat, s))
    if c: issues.append(f"{c} x {name}")
nh = len(re.findall(r"^#{1,6} ", s, flags=re.M))
print(f"{os.path.basename(md_path)} | headings={nh} tables={ntables} figures={len(figs)} notes={len(set(defs))} "
      f"pages_marked={len(set(pm))}/{npages} missing_pages={missing[:20]} issues={issues[:10]}")
