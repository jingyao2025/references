# Addendum for this job (read after AGENT_BRIEF.md; MATH_ADDENDUM.md applies to any formula)

Job: one combined PDF, `/tmp/claude-0/w11/rc.pdf` (24 pages; repo file `Combined_Residential Constraints and the Political Geography of the Populist Radical Right_Evidence from France.pdf`):
- PDF pp. 1–18: Paulina Patana, "Residential Constraints and the Political Geography of the Populist Radical Right: Evidence from France", *Perspectives on Politics* 20(3), September 2022, printed pp. 842–859 (Cambridge UP, two columns). Endnote markers in the text; the printed **Notes** section (endnotes) and **References** come at the end (around PDF pp. 15–18), after Supplementary Materials and Acknowledgement. Figures 1–2, Tables 1–2.
- PDF pp. 19–24: the "Appendix" (Word-made supplement): A. Descriptive Statistics, B. Robustness of Results to Different Model Specifications (regression Tables B1–B4…, significance stars as superscripts), C. Qualitative Research (interview questions).

Three reviewers (PART): A1 = PDF pp. 1–9; A2 = PDF pp. 10–18; S = PDF pp. 19–24.

Output dir: `/home/claude/output10/patana-2022-residential-constraints/`
- Your Markdown: `_parts/<PART>.md`; your log: `_logs/<PART>.log.md`; scratch only in `/tmp/claude-0/w11/scratch/<PART>/`. render.sh: ALWAYS pass the 4th argument (outdir = your scratch folder).
- Figures: `figures/patana-2022-residential-constraints-fig<N>.png` (article), `…-si-fig<X>.png` (appendix, if any). Crop the graphic only, 200 dpi; view each crop; captions/notes as text; don't retype text inside figures.
- Page markers: `<!-- page N (printed p. X) -->`, N = page of the WHOLE 24-page PDF, X = printed folio (article 842–859; the appendix prints no folios? check each page; if none, `<!-- page N -->`).
- Running heads/feet ("Article | Political Geography and the Radical Right", "Perspectives on Politics", "September 2022 | Vol. 20/No. 3", folios) are removed.
- Endnotes: markers `[^n]` exactly where the superscript stands (printed number). The definitions go where the PDF prints them: in the `## Notes` section (A2 writes them there, one `[^n]: …` per note in printed order; multi-paragraph notes indented 4 spaces). A1 writes only markers.
- Significance stars: superscript stars in tables are written inline after the number, escaped: `0.11\*\*\*`. The star legend line verbatim with `\*`.
- Tables: every cell from 150–200 dpi renders + pagetext.sh; standard errors stay on their own row; caption above as printed (`**Table 1** …` keep the printed punctuation), notes below.
- Block quotations (interview quotes) → `> ` only if printed as indented blocks; inline quotes stay inline. French words/italics as printed.

A1 specifics:
- Write the YAML (facts printed in the PDF only): title, authors, journal "Perspectives on Politics", year 2022, month "September", volume "20", issue "3", pages "842–859", doi (printed on p. 1), copyright line verbatim, data replication line (Harvard Dataverse DOI as printed), source_file "Combined_Residential Constraints and the Political Geography of the Populist Radical Right_Evidence from France.pdf", source_pdf_pages 24, source_note "Combined PDF: article (PDF pp. 1–18), Appendix (pp. 19–24)", converted "2026-10-19".
- `# Title`, author line, the abstract (printed without a heading → add `## Abstract`, log it), then body. The p. 1 foot items ("Data replication sets…", author bio, DOI/©) go right after the abstract as printed paragraphs (bio verbatim). Headings: as printed (unnumbered); main headings `##`, sub-headings `###`.
- Stop exactly at the end of p. 9 (if a paragraph continues on p. 10, end at the page break and say so).

A2 specifics:
- Start exactly at p. 10 (continuation text first; say so). Keep Supplementary Materials, Acknowledgement, `## Notes` (all endnote definitions), `## References` (every entry), exactly as printed and in printed order.

S specifics:
- No YAML. Start with `## Appendix` then `### A. Descriptive Statistics`, `### B. …`, numbered table subheadings like "1. Table B1. Key Indicators Estimated Separately" → `#### 1. Table B1. Key Indicators Estimated Separately` and the table, etc.; `### C. Qualitative Research` with interview questions as a numbered list exactly as printed (nested sub-questions as printed).

Final message: path, verify.py numbers on a page-range PDF (`qpdf --empty --pages /tmp/claude-0/w11/rc.pdf A-B -- /tmp/claude-0/w11/scratch/<PART>/range.pdf`), counts (sections, tables, figures, notes markers/definitions, references), unresolved issues.
