# Brief: PDF → Markdown conversion review (scholarly articles & book chapters)

You are finishing the conversion of a scholarly PDF into clean, faithful, machine-readable Markdown.
A layout-aware extractor (ODL-style: XY-cut reading order, header/footer/watermark removal,
de-hyphenation, ligature repair) already produced a **draft** Markdown. Your job is to turn the draft
into a final file that is **complete and 100% faithful** to the PDF, with correct structure.

## Absolute rules (accuracy)
1. **Never invent, paraphrase, summarise, "correct" or modernise the author's text.** Every word in the
   output must exist in the PDF. Do not add commentary, descriptions of charts, alt-text you made up,
   or missing data. If something is illegible/unresolvable, mark it `[illegible]` and log it.
2. **Do not retype body text from images.** The draft text comes from the PDF text layer and is the
   authority for wording. Restructure it (move, split, join, mark up) — don't rewrite it. Only change
   characters when you have confirmed against the page (image or `words.py`) that the draft is wrong
   (e.g. broken glyph mappings, wrong de-hyphenation, a split word, a misplaced superscript).
3. Keep **all** content: title, authors, affiliations, correspondence/footnote info, abstract, keywords,
   all sections/subsections, block quotations, lists, footnotes/endnotes, tables (every cell), figure
   captions & notes, equations, acknowledgements, funding/conflict statements, author bios, ORCID,
   data-availability statements, references (every entry), appendices / supplementary sections.
4. Remove only non-content artefacts: running heads/feet, page numbers, download/licence watermarks
   ("Downloaded from…", "This content downloaded…", EBSCO lines, Wiley "See the Terms…" side text,
   APA vertical copyright notice), publisher "cover sheets" boilerplate (JSTOR/T&F/UvA-DARE cover page:
   move their bibliographic facts into the YAML front matter — e.g. the verbatim "To cite this article"
   line goes into `citation:` — and drop the rest), stray chart-axis tick labels that leaked into prose,
   and web-print interface labels ("Google Scholar", "Google Preview", "WorldCat", "COPAC",
   "Search in this book"). Log every class of removal.

## Required output format
```markdown
---
title: "Exact title (subtitle included)"
authors: ["First Last", "First Last"]
journal: "Journal name"            # or: book_title / editors / series for a chapter
year: 2015
volume: "54"
issue: "2"
pages: "343–362"
doi: "10.xxxx/xxxx"
publisher: "…"                      # only if printed in the PDF
citation: "…"                       # only if a citation line is printed in the PDF (verbatim)
source_file: "articles/<original file name>.pdf"
source_pdf_pages: 20
converted: "2026-10-08"
---
```
Only include fields whose values are **printed in the PDF** (no outside lookup, no guessing). Omit others.

Body:
- `# Title` once. Then author line(s), affiliations, correspondence, received/accepted dates, etc.
  exactly as printed (affiliation markers as `<sup>a</sup>`).
- `## Abstract` (then the text), `**Keywords:** …` (as printed).
- Section headings with correct hierarchy: top-level sections `##`, subsections `###`, sub-sub `####`.
  Keep the original numbering and wording of headings ("2.1 Data" stays "2.1 Data"). Unnumbered run-in
  (inline italic/bold) headings in the PDF stay inline as `**Heading.** text…` / `*Heading.* text…`.
- Paragraphs: one blank line between paragraphs; a paragraph split across columns/pages must be
  rejoined into one paragraph (keep the page marker comment inline where the break occurs).
- **Page markers**: keep the `<!-- page N (printed p. X) -->` comments (N = PDF page). Make sure each
  page's marker exists and stands where that page starts; fix printed page numbers if wrong/missing
  (derive from the article's printed range only if the page number is actually printed or the range
  is printed on page 1).
- Block quotations → `> `. Lists → `-` / `1.`.
- Footnotes/endnotes → markers `[^n]` in the text exactly where the superscript stands (use the original
  note number/symbol: `[^1]`, `[^*]`→ `[^star]` if needed) and definitions `[^n]: text` collected at the
  end of the document under `## Notes` (if the original has an endnotes section, put the definitions
  where that section is, under its original heading). Multi-paragraph notes: indent continuation 4 spaces.
