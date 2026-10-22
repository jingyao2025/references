# Conversion log: Patana (2022) + Appendix (combined PDF)

Date: 2026-10-19 · Source: combined PDF in the repository root (commit `cee6ef8`; MD5 fd1fdebdb7d377984c4deff0344666eb)

## 1. Workflow (reused from the earlier combined-PDF batches)
1. **Inventory and structure parsing**:
   - The PDF has 24 pages and was combined in Adobe Acrobat.
   - pp. 1–18 are the *Perspectives on Politics* article (Cambridge UP, two columns, 594×792 pt). It has endnotes, 2 figures and 2 tables.
   - pp. 19–24 are the Appendix, a Word-made document (612×792 pt) with no page numbers.
   - Both have a born-digital text layer, so no OCR was needed.
2. **Draft extraction**: the same layout-aware, opendataloader-pdf-style extractor (`_tools/extract.py`), run on three page ranges.
3. **Page-by-page review**: one reviewer per range (pp. 1–9, 10–18, 19–24), each comparing every page with rendered images. They followed `_tools/AGENT_BRIEF.md` and `_tools/JOB_ADDENDUM.md`.
   - Every table cell was checked against 150–200 dpi renders and the layout text.
   - Each endnote marker was checked against the 7-pt superscripts.
4. **Merge**:
   - The paragraph that runs from p. 9 to p. 10 ("…politicians, and experts, as well ⟨page 10⟩ as participant observation…") was rejoined.
   - The Appendix was appended after the References, behind a separator.
5. **Independent verification by the orchestrator**:
   - **Structure (`qa.py`)**: 24/24 pages marked, 2 figure links, constant table widths, no `(cid:` or U+FFFD.
     - qa.py also reported "definition without marker 26". It is a false alarm: the marker is present ("constrained mobility[^26]:"), but the printed colon right after it misleads the checker. A direct check confirms that all 55 markers 1–55 are present and each has one definition.
   - **Prose, line by line** (`linecheck.py`): the 13 PDF lines not matched automatically are:
     - 8 running heads;
     - 5 lines that differ only by a line-end hyphen or by an endnote number fused into the text layer.
     
     All 5 were confirmed present by hand (e.g. "opportunities", "interregional migration", "la France Insoumise[^52]").
   - **Numbers**: all 408 decimal numbers of the text layer were compared, counting each occurrence. The only ones absent are:
     - endnote numbers fused after sentence periods in the text layer (".10", ".34" …);
     - the three Appendix B1 AIC values that the PDF wraps across two lines. They are joined in the Markdown as 246136.59, 246083.16 and 246121.29.
   - **Visual spot check**: "15 + -year-old" (p. 7) is confirmed to be printed with spaces.

## 2. Troubleshooting
| Issue | Resolution |
|---|---|
| opendataloader-pdf cannot be installed in the sandbox (PyPI/Maven/npm blocked by network policy) | As in earlier batches: its documented approach and verification discipline were followed with the equivalent local pipeline. |
| The "+" in "15+-year-old" is stored as the glyph "þ" | Mapped to "+" from the page image (2 occurrences). |
| Drop cap split ("T" / "he"); ligatures split ("identifi ed", "di fferent") | Rejoined from the page images. |
| The draft ran three subheadings into the text | Restored as `###` headings, as printed. |
| Broken URLs in the notes and references (dropped hyphens, a space inside the INSEE URL) | Rebuilt from the PDF's own link annotations. |
| Table 1: one minus sign is stored as a figure dash (U+2012) in the text layer (Model 2, Public Services/Capita) | It prints identically to the other minus signs, so it was normalised to "−" (U+2212) for consistent machine reading. |
| Tables 1–2 fill p. 11 in the middle of a paragraph that runs from p. 10 to p. 12 | The paragraph is kept whole, with the page markers inline; both tables follow it, with a comment. |
| Appendix Tables B1 and B4 run across page breaks | The page markers sit right after those tables, because a comment cannot go inside a pipe table. |

## 3. Decisions
- **Abstract heading**: `## Abstract` was added (not printed).
- **p. 1 foot items**: the data-replication line, author bio and DOI/© line are kept as printed after the abstract. Their facts are also in the YAML.
- **Author's name**: "Pauliina Patana" as printed.
- **Appendix YAML (supplement file only)**: the Appendix itself prints only the heading "Appendix". The supplement file's YAML therefore takes the title from the article in the same PDF and says so in a `title_note` field.
- **Appendix Table B1**: the PDF prints only four "RN Vote Share" labels over five model columns, so the first model column has an empty header, as printed.
- **Kept as printed**:
  - "(0. 54)" and "(0. 92)", with the space;
  - the inconsistent star legends in B1–B4;
  - "Overtime" (p. 6, printed "Over-/time" with a line-break hyphen, so the typeset word is "Overtime");
  - "under-explored";
  - "one-third";
  - "Biggs & Knauss … 28 (5)", with a space at a printed line break.
