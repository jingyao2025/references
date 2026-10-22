#!/usr/bin/env python3
"""
Layout-aware PDF -> draft Markdown extractor.

Design follows the opendataloader-pdf (ODL) approach (rule-based, local, deterministic):
  * character-level parsing with font metadata (size / weight / style)
  * content-safety filtering of off-page and rotated (watermark) text
  * XY-cut reading order with column (gutter) detection
  * header / footer / running-head / watermark removal by position + repetition
  * heading detection from font size & weight relative to the body text size
  * paragraph reconstruction with dictionary-based de-hyphenation
  * table-like regions are flagged (kept with spatial layout) for structured rebuild
  * page-boundary markers retained so citations can point to original pages

Output: a draft Markdown file + a JSON sidecar with per-page block data.
The draft is subsequently reviewed against rendered page images.

Usage: python3 -I extract.py <pdf> <out_dir> [--first N] [--last M] [--pageoffset K]
"""
import sys, os, re, json, statistics, argparse
from collections import Counter, defaultdict
import pdfplumber

HERE = os.path.dirname(os.path.abspath(__file__))
WORDS_FILE = "/tmp/claude-0/odl/english-words/words_alpha.txt"

LIGS = {"ﬀ": "ff", "ﬁ": "fi", "ﬂ": "fl", "ﬃ": "ffi", "ﬄ": "ffl",
        "ﬅ": "st", "ﬆ": "st"}

WATERMARK_PATTERNS = [
    r"^Downloaded from ",
    r"Downloaded from https?://",
    r"^This content downloaded from",
    r"All use subject to https?://about\.jstor\.org/terms",
    r"EBSCO Publishing",
    r"EBSCOhost",
    r"^All rights reserved\. May not be reproduced in any form",
    r"legal\.ebsco\.com",
    r"^Copyright ©? ?\d{4}\. Routledge\. All rights reserved",
    r"by guest on \w+ \d{1,2}, \d{4}$",
    r"^Brought to you by",
    r"onlinelibrary\.wiley\.com/terms-and-conditions",
    r"See the Terms and Conditions \(https",
    r"Wiley Online Library for rules of use",
    r"^\d{14,}, \d{4}, \d+, Downloaded from",
]
WM_RE = [re.compile(p) for p in WATERMARK_PATTERNS]


def load_dict():
    d = set()
    try:
        with open(WORDS_FILE) as f:
            for w in f:
                d.add(w.strip().lower())
    except FileNotFoundError:
        pass
    return d


DICT = load_dict()


def norm_text(s):
    for k, v in LIGS.items():
        s = s.replace(k, v)
    # zero-width spaces / soft hyphen artefacts
    s = s.replace("​", "").replace("­", "-").replace("﻿", "")
    return s


def is_bold(fontname):
    f = fontname.lower()
    return any(k in f for k in ["bold", "black", "heavy", "semibold", "demibold", "-bd", ",bold"]) \
        or re.search(r"-(b|bi|sb|semibold)$", f) is not None


def is_italic(fontname):
    f = fontname.lower()
    return any(k in f for k in ["italic", "oblique", "-it", ",it", "ital"]) or re.search(r"-(bi|i)$", f) is not None


# ---------------------------------------------------------------- words/lines
class Word:
    __slots__ = ("text", "x0", "x1", "top", "bottom", "size", "font", "bold", "italic", "sup")

    def __init__(self, w):
        self.text = norm_text(w["text"])
        self.x0, self.x1, self.top, self.bottom = w["x0"], w["x1"], w["top"], w["bottom"]
        self.size = round(w.get("size", 0), 1)
        self.font = w.get("fontname", "")
        self.bold = is_bold(self.font)
        self.italic = is_italic(self.font)
        self.sup = False


