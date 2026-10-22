# Log — PART S (PDF pp. 19–24, Appendix)

Source: /tmp/claude-0/w11/rc.pdf (repo file "Combined_Residential Constraints and the Political Geography of the Populist Radical Right_Evidence from France.pdf"), pages 19–24.
Output: /home/claude/output10/patana-2022-residential-constraints/_parts/S.md (no YAML, per addendum).

## Structure
- `## Appendix`
- `### A. Descriptive Statistics`: intro paragraph + descriptive table (6 cols, 19 rows)
- `### B. Robustness of Results to Different Model Specifications`
  - `#### 1. Table B1. Key Indicators Estimated Separately` (label + 5 model columns)
  - `#### Table B2. First-round Results` (3 models) + following paragraph
  - `#### Table B3. Analysis with Sample Restricted to Communes with Fewer than 5000 inhabitants` (3 models) + paragraph
  - `#### Table B4. Interactive Models` (3 models) + paragraph
- `### C. Qualitative Research`
  - `#### C1. Descriptive Statistics` (7-col table) + note
  - `#### C2. Qualitative Interview Protocol`: intro + numbered list 1–14 (no nested sub-questions are printed)
- B2–B4, C1, C2 are bold unnumbered caption-headings in the PDF; rendered as `####` (B1 keeps its printed "1." numbering).
- Tables: 6 (A, B1–B4, C1). Figures: 0. Notes: 0. References: 0.

## Page markers
`<!-- page 19 -->` … `<!-- page 24 -->`; the appendix prints no folios. B1 spans pp. 19–20 (p. 20 begins with the Public Services s.e. "(0.01)") and B4 spans pp. 21–22 (p. 22 begins with the Sedentary Pop.* Foreign s.e. "(0.00)"); since a comment cannot sit inside a pipe table, the p. 20 and p. 22 markers are placed immediately after those tables (before the table notes, which are on the new page). Other markers stand at the true page starts.

## Table decisions (all checked against 110-dpi renders, pdftotext -layout and words.py)
- Significance stars written inline escaped (`0.11\*\*\*`), whether printed as superscripts or inline (both occur, e.g. B1 "6.34***" inline vs "6.28" + superscript).
- Standard errors on their own rows; empty cells kept empty.
- B1: the printed header has only four "RN Vote Share" labels, standing over model columns 2–5; the first model column has no header — kept as printed (empty header cell).
- B1 AIC cells are wrapped in the PDF ("246136.5 / 9", "246083.1 / 6", "246121.2 / 9"); rejoined as 246136.59, 246083.16, 246121.29 (cell wrap, not separate values).
- B2: "Dept.-level controls" blank in model 1, as printed. "(0. 54)" in B2 and "(0. 92)" in B3 keep the printed space.
- B4: "Sedentary Pop.* Unemployment" has no printed s.e. row (none added).
- "Dept. σ2" → `Dept. σ<sup>2</sup>` (2 is a superscript). AIC italic in B2–B4 (`*AIC*`), roman in B1, per font data.
- Star legends: B1/B2 superscript stars with italic *p* → `\* *p* < 0.05, …`; B3/B4 inline stars with roman p → `\*p < 0.05, …`.
- C1: header cells bold as printed; multi-line cells joined ("Vote Le Pen 1<sup>st</sup> Round", "Share Unemployment", "Share Employment in Industry", "Rural; Peri-Urban" — compound hyphen kept). "N =" (table) vs "N=" (note) as printed; note has superscript "1<sup>st</sup>" but plain "2nd".

## Removals
None needed (no running heads, folios or watermarks on these pages). No `(cid:)` glyphs.

## verify.py (page-range PDF pp. 19–24)
pdf_tokens=1483 md_tokens=1509 recall=0.9912 precision=0.9742
Explained discrepancies:
- Missing runs: all are column-wise text-layer order of tables (pdftotext non-layout reads table columns sequentially); every cell was checked in layout mode and on images.
- σ2/1st/2nd vs σ 2/1 st/2 nd: `<sup>` tokenisation.
- AIC rejoins: missing "9","6","9" vs extra "59","16","29" (and 246136/246083/246121 counted as such).
- "perirural"/"periurban" missing vs "peri","rural","urban" extra: pdftotext dehyphenates "Peri-\nRural"/"Peri-\nUrban" across the interleaved column text.
- Extra "0","01","00","04","2" etc.: verify.py drops edge lines that look like bare page numbers or repeat (digits normalised) on ≥3 pages, e.g. table cells "0", "(0.01)" at page tops/bottoms; a direct token count with the same tokenizer on full pdftotext output gives identical counts ("0": 155 vs 155; "01": 48 vs 48).
No unexplained tokens remain.

## Self-checks
Headings outline OK; table column counts consistent per table (6/6/4/4/4/7 cols); no figures; no `(cid:`, `�` or code fences; page markers 19–24 present.
