#!/usr/bin/env python3
"""
Fidelity check: compare the word sequence of a Markdown conversion against the PDF's own
text layer (pdftotext, independent of the extractor's parser).

Reports
  * recall  : share of PDF tokens (multiset) present in the Markdown
  * precision: share of Markdown tokens present in the PDF text (catches added/fabricated text)
  * the most frequent missing / extra tokens, and long missing runs (in sequence) so that
    omitted passages can be located.

Usage: python3 -I verify.py <pdf> <md> [--first N --last M] [--ignore-file patterns.txt]
"""
import sys, re, subprocess, argparse, difflib
from collections import Counter

LIGS = {"ﬀ": "ff", "ﬁ": "fi", "ﬂ": "fl", "ﬃ": "ffi", "ﬄ": "ffl"}


def norm(s):
    for k, v in LIGS.items():
        s = s.replace(k, v)
    s = s.replace("​", "").replace("­", "")
    s = s.replace("’", "'").replace("‘", "'").replace("“", '"').replace("”", '"')
    return s


def toks(s):
    s = norm(s).lower()
    # dehyphenate line-break hyphens in raw pdf text
    s = re.sub(r"(\w)-\n(\w)", r"\1\2", s)
    s = s.replace("-", " ")
    return re.findall(r"[a-z0-9À-ɏͰ-ϿЀ-ӿ]+", s)


def md_text(md):
    md = re.sub(r"<!--.*?-->", " ", md, flags=re.S)
    md = re.sub(r"^---\n.*?\n---\n", " ", md, flags=re.S)  # front matter
    md = re.sub(r"!\[[^\]]*\]\([^)]*\)", " ", md)             # image links
    md = re.sub(r"\[\^([^\]]+)\]:?", r" \1 ", md)               # footnote markers keep number
    md = re.sub(r"</?(sup|sub|br|em|i|b|strong)\s*/?>", " ", md)
    md = re.sub(r"\]\((https?://[^)]*)\)", r"] \1 ", md)
    return md


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("pdf"); ap.add_argument("md")
    ap.add_argument("--first", type=int); ap.add_argument("--last", type=int)
    ap.add_argument("--show", type=int, default=25)
    a = ap.parse_args()
    cmd = ["pdftotext", "-enc", "UTF-8"]
    if a.first: cmd += ["-f", str(a.first)]
    if a.last: cmd += ["-l", str(a.last)]
    cmd += [a.pdf, "-"]
    raw = subprocess.run(cmd, capture_output=True, text=True).stdout
    # drop known watermark lines from the reference text
    WM = r"Downloaded from|EBSCO|legal\.ebsco|All rights reserved\. May not be reproduced|This content downloaded|about\.jstor\.org/terms|Wiley Online Library for rules|onlinelibrary\.wiley\.com/terms"
    raw = "\f".join("\n".join(l for l in pg.split("\n") if not re.search(WM, l)) for pg in raw.split("\f"))
    # drop running heads / footers: lines among the first/last 4 non-empty lines of a page that
    # repeat (digits normalised) on >=3 pages, and bare page numbers
    pages = raw.split("\f")
    edge = Counter()
    def key(l): return re.sub(r"\d+", "#", re.sub(r"\s+", " ", l.strip().lower()))
    for pg in pages:
        ls = [l for l in pg.split("\n") if l.strip()]
        for l in set(ls[:4] + ls[-4:]):
            edge[key(l)] += 1
    rep = {k for k, v in edge.items() if v >= 3}
    newpages = []
    for pg in pages:
        ls = [l for l in pg.split("\n") if l.strip()]
        head, tail = ls[:4], ls[-4:]
        keep = []
        for i, l in enumerate(ls):
            if (i < 4 or i >= len(ls) - 4) and (key(l) in rep or re.fullmatch(r"\s*\d{1,4}\s*", l)):
                continue
            keep.append(l)
        newpages.append("\n".join(keep))
    raw = "\n".join(newpages)
    P = toks(raw)
    M = toks(md_text(open(a.md, encoding="utf-8").read()))
    cp, cm = Counter(P), Counter(M)
    inter = sum((cp & cm).values())
    recall = inter / max(1, sum(cp.values()))
    prec = inter / max(1, sum(cm.values()))
    print(f"pdf_tokens={len(P)} md_tokens={len(M)} recall={recall:.4f} precision={prec:.4f}")
    miss = cp - cm
    extra = cm - cp
    print("top missing:", miss.most_common(a.show))
    print("top extra  :", extra.most_common(a.show))
    # long missing runs (sequence alignment)
    sm = difflib.SequenceMatcher(None, P, M, autojunk=False)
    runs = []
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag in ("delete", "replace") and (i2 - i1) >= 8:
            # only report if those tokens are not found elsewhere (i.e. not just moved)
            seg = P[i1:i2]
            mtxt = " " + " ".join(M) + " "
            if (" " + " ".join(seg[:6]) + " ") not in mtxt:
                runs.append((i2 - i1, " ".join(seg[:30])))
    runs.sort(reverse=True)
    print(f"missing runs (>=8 tokens, not found elsewhere): {len(runs)}")
    for n, s in runs[:15]:
        print(f"  [{n}] {s}")


if __name__ == "__main__":
    main()