def page_words(page):
    """Upright, on-page words with font info. Rotated text (side watermarks) is dropped."""
    W, H = page.width, page.height
    p = page.filter(lambda o: o.get("object_type") != "char" or (
        o.get("upright", True) and -1 <= o["x0"] <= W + 1 and -1 <= o["top"] <= H + 1
        and (o.get("non_stroking_color") is None or True)))
    ws = p.extract_words(extra_attrs=["size", "fontname"], keep_blank_chars=False,
                         x_tolerance_ratio=0.09, y_tolerance=2.5, use_text_flow=False)
    ws = [w for w in ws if w["text"].strip()]
    # re-join words split around ligature glyphs (e.g. "signi" + "ﬁ" + "cant")
    merged = []
    LIG = set(LIGS.keys())
    for w in ws:
        if merged:
            pv = merged[-1]
            gap = w["x0"] - pv["x1"]
            same = abs(w["bottom"] - pv["bottom"]) < 3.0 or abs(w["top"] - pv["top"]) < 3.0
            LW = {"ff", "fi", "fl", "ffi", "ffl"} | LIG
            pvl = pv.get("_lig", False) or pv["text"] in LW
            sz_ok = abs(w.get("size", 10) - pv.get("size", 10)) <= 0.15 * max(1, pv.get("size", 10))
            if same and sz_ok and -0.5 < gap < 0.08 * max(1, w.get("size", 10)):
                pv = dict(pv)
                pv["text"] = pv["text"] + w["text"]
                pv["x1"] = w["x1"]
                pv["bottom"] = max(pv["bottom"], w["bottom"])
                pv["top"] = max(pv["top"], w["top"]) if w["text"] not in LW else pv["top"]
                pv["_lig"] = w["text"] in LW
                merged[-1] = pv
                continue
        merged.append(w)
    out = [Word(w) for w in merged]
    return out


def group_lines(words, ytol=None):
    """Group words into lines by vertical overlap (assumes words are in one column)."""
    if not words:
        return []
    words = sorted(words, key=lambda w: (round(w.top), w.x0))
    lines = []
    for w in sorted(words, key=lambda w: (w.top + w.bottom) / 2):
        mid = (w.top + w.bottom) / 2
        placed = False
        for ln in lines[-4:]:
            ltop = min(x.top for x in ln)
            lbot = max(x.bottom for x in ln)
            # vertical overlap with the main body of the line
            core_h = statistics.median([x.bottom - x.top for x in ln])
            lmid = statistics.median([(x.top + x.bottom) / 2 for x in ln])
            if abs(mid - lmid) <= max(2.5, core_h * 0.45) or (w.size < 0.8 * statistics.median([x.size for x in ln]) and ltop - 2 <= mid <= lbot + 1):
                ln.append(w)
                placed = True
                break
        if not placed:
            lines.append([w])
    res = []
    for ln in lines:
        ln.sort(key=lambda w: w.x0)
        med = statistics.median([w.size for w in ln])
        base = statistics.median([w.bottom for w in ln if w.size >= med * 0.9] or [w.bottom for w in ln])
        for w in ln:
            if w.size < med * 0.82 and w.bottom < base - 1.0 and len(w.text) <= 6:
                w.sup = True
        res.append(ln)
    res.sort(key=lambda ln: statistics.median([w.top for w in ln]))
    return res


# ---------------------------------------------------------------- XY cut
def _gaps(intervals, lo, hi, min_gap):
    intervals = sorted(intervals)
    gaps = []
    cur = lo
    for a, b in intervals:
        if a - cur >= min_gap:
            gaps.append((cur, a))
        cur = max(cur, b)
    if hi - cur >= min_gap:
        gaps.append((cur, hi))
    return gaps


def find_gutter(words, page_w):
    """Vertical whitespace channel splitting text columns (near the page middle area)."""
    if len(words) < 12:
        return None
    x0 = min(w.x0 for w in words)
    x1 = max(w.x1 for w in words)
    width = x1 - x0
    if width < page_w * 0.45:
        return None
    gaps = _gaps([(w.x0, w.x1) for w in words], x0, x1, 6.0)
    best = None
    for a, b in gaps:
        if a <= x0 + 1 or b >= x1 - 1:
            continue
        c = (a + b) / 2
        if not (x0 + width * 0.25 <= c <= x0 + width * 0.75):
            continue
        left = [w for w in words if w.x1 <= a + 0.5]
        right = [w for w in words if w.x0 >= b - 0.5]
        if len(left) < 6 or len(right) < 6:
            continue
        # columns of running text: lines span a good part of each column
        lw = max(w.x1 for w in left) - min(w.x0 for w in left)
        rw = max(w.x1 for w in right) - min(w.x0 for w in right)
        if lw < width * 0.28 or rw < width * 0.28:
            continue
        if best is None or (b - a) > (best[1] - best[0]):
            best = (a, b)
    return best


