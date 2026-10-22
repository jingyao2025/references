import sys, re, subprocess
sys.path.insert(0, '/home/claude/pipeline'); import verify
pdf, md = sys.argv[1], sys.argv[2]
M = " " + " ".join(verify.toks(verify.md_text(open(md, encoding='utf-8').read()))) + " "
raw = subprocess.run(['pdftotext', '-layout', pdf, '-'], capture_output=True, text=True).stdout
bad = []
for pno, pg in enumerate(raw.split('\f'), 1):
    for line in pg.split('\n'):
        l = line.strip()
        if not l or re.search(r'Downloaded from|Google Scholar|WorldCat|COPAC|Google Preview', l): continue
        # take each column chunk separately (split on wide gaps)
        for chunk in re.split(r'\s{4,}', l):
            t = verify.toks(chunk)
            words = [x for x in t if re.fullmatch(r'[a-zÀ-ɏ]{3,}', x)]
            if len(words) < 6 or len(words) < 0.7 * len(t): continue   # prose-like only
            # check sliding 5-grams; flag the chunk if none of them appear in the MD
            grams = [" " + " ".join(t[i:i+5]) + " " for i in range(0, max(1, len(t) - 4))]
            hit = sum(1 for g in grams if g in M)
            if hit / len(grams) < 0.5:
                bad.append((pno, chunk[:140]))
print(f"prose chunks not found in MD: {len(bad)}")
for p, c in bad: print(f"  p{p}: {c}")
