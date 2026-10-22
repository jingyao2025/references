# Conversion log

Date: 2026-10-08 · Source: https://github.com/jingyao2025/references (commit `93c8acd`)

## 1. Method

1. **Inventory & layout analysis** of all 26 PDFs: page counts, text layer present or not, tagged or not, producer, MD5 duplicates, cover sheets, rotated pages, columns, broken font encodings.
2. **Draft extraction** with a layout-aware extractor (`_tools/extract.py`) modelled on the opendataloader-pdf (ODL) pipeline: character-level parsing with font size/weight/style; removal of off-page and rotated watermark text; XY-cut reading order with column-gutter detection; header/footer/running-head removal by position + repetition; heading detection by font size/weight; paragraph reconstruction with dictionary-based de-hyphenation; ligature repair; rotated (landscape) pages captured with a layout-preserving fallback; page markers.
3. **Page-by-page review** of every document against rendered page images (one reviewer per article, one per 18–45-page book chunk), following `_tools/AGENT_BRIEF.md` (and `BOOK_BRIEF.md` for books): restore structure, rebuild every table cell from the page, crop figures, place footnotes, repair references, resolve broken glyphs — without retyping or paraphrasing the author's text.
4. **Verification** (ODL skill principle "a zero exit code does not mean extraction succeeded"):
   - `_tools/verify.py`: word-level recall/precision against the PDF's own text layer (independent parser: poppler `pdftotext`) plus a list of long missing passages; every remaining discrepancy was investigated and explained in the per-document log.
   - `_tools/qa.py`: every note marker has exactly one definition, table rows have constant column counts, every figure link resolves, page markers cover every page in order, no `(cid:)`, `U+FFFD`, NUL or leftover raw blocks.
   - Additional check that decimal numbers (table values) of the PDF are present in the Markdown; the only absent decimals are chart tick labels, footer DOIs and numbers glued to footnote markers in the text layer.
5. **Books**: the article workflow was reused unchanged and applied in parallel chunks (7 for Sondel-Cedarmas & Berti, 6 for Green-Pedersen); chunks were then merged under one heading scheme and also split into per-chapter files.

## 2. Troubleshooting (issues met and how they were resolved)

| Issue | Resolution |
|---|---|
| **opendataloader-pdf could not be installed**: in this cloud sandbox PyPI, Maven Central and the npm registry are blocked by the network egress policy (403 / DNS failure); ODL needs its Java jar or the PyPI/npm package. | Cloned the ODL repository from GitHub (reachable) and followed its documented approach and its `odl-pdf` skill (verify-don't-trust, silent-failure checks) with an equivalent local pipeline built on pdfplumber, poppler (`pdftotext`, `pdftoppm`) and tesseract. |
| No system dictionary for de-hyphenation | Used the open `dwyl/english-words` list + each document's own vocabulary; hard cases checked by reviewers on the page image. |
| Words split by tight justification / ligature glyphs / separately drawn accents ("signi fi cant", "Kaczy ń ski") | Ratio-based word tolerance and merging of zero-gap fragments of equal size. |
| Rotated landscape table pages dropped by the upright-text filter (Green-Pedersen 2007 pp. 13–16 and others) | Detected pages with mostly rotated text and captured them with `pdftotext -layout`; tables then rebuilt from the page images. |
| Broken font encodings `(cid:N)` (Bélanger & Meguid 2008; Spoon & Klüver 2014; Feinberg et al. 2020; Meguid et al. 2025; Seeberg; Green-Pedersen 2019 tables) — same code meaning different symbols in different fonts | Mapped per document and per font from the page images (e.g. `=`, `<`, `≤`, `−`, `×`, `η`, `©`); mappings listed in each log. |
| Elsevier 2008 text layer encodes en dashes as `e`, `+` as `þ`, `=` as `¼` | Corrected from page images (log: belanger-meguid). |
| OUP web-printed reference pages: ligatures (ff/ft) encoded as NUL; modifier-letter quotes ʻ ʼ; "Google Scholar / WorldCat / COPAC" link rows | Ligatures restored and checked against page images (60 cases); quotes normalised to ‘ ’; link labels removed. |
| OUP PDF has a non-zero CropBox origin, offsetting figure crops | Offset corrected; every crop viewed. |
| Brader & Tucker 2012 is a JSTOR scan whose text layer is OCR with errors ("HI." for H1, ρ for p, broken words) | Each error corrected from the page image at 90–200 dpi; full list in `_logs/brader-tucker-2012-….log.md`. |
| `Do parties respond___.pdf` is image-only | OCR'd all pages to confirm it is the same article as the text-layer PDF; converted once. |
| Inconsistent handling of the OUP chapter-opener footers (chapter DOIs) between book chunks | Standardised: the footer line with the chapter DOI is kept under every chapter heading of Green-Pedersen 2019 (its wording is identical on every chapter opener; only the DOI suffix differs). |

## 3. Decisions

- Publisher download cover sheets (JSTOR, Taylor & Francis, UvA-DARE, EBSCO) are not article content: their bibliographic facts (incl. the verbatim citation line) are in the YAML front matter, the rest is dropped.
- Book front matter: Contents, List of figures/tables and Notes on contributors are kept at the start (Sondel-Cedarmas & Berti); the half-title blurb, series page, title page and copyright/CIP page are kept verbatim at the end of the book file ("Publisher front matter (as printed)") so the file opens with the main content. Cover, blank/logo pages and the Index are omitted.
- The "Citation formats" box at the top of each book is compiled exclusively from facts printed in the PDF and is clearly labelled as not part of the original. Green-Pedersen 2019's PDF has no title page or place of publication, so no place is given.
- Coffé et al. 2023 (Ch. 27): the handbook title, editors and publisher are not printed on its pages, so they are not in its YAML (only title, authors, chapter number, pages, DOI).
- Green-Pedersen 2019's PDF contains no table of contents, list of figures or index; nothing was generated in their place.
- Authors' typos, inconsistent citations and odd spellings are reproduced as printed (examples listed in the logs).

## 4. Known limitations

- Figures are embedded as images; chart data were not re-digitised (doing so would require estimation).
- Tables with spanning column headers are flattened into single header rows; values are unchanged.
- In a few places a table or figure that interrupts a paragraph is placed after that paragraph; an HTML comment marks the printed page.
- Recall/precision are bag-of-words measures; the explanation of each residual difference is in the per-document log.