def xycut(words, page_w, depth=0):
    """Returns list of regions (each a list of words) in reading order."""
    if not words or depth > 12:
        return [words] if words else []
    g = find_gutter(words, page_w)
    if g:
        a, b = g
        left = [w for w in words if (w.x0 + w.x1) / 2 < (a + b) / 2]
        right = [w for w in words if (w.x0 + w.x1) / 2 >= (a + b) / 2]
        return xycut(left, page_w, depth + 1) + xycut(right, page_w, depth + 1)
    # horizontal bands
    sizes = [w.size for w in words]
    body = statistics.median(sizes) if sizes else 10
    y0 = min(w.top for w in words)
    y1 = max(w.bottom for w in words)
    hg = _gaps([(w.top, w.bottom) for w in words], y0, y1, max(4.0, body * 0.55))
    if not hg:
        return [words]
    cuts = [(a + b) / 2 for a, b in hg]
    bands = []
    prev = y0 - 1
    for c in cuts + [y1 + 1]:
        band = [w for w in words if prev <= (w.top + w.bottom) / 2 < c]
        if band:
            bands.append(band)
        prev = c
    if len(bands) <= 1:
        return [words]
    # merge consecutive bands that share a column gutter
    groups = []
    for band in bands:
        gb = find_gutter(band, page_w) if len(band) >= 12 else None
        if groups and gb and groups[-1][1]:
            ga = groups[-1][1]
            if gb[0] < ga[1] and ga[0] < gb[1]:
                merged = groups[-1][0] + band
                groups[-1] = (merged, (max(ga[0], gb[0]), min(ga[1], gb[1])))
                continue
        groups.append((band, gb))
    out = []
    for band, gb in groups:
        if gb:
            a, b = gb
            # verify the merged group still has a clean gutter
            if all(not (w.x0 < a - 0.5 and w.x1 > b + 0.5) for w in band):
                left = [w for w in band if (w.x0 + w.x1) / 2 < (a + b) / 2]
                right = [w for w in band if (w.x0 + w.x1) / 2 >= (a + b) / 2]
                out += xycut(left, page_w, depth + 1) + xycut(right, page_w, depth + 1)
                continue
        out.append(band)
    return out


# ---------------------------------------------------------------- page model
def line_text(ln, mark_sup=True, mark_italic=True):
    parts = []
    prev = None
    for w in ln:
        t = w.text
        if mark_sup and w.sup:
            t = "<sup>" + t + "</sup>"
        sep = ""
        if prev is not None:
            gap = w.x0 - prev.x1
            sep = " " if gap > 0.8 or not (w.sup or prev.sup) else ""
            if w.sup and gap < 1.0:
                sep = ""
        parts.append((sep, t, w.italic and mark_italic and not w.sup, w.bold))
        prev = w
    # merge italic runs
    s = ""
    i = 0
    n = len(parts)
    while i < n:
        sep, t, it, bd = parts[i]
        if it and re.search(r"[A-Za-z]", t):
            j = i
            run = []
            while j < n and parts[j][2]:
                run.append((parts[j][0] if j > i else "", parts[j][1]))
                j += 1
            txt = "".join(a + b for a, b in run)
            m = re.match(r"^(\W*)(.*?)(\W*)$", txt, re.S)
            if m and m.group(2):
                s += sep + m.group(1) + "*" + m.group(2) + "*" + m.group(3)
            else:
                s += sep + txt
            i = j
        else:
            s += sep + t
            i += 1
    return s.strip()


