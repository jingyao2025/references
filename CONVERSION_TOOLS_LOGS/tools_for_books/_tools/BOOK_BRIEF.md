# Book-chunk addendum (read AFTER /home/claude/pipeline/AGENT_BRIEF.md)

You convert ONE contiguous page range ("chunk") of a book. The orchestrator will concatenate all
chunks of the book into a single Markdown file, so your output is a **fragment**: NO YAML front
matter, NO `# Book title` heading. Everything in AGENT_BRIEF.md applies (fidelity rules, tables,
figures, verify.py — run verify.py with `--first/--last` set to your page range), with these book rules:

## Heading scheme (uniform across the whole book)
- Part openers: `## Part I: Current nationalisms and the European integration process` (wording as printed).
- Chapters: `## Chapter 1. Against Europe or against Germany? European integration and …` (number and
  full title as printed). Preface / Introduction / Acknowledgements: `## Preface`, `## Introduction`.
- The chapter's author line(s) directly under the chapter heading, as printed, in italics:
  `*Daniele Pasquinucci*` (normal capitalisation if printed in small caps).
- Sections inside a chapter `###`, subsections `####`, deeper `#####`. Keep printed numbering.
- Chapter-end sections (Notes, References/Bibliography, Acknowledgements, appendix) are `###` inside
  that chapter, in their printed order.

## Notes
- Footnote labels must be unique in the whole book: prefix with the chapter: `[^ch3-12]` for note 12 of
  chapter 3 (`[^intro-2]`, `[^pref-1]` for Introduction/Preface). Definitions go where the printed
  notes are (chapter-end `### Notes` section) — or, if the book prints them as page footnotes, at the end
  of that chapter under `### Notes`.

## Page markers
- Keep `<!-- page N (printed p. X) -->` for every page of your range (N = PDF page number of the whole
  PDF; the drafts already use whole-PDF numbering). Roman-numeral printed pages are fine ("printed p. vi").
- Blank pages: keep a marker with `(blank)`; no content.

## Omit
- Cover page, blank pages' content, dedication page, the Index, watermark lines (EBSCO "printed on…",
  "All rights reserved. May not be reproduced…", OUP "Downloaded from academic.oup.com…"), running heads,
  page numbers, web-print interface labels ("Google Scholar", "Google Preview", "WorldCat", "COPAC",
  "Search in this book", "END MATTER", "p. 189" margin page labels of the web print — but keep those
  printed-page labels as page-marker information).

## Figures
Save to `/home/claude/output/references-markdown/books/<book-slug>/figures/<book-slug>-fig<chapter>-<n>.png`
(e.g. `…-fig6-1.png` for Figure 6.1) and link as `figures/<book-slug>-fig6-1.png`.

## Output
- Fragment: `/home/claude/output/references-markdown/books/_parts/<CHUNK-ID>.md`
  (start from the draft at `/tmp/claude-0/w/bookdrafts/chunks/<CHUNK-ID>.md`; layout data next to it).
- Log: `/home/claude/output/references-markdown/_logs/book-<CHUNK-ID>.log.md`
- Scratch: `/tmp/claude-0/w/scratch/book-<CHUNK-ID>/`.
- Render pages at ~80–90 dpi for review; you must look at every page of your range.