- **Tables** → GitHub pipe tables. Caption above as `**Table 1.** Caption text` (verbatim), table notes
  below as a normal paragraph (verbatim, e.g. `*Note:* …`). Every cell value must match the PDF exactly
  (signs, decimals, stars, parentheses, dashes). Use `./pagetext.sh` (pdftotext -layout) for the page
  plus the rendered page image to read cells; when a column header spans several columns, flatten it
  ("Model 1: Coef." …). Standard errors printed on their own line stay on their own row. Empty cells
  stay empty. Rotated/landscape tables: same treatment. If a table is genuinely too complex for a pipe
  table (nested cells), use an HTML `<table>`; never drop cells.
- **Figures** → crop the figure region (graphic only, without caption) to PNG with
  `crop.sh <pdf> <page> x0 top x1 bottom <outdir>/figures/<slug>-fig<N>.png 150` (coordinates in PDF
  points: use `words.py`/the `*.layout.json` lines and the rendered page to find the box; verify the crop
  by viewing it). Insert `![Figure N](figures/<slug>-figN.png)` followed by the verbatim caption
  `**Figure N.** caption` and any figure notes/sources. Remove the leaked axis labels / legend words of
  the chart from the prose. Do not describe the figure. Photos/maps/logos that are content: same way.
  Publisher logos/cover thumbnails/CrossMark icons: drop.
- Equations → LaTeX `$…$` / `$$…$$` reproducing the printed equation exactly.
- Italics → `*…*` (journal/book titles in references, emphasis, statistical symbols like *p*, *N*).
  Bold → `**…**` where bold in the original. Don't over-mark.
- `## References` (or the original heading, e.g. "Bibliography") — one entry per paragraph (blank line
  between), each entry complete and on one line; fix line-break hyphens inside URLs/DOIs (no spaces in
  URLs). Keep hanging entries' original text and order.
- Appendices / supplementary material after references (or wherever they are), with their headings.
- Special characters: keep diacritics, en/em dashes, minus signs (−), ×, ≤, ≥, Greek letters, curly quotes
  as printed. Draft text may contain `(cid:N)` or other wrong glyphs from broken font encodings: work
  out the true character from the page image for each distinct code **in that document** (e.g. `=`,
  `<`, `−`, `©`, `–`), replace consistently, and record the mapping in your log.

## Tools (all under /home/claude/pipeline/, run python with `-I`)
- `render.sh <pdf> <page> [dpi]` → PNG path; then view it with the Read tool. Use 80–110 dpi for a
  page overview; 150–200 dpi (or crop) to read small table numbers.
- `pagetext.sh <pdf> <first> [last]` → layout-preserving text of page(s) (best for tables).
- `python3 -I words.py <pdf> <page> [x0 top x1 bottom]` → words with coordinates, font and size.
- `crop.sh …` (see Figures).
- `python3 -I verify.py <pdf> <md>` → token-level fidelity vs. the PDF text layer: recall (PDF words
  present in the MD) and precision (MD words present in the PDF), top missing/extra tokens and long
  missing runs. Targets: recall ≥ 0.99 and precision ≥ 0.995 **after** discounting tokens you removed on
  purpose (axis tick labels, watermarks, cover-sheet boilerplate, web labels) and markup words.
  Investigate every long missing run and every unexplained extra token.
- Draft layout data: `<name>.layout.json` (per-page lines with x0/top/x1/bottom, font size, bold/italic).

## Procedure
1. Read this brief, then the draft. Render every page of the PDF at ~90 dpi and look at each one
   (in order), comparing against the draft: structure, reading order, headings, tables, figures, notes.
2. Fix the Markdown (edit the file in place with Edit/Write or small python scripts). Work page by page.
3. Run verify.py; resolve problems; repeat until targets are met or every remaining discrepancy is
   explained.
4. Final self-check: headings outline (`grep -n '^#' file`), every `[^n]` has exactly one definition
   and vice-versa, every table has the same column count in every row, every figure link points to an
   existing file, no `(cid:`, no `�`, no stray ```text blocks left, page markers 1..N present.
5. Write a log `<slug>.log.md` next to the output (in `_logs/`): source file, pages, structure found,
   what was removed and why, glyph mappings, tables/figures count, any uncertainty or
   unresolved issue (be honest), and the final verify.py numbers.

Return in your final message: the output path(s), verify numbers, counts (sections, tables, figures,
notes, references) and any unresolved issues. Keep it concise.

## Scratch space
Several agents run in parallel. Keep ALL your intermediate files in your own folder
`/tmp/claude-0/w/scratch/<slug>/` (create it). Never write elsewhere except your output .md, your
figures and your log.