def plain(ln):
    return " ".join(w.text for w in ln).strip()


def norm_rep(s):
    s = re.sub(r"\d+", "#", s.lower())
    s = re.sub(r"\s+", " ", s).strip()
    return s


def is_watermark(text):
    return any(r.search(text) for r in WM_RE)


def analyse(pdf_path, first=None, last=None):
    pdf = pdfplumber.open(pdf_path)
    n = len(pdf.pages)
    first = first or 1
    last = last or n
    pages = []
    for pi in range(first - 1, last):
        page = pdf.pages[pi]
        try:
            words = page_words(page)
        except Exception as e:
            words = []
            print(f"WARN page {pi+1}: {e}", file=sys.stderr)
        nchar = len(page.chars)
        nup = sum(1 for c in page.chars if c.get("upright", True))
        rotated = None
        if nchar > 200 and nup < 0.5 * nchar:
            import subprocess
            rotated = subprocess.run(["pdftotext", "-layout", "-f", str(pi + 1), "-l", str(pi + 1), pdf_path, "-"],
                                     capture_output=True, text=True).stdout
            rotated = "\n".join(l.rstrip() for l in rotated.splitlines() if l.strip() and not is_watermark(l.strip()))
        pages.append({"index": pi + 1, "w": float(page.width), "h": float(page.height), "rotated": rotated,
                      "words": words, "images": [(round(i["x0"]), round(i["top"]), round(i["x1"]), round(i["bottom"])) for i in page.images
                                                  if (i["x1"] - i["x0"]) > 40 and (i["bottom"] - i["top"]) > 40]})
    return pdf, pages


def body_size(pages):
    c = Counter()
    for p in pages:
        for w in p["words"]:
            c[w.size] += len(w.text)
    return c.most_common(1)[0][0] if c else 10.0


def detect_margins(pages):
    """Find repeated header/footer lines: text in the top/bottom 9% repeating across pages."""
    rep = Counter()
    per_page = []
    for p in pages:
        H = p["h"]
        lines = group_lines([w for w in p["words"] if w.top < H * 0.09 or w.bottom > H * 0.91])
        keys = set()
        for ln in lines:
            keys.add(norm_rep(plain(ln)))
        per_page.append(keys)
        for k in keys:
            rep[k] += 1
    thr = max(2, int(len(pages) * 0.2))
    return {k for k, v in rep.items() if v >= thr and k}


PAGENUM_RE = re.compile(r"^(?:[ivxlcdm]+|\d{1,4})$", re.I)


def build(pdf_path, out_dir, first=None, last=None):
    pdf, pages = analyse(pdf_path, first, last)
    bsize = body_size(pages)
    reps = detect_margins(pages)
    doc_vocab = Counter()
    for p in pages:
        for w in p["words"]:
            for t in re.findall(r"[A-Za-z][A-Za-z\-]+[A-Za-z]", w.text):
                doc_vocab[t.lower()] += 1

    page_records = []
    for p in pages:
        H, W = p["h"], p["w"]
        words = p["words"]
        printed = None
        # remove header/footer lines
        keep = []
        margin_lines = group_lines([w for w in words if w.top < H * 0.09 or w.bottom > H * 0.91])
        drop_ids = set()
        for ln in margin_lines:
            t = plain(ln)
            k = norm_rep(t)
            if k in reps or PAGENUM_RE.match(t) or is_watermark(t) or re.match(r"^\d{1,4}\s", t) and k in reps:
                for w in ln:
                    drop_ids.add(id(w))
                m = re.match(r"^(\d{1,4})\b|\b(\d{1,4})$", t)
                if m and printed is None:
                    printed = m.group(1) or m.group(2)
            elif re.fullmatch(r"\d{1,4}", t.strip()):
                printed = t.strip()
                for w in ln:
                    drop_ids.add(id(w))
        # watermark lines anywhere
        all_lines = group_lines([w for w in words if id(w) not in drop_ids])
        for ln in all_lines:
            if is_watermark(plain(ln)):
                for w in ln:
                    drop_ids.add(id(w))
        keep = [w for w in words if id(w) not in drop_ids]
        regions = xycut(keep, W)
        blocks = []
        for reg in regions:
            lines = group_lines(reg)
            for ln in lines:
                sz = statistics.median([w.size for w in ln if not w.sup] or [w.size for w in ln])
                gaps = [ln[i + 1].x0 - ln[i].x1 for i in range(len(ln) - 1)]
                big = sum(1 for g in gaps if g > max(8.0, bsize * 1.2))
                blocks.append({
                    "x0": round(min(w.x0 for w in ln), 1), "x1": round(max(w.x1 for w in ln), 1),
                    "top": round(min(w.top for w in ln), 1), "bottom": round(max(w.bottom for w in ln), 1),
                    "size": sz, "bold": all(w.bold for w in ln if re.search(r"\w", w.text)),
                    "italic": all(w.italic for w in ln if re.search(r"\w", w.text)),
                    "big_gaps": big, "text": line_text(ln), "plain": plain(ln),
                    "region": id(reg) % 100000,
                    "spaced": " ".join(w.text for w in ln) if big < 2 else _spaced(ln),
                })
        page_records.append({"index": p["index"], "printed": printed, "w": W, "h": H, "rotated": p.get("rotated"),
                             "images": p["images"], "lines": blocks})
    return page_records, bsize, doc_vocab


def _spaced(ln):
    s = ""
    cur = ln[0].x0
    for i, w in enumerate(ln):
        if i:
            gap = w.x0 - ln[i - 1].x1
            s += " " * (1 if gap < 6 else max(3, int(gap / 4)))
        s += w.text
    return s


# ---------------------------------------------------------------- markdown
def dehyphen(a, b, vocab):
    """Join a line ending with '-' to the next line's first word."""
    m1 = re.search(r"([A-Za-z]+)-$", a)
    m2 = re.match(r"^([A-Za-z]+)", b)
    if not m1 or not m2:
        return a + b  # keep hyphen e.g. numbers / dashes
    f1, f2 = m1.group(1), m2.group(1)
    joined = (f1 + f2).lower()
    hyph = (f1 + "-" + f2).lower()
    if f2[0].isupper():
        return a + b  # e.g. "Anglo-Saxon", "post-Brexit"
    if vocab.get(hyph, 0) > 0 and vocab.get(joined, 0) == 0:
        return a + b
    if joined in DICT or vocab.get(joined, 0) > 0:
        return a[:-1] + b
    if (f1.lower() in DICT and len(f1) > 2) and (f2.lower() in DICT and len(f2) > 2):
        return a + b
    return a[:-1] + b


def to_markdown(page_records, bsize, vocab, meta_header=""):
    out = []
    para = ""
    prev = None
    tab_buf = []

    def flush():
        nonlocal para
        if para.strip():
            out.append(para.strip())
            out.append("")
        para = ""

    def flush_tab():
        nonlocal tab_buf
        if tab_buf:
            flush()
            out.append("```text")
            out.extend(tab_buf)
            out.append("```")
            out.append("")
            tab_buf = []

    for pr in page_records:
        label = pr["printed"] or ""
        marker = f"<!-- page {pr['index']}" + (f" (printed p. {label})" if label else "") + " -->"
        if para.strip():
            para += " " + marker + " "
        else:
            out.append(marker)
            out.append("")
        if pr["images"]:
            for im in pr["images"]:
                out.append(f"<!-- image region on pdf page {pr['index']} bbox={list(im)} -->")
            out.append("")
        lines = pr["lines"]
        if pr.get("rotated"):
            flush()
            out.append(f"<!-- rotated (landscape) page {pr['index']}: text taken from pdftotext -layout -->")
            out.append("```text")
            out.extend(pr["rotated"].splitlines())
            out.append("```")
            out.append("")
        for i, ln in enumerate(lines):
            t = ln["text"]
            if not t:
                continue
            is_head = (ln["size"] >= bsize + 1.2 or (ln["bold"] and len(ln["plain"]) < 120 and ln["size"] >= bsize - 0.6)) \
                and len(ln["plain"]) < 200 and not ln["big_gaps"] >= 2
            small = ln["size"] <= bsize - 1.2
            if ln["big_gaps"] >= 2:
                flush()
                tab_buf.append(ln["spaced"])
                prev = ln
                continue
            else:
                flush_tab()
            if is_head:
                flush()
                lvl = "##" if ln["size"] >= bsize + 1.2 else "###"
                if ln["size"] >= bsize + 5:
                    lvl = "#"
                # merge multi-line headings
                if out and out[-1] == "" and len(out) >= 2 and out[-2].startswith(lvl + " ") and prev is not None and \
                        prev.get("_head") and abs(prev["size"] - ln["size"]) < 0.3 and 0 <= ln["top"] - prev["bottom"] < ln["size"] * 1.2:
                    out[-2] = out[-2] + " " + re.sub(r"^\*\*|\*\*$", "", t)
                else:
                    out.append(f"{lvl} {t.strip('*') if t.startswith('**') else t}")
                    out.append("")
                ln["_head"] = True
                prev = ln
                continue
            new_para = False
            if prev is None or prev.get("_head"):
                new_para = True
            else:
                vgap = ln["top"] - prev["bottom"]
                same_region = ln["region"] == prev["region"]
                indent = ln["x0"] - prev["x0"]
                if abs(ln["size"] - prev["size"]) > 0.8:
                    new_para = True
                elif same_region and vgap > ln["size"] * 0.9:
                    new_para = True
                elif same_region and indent > ln["size"] * 0.6 and vgap < ln["size"] * 1.5:
                    new_para = True
                elif same_region and indent < -ln["size"] * 0.6 and re.search(r"[.:?!\"’”)]$", prev["plain"]):
                    new_para = True
            if new_para:
                flush()
                para = t
            else:
                if para.endswith("-") and not para.endswith("--"):
                    para = dehyphen(para, t, vocab)
                elif para.endswith("–") or para.endswith("—") or para.endswith("/"):
                    para = para + t
                else:
                    para = para + " " + t
            prev = ln
        flush_tab()
    flush()
    md = "\n".join(out)
    md = re.sub(r"\n{3,}", "\n\n", md)
    # resolve NUL glyphs (unmapped ligatures such as ff/ft/fi/fl in web-printed pages)
    def _fixnul(m):
        w = m.group(0)
        for cand in ["ff", "ft", "fi", "fl", "ffi", "ffl", "tt", "th"]:
            t = w.replace("\x00", cand)
            core = re.sub(r"[^A-Za-z]", "", t).lower()
            if core and (core in DICT or vocab.get(core, 0) > 0):
                return t
        return w.replace("\x00", "\ufffd")
    md = re.sub(r"[A-Za-z\x00]*\x00[A-Za-z\x00]*", _fixnul, md)
    # merge adjacent italic spans: "*a* *b*" -> "*a b*"
    md = re.sub(r"(?<=[^\s*])\* \*(?=[^\s*])", " ", md)
    md = re.sub(r"\* ([,.;:)])", r"*\1", md)
    return md


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("pdf")
    ap.add_argument("out_dir")
    ap.add_argument("--first", type=int)
    ap.add_argument("--last", type=int)
    ap.add_argument("--name")
    a = ap.parse_args()
    os.makedirs(a.out_dir, exist_ok=True)
    recs, bsize, vocab = build(a.pdf, a.out_dir, a.first, a.last)
    name = a.name or "draft"
    md = to_markdown(recs, bsize, vocab)
    with open(os.path.join(a.out_dir, name + ".md"), "w") as f:
        f.write(md)
    with open(os.path.join(a.out_dir, name + ".layout.json"), "w") as f:
        json.dump({"body_size": bsize, "pages": [{k: v for k, v in r.items()} for r in recs]}, f, ensure_ascii=False, indent=0)
    print(f"ok pages={len(recs)} body={bsize} chars={len(md)}")


if __name__ == "__main__":
    main()
